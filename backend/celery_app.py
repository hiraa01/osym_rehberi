"""
Celery configuration for async task processing
Özellikle recommendation generation gibi uzun süren işlemler için kullanılır
"""
from celery import Celery
import os

# Redis connection URL (Celery broker ve result backend için)
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")

# Celery app oluştur
celery_app = Celery(
    "osym_rehberi",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["tasks.recommendation_tasks"]  # Task modüllerini dahil et
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=600,  # 10 dakika maksimum task süresi
    task_soft_time_limit=540,  # 9 dakika soft limit
    worker_prefetch_multiplier=1,  # Worker başına 1 task
    worker_max_tasks_per_child=50,  # Her worker 50 task sonrası restart
)

