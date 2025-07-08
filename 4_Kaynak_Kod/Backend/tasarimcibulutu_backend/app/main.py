# app/main.py
from fastapi import FastAPI
from app.routers import user, project, application, auth, message, notification, skill_test, skill, portfolio, work_experience, review
from fastapi.staticfiles import StaticFiles # Yeni import

app = FastAPI(
    title="TasarimciBulutu API",
    description="CAD tasarımcıları ve firmalar için proje eşleştirme platformu.",
    version="1.0.0",
)

app.mount("/static", StaticFiles(directory="static"), name="static")

# API Router'larını uygulamaya dahil etme
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(project.router)
app.include_router(application.router)
app.include_router(message.router)
app.include_router(notification.router)
app.include_router(skill_test.router)
app.include_router(skill.router)
app.include_router(portfolio.router)
app.include_router(work_experience.router)
app.include_router(review.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to TasarimciBulutu API"}