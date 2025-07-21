#!/usr/bin/env bash
# exit on error
set -o errexit

pip install --upgrade pip
pip install -r requirements.txt

# Alembic ile veritabanı tablolarını oluştur/güncelle
alembic upgrade head