"""
Agenda Router - Ajanda öğeleri yönetimi
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
from datetime import datetime

from database import get_db
from models import AgendaItem, Student
from schemas.agenda import (
    AgendaItemCreate, AgendaItemUpdate, AgendaItemResponse, AgendaItemListResponse
)
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


@router.get("/", response_model=AgendaItemListResponse)
async def get_agenda_items(
    student_id: int = Query(..., description="Öğrenci ID"),
    page: int = Query(1, ge=1, description="Sayfa numarası"),
    size: int = Query(20, ge=1, le=100, description="Sayfa başına kayıt sayısı"),
    is_completed: Optional[bool] = Query(None, description="Tamamlanma durumu filtresi"),
    category: Optional[str] = Query(None, description="Kategori filtresi"),
    db: Session = Depends(get_db)
):
    """
    Öğrencinin ajanda öğelerini listele (Sayfalama ile)
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")

        # Base query
        query = db.query(AgendaItem).filter(AgendaItem.student_id == student_id)

        # Filtreler
        if is_completed is not None:
            query = query.filter(AgendaItem.is_completed == is_completed)
        if category:
            query = query.filter(AgendaItem.category == category)

        # Toplam sayı
        total = query.count()

        # Sayfalama
        skip = (page - 1) * size
        items = query.order_by(desc(AgendaItem.due_date), desc(AgendaItem.created_at)).offset(skip).limit(size).all()

        return AgendaItemListResponse(
            items=[AgendaItemResponse.from_orm(item) for item in items],
            total=total,
            page=page,
            size=size
        )
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting agenda items: {str(e)}")
        raise HTTPException(status_code=500, detail="Ajanda öğeleri alınırken bir hata oluştu")


@router.post("/", response_model=AgendaItemResponse)
async def create_agenda_item(
    item: AgendaItemCreate,
    db: Session = Depends(get_db)
):
    """
    Yeni ajanda öğesi oluştur
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == item.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {item.student_id}")

        # Yeni öğe oluştur
        new_item = AgendaItem(
            student_id=item.student_id,
            title=item.title,
            description=item.description,
            due_date=item.due_date,
            priority=item.priority,
            category=item.category,
            is_completed=False
        )

        db.add(new_item)
        db.commit()
        db.refresh(new_item)

        api_logger.info(f"Agenda item created: id={new_item.id}, student_id={item.student_id}")
        return AgendaItemResponse.from_orm(new_item)
    except StudentNotFoundError:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error creating agenda item: {str(e)}")
        raise HTTPException(status_code=500, detail="Ajanda öğesi oluşturulurken bir hata oluştu")


@router.put("/{item_id}", response_model=AgendaItemResponse)
async def update_agenda_item(
    item_id: int,
    item_update: AgendaItemUpdate,
    db: Session = Depends(get_db)
):
    """
    Ajanda öğesini güncelle
    """
    try:
        item = db.query(AgendaItem).filter(AgendaItem.id == item_id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Ajanda öğesi bulunamadı")

        # Güncelleme
        update_data = item_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(item, key, value)

        db.commit()
        db.refresh(item)

        api_logger.info(f"Agenda item updated: id={item_id}")
        return AgendaItemResponse.from_orm(item)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error updating agenda item: {str(e)}")
        raise HTTPException(status_code=500, detail="Ajanda öğesi güncellenirken bir hata oluştu")


@router.delete("/{item_id}")
async def delete_agenda_item(
    item_id: int,
    db: Session = Depends(get_db)
):
    """
    Ajanda öğesini sil
    """
    try:
        item = db.query(AgendaItem).filter(AgendaItem.id == item_id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Ajanda öğesi bulunamadı")

        db.delete(item)
        db.commit()

        api_logger.info(f"Agenda item deleted: id={item_id}")
        return {"message": "Ajanda öğesi başarıyla silindi", "id": item_id}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error deleting agenda item: {str(e)}")
        raise HTTPException(status_code=500, detail="Ajanda öğesi silinirken bir hata oluştu")

