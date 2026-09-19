# Build stage: install Python dependencies into a dedicated prefix.
FROM python:3.12.7-slim-bookworm AS builder

WORKDIR /build
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

COPY requirements.txt .
RUN python -m pip install --prefix=/install -r requirements.txt

# Runtime stage: minimal image and non-root execution.
FROM python:3.12.7-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_NAME=demo-service \
    VERSION=0.1.0

COPY --from=builder /install /usr/local
WORKDIR /app
COPY app.py .

RUN useradd --create-home --uid 10001 appuser \
    && chown -R appuser:appuser /app
USER 10001

EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
