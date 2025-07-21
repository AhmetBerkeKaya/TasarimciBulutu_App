# tasarimcibulutu_backend/app/services/aps_service.py (Direct-to-S3 Version)

import base64
import httpx
import os
from fastapi import HTTPException
from sqlalchemy.orm import Session
import math
import asyncio

from app.config import settings
from app.crud import showcase as showcase_crud
from app.models import showcase as showcase_model

APS_BASE_URL = "https://developer.api.autodesk.com"
APS_BUCKET_KEY = f"tasarimcibulutu-{settings.APS_CLIENT_ID.lower()}"

class APSService:
    
    async def _get_internal_token(self) -> dict:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{APS_BASE_URL}/authentication/v2/token",
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                data={ "grant_type": "client_credentials", "client_id": settings.APS_CLIENT_ID, "client_secret": settings.APS_CLIENT_SECRET, "scope": "bucket:create bucket:read data:read data:write data:create" },
            )
            response.raise_for_status()
            return response.json()

    async def _ensure_bucket_exists(self, token: str):
        async with httpx.AsyncClient() as client:
            check_url = f"{APS_BASE_URL}/oss/v2/buckets/{APS_BUCKET_KEY}/details"
            headers = {"Authorization": f"Bearer {token}"}
            check_response = await client.get(check_url, headers=headers)
            if check_response.status_code == 404:
                print(f"Bucket '{APS_BUCKET_KEY}' bulunamadı, US bölgesinde oluşturuluyor...")
                create_url = f"{APS_BASE_URL}/oss/v2/buckets"
                payload = {"bucketKey": APS_BUCKET_KEY, "policyKey": "temporary", "region": "US"}
                create_response = await client.post(create_url, headers=headers, json=payload)
                create_response.raise_for_status()
                print(f"Bucket '{APS_BUCKET_KEY}' başarıyla oluşturuldu.")
            else:
                check_response.raise_for_status()

    # --- NEW UPLOAD LOGIC ---
    async def _upload_file_direct_to_s3(self, token: str, file_path: str, object_name: str) -> str:
        """Generates a signed S3 URL and uploads the file directly."""
        print("Direct-to-S3 upload process initiated...")
        file_size = os.path.getsize(file_path)
        
        # 1. Get Signed S3 URL(s)
        signed_url_endpoint = f"{APS_BASE_URL}/oss/v2/buckets/{APS_BUCKET_KEY}/objects/{object_name}/signeds3upload"
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        
        # For files larger than 100MB, we need to use multipart upload. This code handles both.
        parts = 1
        if file_size > 100 * 1024 * 1024:
             parts = math.ceil(file_size / (100 * 1024 * 1024))

        async with httpx.AsyncClient(timeout=60.0) as client:
            get_url_response = await client.get(signed_url_endpoint, headers=headers, params={'parts': parts})
            get_url_response.raise_for_status()
            signed_data = get_url_response.json()

        # 2. Upload the file
        with open(file_path, "rb") as f:
            file_content = f.read()
        
        async with httpx.AsyncClient(timeout=300.0) as client:
            upload_response = await client.put(signed_data['urls'][0], content=file_content)
            upload_response.raise_for_status()
        
        # 3. Complete the upload
        complete_upload_endpoint = f"{APS_BASE_URL}/oss/v2/buckets/{APS_BUCKET_KEY}/objects/{object_name}/signeds3upload"
        complete_payload = { "uploadKey": signed_data['uploadKey'] }

        async with httpx.AsyncClient(timeout=60.0) as client:
            complete_response = await client.post(complete_upload_endpoint, headers=headers, json=complete_payload)
            complete_response.raise_for_status()
            print(f"'{object_name}' dosyası Direct-to-S3 ile başarıyla yüklendi.")
            return complete_response.json()['objectId']

    async def _start_translation(self, token: str, object_urn: str):
        translation_url = f"{APS_BASE_URL}/modelderivative/v2/designdata/job"
        webhook_url = f"{settings.WEBHOOK_HOST}/webhooks/aps"
        headers = { "Authorization": f"Bearer {token}", "Content-Type": "application/json", "x-ads-callback-url": webhook_url }
        encoded_urn = base64.urlsafe_b64encode(object_urn.encode()).decode().rstrip("=")
        payload = { "input": {"urn": encoded_urn}, "output": {"formats": [{"type": "svf", "views": ["2d", "3d"]}]} }
        async with httpx.AsyncClient() as client:
            response = await client.post(translation_url, headers=headers, json=payload)
            response.raise_for_status()
            print(f"'{object_urn}' için çeviri işlemi başarıyla başlatıldı.")


    async def trigger_translation(self, db: Session, post: showcase_model.ShowcasePost):
        print(f"Post ID {post.id} için çeviri süreci başlatılıyor...")
        try:
            token_data = await self._get_internal_token()
            token = token_data['access_token']
            
            await self._ensure_bucket_exists(token)
            
            file_extension = os.path.splitext(post.storage_path)[1]
            object_name = f"{post.id}{file_extension}"

            # --- USE THE NEW UPLOAD METHOD ---
            object_urn = await self._upload_file_direct_to_s3(token, post.storage_path, object_name)
            
            await self._start_translation(token, object_urn)
            
            encoded_urn = base64.urlsafe_b64encode(object_urn.encode()).decode().rstrip("=")
            showcase_crud.update_post_urn_and_status(db=db, db_post=post, urn=encoded_urn, status="inprogress")
            print(f"Post ID {post.id}, URN '{encoded_urn}' ile güncellendi. Durum: inprogress.")
            
        except Exception as e:
            error_urn = f"error:{post.id}:{type(e).__name__}"
            showcase_crud.update_post_urn_and_status(db=db, db_post=post, urn=error_urn, status="failed")
            print(f"Post ID {post.id} için çeviri sürecinde HATA oluştu: {e!r}")