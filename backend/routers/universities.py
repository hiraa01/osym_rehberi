from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from models.university import University, Department
from schemas.university import (
    UniversityCreate, UniversityUpdate, UniversityResponse,
    DepartmentCreate, DepartmentUpdate, DepartmentResponse, DepartmentWithUniversityResponse
)

router = APIRouter()


# University endpoints
@router.post("/", response_model=UniversityResponse)
async def create_university(university: UniversityCreate, db: Session = Depends(get_db)):
    """Yeni üniversite oluştur"""
    db_university = University(**university.dict())
    db.add(db_university)
    db.commit()
    db.refresh(db_university)
    return db_university


@router.get("/", response_model=List[UniversityResponse])
async def get_universities(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    city: Optional[str] = Query(None),
    university_type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Üniversite listesini getir"""
    query = db.query(University)
    
    if city:
        query = query.filter(University.city.ilike(f"%{city}%"))
    if university_type:
        query = query.filter(University.university_type == university_type)
    
    universities = query.offset(skip).limit(limit).all()
    return universities


@router.get("/{university_id}", response_model=UniversityResponse)
async def get_university(university_id: int, db: Session = Depends(get_db)):
    """Belirli bir üniversiteyi getir"""
    university = db.query(University).filter(University.id == university_id).first()
    if not university:
        raise HTTPException(status_code=404, detail="Üniversite bulunamadı")
    return university


@router.put("/{university_id}", response_model=UniversityResponse)
async def update_university(
    university_id: int,
    university_update: UniversityUpdate,
    db: Session = Depends(get_db)
):
    """Üniversite bilgilerini güncelle"""
    university = db.query(University).filter(University.id == university_id).first()
    if not university:
        raise HTTPException(status_code=404, detail="Üniversite bulunamadı")
    
    update_data = university_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(university, field, value)
    
    db.commit()
    db.refresh(university)
    return university


@router.delete("/{university_id}")
async def delete_university(university_id: int, db: Session = Depends(get_db)):
    """Üniversiteyi sil"""
    university = db.query(University).filter(University.id == university_id).first()
    if not university:
        raise HTTPException(status_code=404, detail="Üniversite bulunamadı")
    
    db.delete(university)
    db.commit()
    return {"message": "Üniversite başarıyla silindi"}


# Department endpoints
@router.post("/departments/", response_model=DepartmentResponse)
async def create_department(department: DepartmentCreate, db: Session = Depends(get_db)):
    """Yeni bölüm oluştur"""
    # Üniversite var mı kontrol et
    university = db.query(University).filter(University.id == department.university_id).first()
    if not university:
        raise HTTPException(status_code=404, detail="Üniversite bulunamadı")
    
    db_department = Department(**department.dict())
    db.add(db_department)
    db.commit()
    db.refresh(db_department)
    return db_department


@router.get("/departments/", response_model=List[DepartmentWithUniversityResponse])
async def get_departments(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    field_type: Optional[str] = Query(None),
    university_id: Optional[int] = Query(None),
    city: Optional[str] = Query(None),
    university_type: Optional[str] = Query(None),
    min_score: Optional[float] = Query(None),
    max_score: Optional[float] = Query(None),
    has_scholarship: Optional[bool] = Query(None),
    db: Session = Depends(get_db)
):
    """Bölüm listesini getir"""
    query = db.query(Department).join(University)
    
    if field_type:
        query = query.filter(Department.field_type == field_type)
    if university_id:
        query = query.filter(Department.university_id == university_id)
    if city:
        query = query.filter(University.city.ilike(f"%{city}%"))
    if university_type:
        query = query.filter(University.university_type == university_type)
    if min_score:
        query = query.filter(Department.min_score >= min_score)
    if max_score:
        query = query.filter(Department.min_score <= max_score)
    if has_scholarship is not None:
        query = query.filter(Department.has_scholarship == has_scholarship)
    
    departments = query.offset(skip).limit(limit).all()
    
    # University bilgilerini ekle
    result = []
    for dept in departments:
        university = db.query(University).filter(University.id == dept.university_id).first()
        dept_response = DepartmentWithUniversityResponse(
            **dept.__dict__,
            university=university
        )
        result.append(dept_response)
    
    return result


@router.get("/departments/{department_id}", response_model=DepartmentWithUniversityResponse)
async def get_department(department_id: int, db: Session = Depends(get_db)):
    """Belirli bir bölümü getir"""
    department = db.query(Department).filter(Department.id == department_id).first()
    if not department:
        raise HTTPException(status_code=404, detail="Bölüm bulunamadı")
    
    university = db.query(University).filter(University.id == department.university_id).first()
    
    return DepartmentWithUniversityResponse(
        **department.__dict__,
        university=university
    )


@router.put("/departments/{department_id}", response_model=DepartmentResponse)
async def update_department(
    department_id: int,
    department_update: DepartmentUpdate,
    db: Session = Depends(get_db)
):
    """Bölüm bilgilerini güncelle"""
    department = db.query(Department).filter(Department.id == department_id).first()
    if not department:
        raise HTTPException(status_code=404, detail="Bölüm bulunamadı")
    
    update_data = department_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(department, field, value)
    
    db.commit()
    db.refresh(department)
    return department


@router.delete("/departments/{department_id}")
async def delete_department(department_id: int, db: Session = Depends(get_db)):
    """Bölümü sil"""
    department = db.query(Department).filter(Department.id == department_id).first()
    if not department:
        raise HTTPException(status_code=404, detail="Bölüm bulunamadı")
    
    db.delete(department)
    db.commit()
    return {"message": "Bölüm başarıyla silindi"}


@router.get("/cities/", response_model=List[str])
async def get_cities(db: Session = Depends(get_db)):
    """Tüm şehirleri getir"""
    cities = db.query(University.city).distinct().all()
    return [city[0] for city in cities]


@router.get("/field-types/", response_model=List[str])
async def get_field_types(db: Session = Depends(get_db)):
    """Tüm alan türlerini getir"""
    field_types = db.query(Department.field_type).distinct().all()
    return [field_type[0] for field_type in field_types]
