# Simple Dockerfile for Django app in this repo
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=backend.settings

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Project
COPY . /app

# Collect static (ignore errors if not configured)
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

# Default command: run Django dev server (for demo/testing)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
