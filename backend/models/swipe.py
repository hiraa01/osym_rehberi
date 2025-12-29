from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class Swipe(Base):
    """Kullanıcının bölümlere yaptığı swipe işlemleri (like/dislike)"""
    __tablename__ = "swipes"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    action = Column(String(20), nullable=False)  # 'like' or 'dislike'
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="swipes")
    department = relationship("Department", back_populates="swipes")
    
    # Unique constraint: Aynı öğrenci aynı bölümü birden fazla kez swipe edemez
    __table_args__ = (UniqueConstraint('student_id', 'department_id', name='uq_student_department_swipe'),)
    
    def __repr__(self):
        return f"<Swipe(id={self.id}, student_id={self.student_id}, department_id={self.department_id}, action='{self.action}')>"

