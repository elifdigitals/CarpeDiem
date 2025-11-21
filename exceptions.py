from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from datetime import datetime


def _build_error_response(error_type: str, message: str, details=None):
    return {
        "success": False,
        "error": {
            "type": error_type,
            "message": message,
            "details": details,
            "timestamp": datetime.utcnow().isoformat()
        }
    }


async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content=_build_error_response(
            error_type="HTTPException",
            message=exc.detail,
            details={"path": request.url.path}
        )
    )


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content=_build_error_response(
            error_type="ValidationError",
            message="Invalid request data",
            details=exc.errors()
        )
    )


async def generic_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content=_build_error_response(
            error_type="ServerError",
            message=str(exc),
            details={"path": request.url.path}
        )
    )
