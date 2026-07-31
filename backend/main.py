from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import time

from app.core.config import settings
from app.core.logging import logger
from app.api.v1.router import api_router as v1_router
from app.api.v2.router import api_v2_router
from app.schemas.response_wrapper import APIResponse

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V2_STR}/openapi.json",
    description="Enterprise AI-powered GeoProperty Intelligence Platform API.",
)

# Configure CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Structured Logging & Performance Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    logger.info(f"Incoming Request: {request.method} {request.url.path}")

    try:
        response = await call_next(request)
        process_time_ms = (time.time() - start_time) * 1000
        logger.info(
            f"Request Handled: {request.method} {request.url.path} "
            f"-> Status {response.status_code} ({process_time_ms:.2f}ms)"
        )
        return response
    except Exception as exc:
        process_time_ms = (time.time() - start_time) * 1000
        logger.error(
            f"Unhandled Error: {request.method} {request.url.path} "
            f"({process_time_ms:.2f}ms) - {str(exc)}",
            exc_info=True,
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=APIResponse.fail(
                message="An internal server error occurred.", errors=str(exc)
            ).model_dump(),
        )


# Global Exception Handler for Clean API Envelopes
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception caught: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=APIResponse.fail(
            message="Internal server error", errors=str(exc)
        ).model_dump(),
    )


# Include API Routers
app.include_router(api_v2_router, prefix=settings.API_V2_STR)
app.include_router(v1_router, prefix=settings.API_V1_STR)


@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return APIResponse.ok(
        data={
            "title": settings.PROJECT_NAME,
            "version": settings.VERSION,
            "status": "online",
            "docs": "/docs",
            "provider": settings.DEFAULT_STATE_PROVIDER,
        },
        message="GeoProperty Intelligence Platform backend API is running.",
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
