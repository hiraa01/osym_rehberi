"""
Agenda Item Schemas
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class AgendaItemBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200, description="Görev başlığı")
    description: Optional[str] = Field(None, max_length=1000, description="Görev açıklaması")
    due_date: Optional[datetime] = Field(None, description="Bitiş tarihi")
    priority: str = Field("medium", description="Öncelik: low, medium, high")
    category: Optional[str] = Field(None, max_length=50, description="Kategori: Ders, Sınav, Ödev, vb.")


class AgendaItemCreate(AgendaItemBase):
    student_id: int = Field(..., description="Öğrenci ID")


class AgendaItemUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    due_date: Optional[datetime] = None
    is_completed: Optional[bool] = None
    priority: Optional[str] = Field(None, description="Öncelik: low, medium, high")
    category: Optional[str] = Field(None, max_length=50)


class AgendaItemResponse(AgendaItemBase):
    id: int
    student_id: int
    is_completed: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AgendaItemListResponse(BaseModel):
    items: list[AgendaItemResponse]
    total: int
    page: int
    size: int

