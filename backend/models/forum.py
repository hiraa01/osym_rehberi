from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class ForumPost(Base):
    """Forum gönderileri (sorular)"""
    __tablename__ = "forum_posts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    category = Column(String(50), nullable=False, index=True)  # TYT, AYT, Rehberlik
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="forum_posts")
    comments = relationship("ForumComment", back_populates="post", cascade="all, delete-orphan")
    
    # Indexes
    __table_args__ = (
        Index('ix_forum_posts_category_created', 'category', 'created_at'),
    )
    
    def __repr__(self):
        return f"<ForumPost(id={self.id}, title='{self.title[:30]}...', category='{self.category}')>"


class ForumComment(Base):
    """Forum gönderilerine yapılan yorumlar"""
    __tablename__ = "forum_comments"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("forum_posts.id"), nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    content = Column(Text, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    post = relationship("ForumPost", back_populates="comments")
    student = relationship("Student", back_populates="forum_comments")
    
    def __repr__(self):
        return f"<ForumComment(id={self.id}, post_id={self.post_id}, student_id={self.student_id})>"

