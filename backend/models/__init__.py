# Models package
# ✅ Tüm modeller artık tek dosyada (backend/models.py)
# Backward compatibility için buradan import ediyoruz
import sys
import os

# backend/models.py dosyasını import et
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from models import (
    User, Student, ExamAttempt,
    University, Department, DepartmentYearlyStats, Recommendation,
    Preference, Swipe,
    ForumPost, ForumComment,
    AgendaItem, StudySession, ChatMessage,
    YokUniversity, YokProgram, YokCity, ScoreCalculation
)

__all__ = [
    "User",
    "Student",
    "University",
    "Department",
    "DepartmentYearlyStats",
    "Recommendation",
    "YokUniversity",
    "YokProgram",
    "YokCity",
    "ScoreCalculation",
    "ExamAttempt",
    "Preference",
    "ForumPost",
    "ForumComment",
    "Swipe",
    "AgendaItem",
    "StudySession",
    "ChatMessage",
]
