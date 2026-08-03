from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings

from routers import auth, admin, mentor, shared, skill_surveys
from routers._photos import COMPRESSED_PHOTO_DIR

app = FastAPI(title="Progress Tracking API")

if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(mentor.router, prefix="/api/mentor", tags=["mentor"])
app.include_router(shared.router, prefix="/api/shared", tags=["shared"])
app.include_router(skill_surveys.router, prefix="/api/shared", tags=["skill surveys"])

@app.get("/api/health")
def health_check():
    return {"status": "ok"}

app.mount(
    "/compressed_photos",
    StaticFiles(
        directory=COMPRESSED_PHOTO_DIR,
    ),
    name="compressed_photos",
)

app.mount(
    "/compressed_story_photos",
    StaticFiles(
        directory="compressed_story_photos",
    ),
    name="compressed_story_photos",
)
