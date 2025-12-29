from sqlalchemy import Column, Integer, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class Preference(Base):
    """Öğrencinin beğendiği bölümleri kaydeden tablo"""
    __tablename__ = "preferences"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    order = Column(Integer, nullable=True)  # Tercih sırası (opsiyonel)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="preferences")
    department = relationship("Department", back_populates="preferences")
    
    # Unique constraint: Aynı öğrenci aynı bölümü birden fazla kez ekleyemez
    __table_args__ = (UniqueConstraint('student_id', 'department_id', name='uq_student_department'),)
    
    def __repr__(self):
        return f"<Preference(id={self.id}, student_id={self.student_id}, department_id={self.department_id}, order={self.order})>"

