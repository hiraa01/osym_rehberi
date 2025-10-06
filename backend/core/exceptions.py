"""Custom exceptions for ÖSYM Rehberi domain"""


class OsymRehberiException(Exception):
    """Base exception for ÖSYM Rehberi"""
    pass


class StudentNotFoundError(OsymRehberiException):
    """Raised when student is not found"""
    pass


class UniversityNotFoundError(OsymRehberiException):
    """Raised when university is not found"""
    pass


class DepartmentNotFoundError(OsymRehberiException):
    """Raised when department is not found"""
    pass


class InvalidScoreError(OsymRehberiException):
    """Raised when score calculation fails"""
    pass


class RecommendationError(OsymRehberiException):
    """Raised when recommendation generation fails"""
    pass


class DatabaseError(OsymRehberiException):
    """Raised when database operation fails"""
    pass
