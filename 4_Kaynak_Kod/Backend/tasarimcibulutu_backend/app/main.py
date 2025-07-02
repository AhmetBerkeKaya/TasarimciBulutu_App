# app/main.py
from fastapi import FastAPI
from app.routers import user, project, application, auth, message, notification, skill_test, test_result, skill

app = FastAPI(
    title="TasarimciBulutu API",
    description="CAD tasarımcıları ve firmalar için proje eşleştirme platformu.",
    version="1.0.0",
)

# API Router'larını uygulamaya dahil etme
app.include_router(auth.router) # BU SATIRIN EKLENDİĞİNDEN EMİN OL
app.include_router(user.router)
app.include_router(project.router)
app.include_router(application.router)
app.include_router(message.router)
app.include_router(notification.router)
app.include_router(skill_test.router)
app.include_router(test_result.router)
app.include_router(skill.router)


@app.get("/")
def read_root():
    return {"message": "Welcome to TasarimciBulutu API"}