# Models package
from .user import User
from .student import Student
from .university import University, Department, Recommendation
from .yok_data import YokUniversity, YokProgram, YokCity, ScoreCalculation
from .exam_attempt import ExamAttempt

__all__ = [
    "User",
    "Student",
    "University",
    "Department",
    "Recommendation",
    "YokUniversity",
    "YokProgram",
    "YokCity",
    "ScoreCalculation",
    "ExamAttempt",
]
