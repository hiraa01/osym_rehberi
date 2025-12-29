# ✅ Models package - Relative import kullanarak circular import'u önle
# ✅ CRITICAL: Absolute import (from models import ...) kullanma, relative import kullan (.user, .student)

from .user import User
from .student import Student
from .exam_attempt import ExamAttempt
from .university import University, Department, DepartmentYearlyStats, Recommendation
from .preference import Preference
from .swipe import Swipe
from .forum import ForumPost, ForumComment
from .yok_data import YokUniversity, YokProgram, YokCity, ScoreCalculation

# ✅ AgendaItem, StudySession, ChatMessage modelleri models.py'de olabilir
# Eğer ayrı dosyalarda değillerse, models.py'den import et
try:
    from .agenda import AgendaItem
except ImportError:
    try:
        # models.py'den import et (eğer orada tanımlıysa)
        import sys
        import os
        parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        if parent_dir not in sys.path:
            sys.path.insert(0, parent_dir)
        from models import AgendaItem  # noqa: F401
    except ImportError:
        AgendaItem = None

try:
    from .study import StudySession
except ImportError:
    try:
        from models import StudySession  # noqa: F401
    except ImportError:
        StudySession = None

try:
    from .chat import ChatMessage
except ImportError:
    try:
        from models import ChatMessage  # noqa: F401
    except ImportError:
        ChatMessage = None

__all__ = [
    "User",
    "Student",
    "ExamAttempt",
    "University",
    "Department",
    "DepartmentYearlyStats",
    "Recommendation",
    "Preference",
    "Swipe",
    "ForumPost",
    "ForumComment",
    "YokUniversity",
    "YokProgram",
    "YokCity",
    "ScoreCalculation",
    "AgendaItem",
    "StudySession",
    "ChatMessage",
]
