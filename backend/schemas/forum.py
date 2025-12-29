from pydantic import BaseModel, validator
from typing import Optional, List
from datetime import datetime


class ForumPostBase(BaseModel):
    student_id: int
    title: str
    content: str
    category: str
    
    @validator('category')
    def validate_category(cls, v):
        allowed_categories = ['TYT', 'AYT', 'Rehberlik']
        if v not in allowed_categories:
            raise ValueError(f'category must be one of {allowed_categories}')
        return v


class ForumPostCreate(ForumPostBase):
    pass


class ForumPostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    category: Optional[str] = None


class ForumCommentBase(BaseModel):
    post_id: int
    student_id: int
    content: str


class ForumCommentCreate(ForumCommentBase):
    pass


class ForumCommentResponse(ForumCommentBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class ForumPostResponse(ForumPostBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    comment_count: int = 0  # Yorum sayısı
    
    class Config:
        from_attributes = True


class ForumPostDetailResponse(ForumPostResponse):
    """Gönderi detayı + yorumlar"""
    comments: List[ForumCommentResponse] = []


class ForumPostListResponse(BaseModel):
    """Sayfalama ile gönderi listesi"""
    posts: List[ForumPostResponse]
    total: int
    page: int
    size: int

