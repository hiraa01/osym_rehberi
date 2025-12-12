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


# ⚠️ ÖNEMLİ: FastAPI'da spesifik route'lar önce, genel pattern'ler sonda olmalı!
# Yoksa /{university_id} tüm istekleri yakalar

# Spesifik endpoints (önce bunlar)
@router.get("/cities/", response_model=List[str])
async def get_cities(db: Session = Depends(get_db)):
    """81 il + KKTC şehirlerini getir (81 il öncelikli) - OPTIMIZED"""
    # 81 il listesi (seed_yok_data.py'den)
    TURKISH_81_CITIES = [
        "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya",
        "Ardahan", "Artvin", "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik",
        "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı", "Çorum",
        "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir",
        "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır", "Isparta", "İstanbul",
        "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars", "Kastamonu", "Kayseri", "Kırıkkale",
        "Kırklareli", "Kırşehir", "Kilis", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
        "Mardin", "Mersin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Osmaniye",
        "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas", "Şanlıurfa", "Şırnak",
        "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak"
    ]
    
    # ✅ OPTIMIZED: Sadece distinct city değerlerini çek (tüm kayıtları değil)
    from sqlalchemy import distinct
    cities_result = db.query(distinct(University.city)).filter(University.city.isnot(None)).all()
    db_cities = [city[0] for city in cities_result if city[0]]
    
    # KKTC şehirlerini bul
    kktc_cities = [city for city in db_cities if 'kktc' in city.lower()]
    
    # Yabancı ülkeleri filtrele
    foreign_cities = [city for city in db_cities if any(keyword in city.lower() for keyword in [
        'azerbaycan', 'kırgızistan', 'bosna', 'arnavutluk', 
        'makedonya', 'kazakistan', 'moldova', 'bakü', 'bişkek',
        'saraybosna', 'tiran', 'üsküp', 'türkistan', 'komrat'
    ])]
    
    # "Bilinmiyor" şehirleri
    unknown_cities = [city for city in db_cities if 'bilinmiyor' in city.lower()]
    
    # Sıralama: 81 il + KKTC + diğerleri
    result = []
    
    # Türkçe karakterler için özel sıralama
    def turkish_sort_key(text):
        # Türkçe karakterleri İngilizce karşılıklarına çevir
        replacements = {
            'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
            'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U'
        }
        result = text
        for tr, en in replacements.items():
            result = result.replace(tr, en)
        return result.lower()
    
    # 1. 81 il (Türkçe alfabetik sıralı)
    result.extend(sorted(TURKISH_81_CITIES, key=turkish_sort_key))
    
    # 2. KKTC şehirleri (Türkçe alfabetik sıralı)
    result.extend(sorted(kktc_cities, key=turkish_sort_key))
    
    # 3. Diğer şehirler (yabancı ülkeler hariç)
    other_cities = [city for city in db_cities 
                   if city not in TURKISH_81_CITIES 
                   and city not in kktc_cities 
                   and city not in foreign_cities 
                   and city not in unknown_cities]
    result.extend(sorted(other_cities, key=turkish_sort_key))
    
    return result


@router.get("/field-types/", response_model=List[str])
async def get_field_types(db: Session = Depends(get_db)):
    """Tüm alan türlerini getir (cached)"""
    from core.cache import get_cache, set_cache
    from datetime import timedelta
    
    # ✅ Cache'den kontrol et (field types sık değişmez)
    cache_key = "universities:field-types"
    cached = get_cache(cache_key, ttl=timedelta(hours=1))
    if cached is not None:
        return cached
    
    # ✅ OPTIMIZED: Sadece distinct field_type değerlerini çek
    from sqlalchemy import distinct
    field_types_result = db.query(distinct(Department.field_type)).filter(Department.field_type.isnot(None)).all()
    result = [field_type[0] for field_type in field_types_result if field_type[0]]
    
    # Cache'e kaydet
    set_cache(cache_key, result, ttl=timedelta(hours=1))
    return result


# University endpoints
@router.post("/", response_model=UniversityResponse)
async def create_university(university: UniversityCreate, db: Session = Depends(get_db)):
    """Yeni üniversite oluştur"""
    db_university = University(**university.dict())
    db.add(db_university)
    db.commit()
    db.refresh(db_university)
    return db_university


def get_university_logo_url(university: University) -> Optional[str]:
    """Üniversite logosu URL'i oluştur"""
    if university.website:
        # Website varsa, domain'den favicon çek (Google Favicon API)
        domain = university.website.replace('http://', '').replace('https://', '').replace('www.', '').split('/')[0]
        return f"https://www.google.com/s2/favicons?domain={domain}&sz=256"
    return None


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
    
    # ✅ Üniversite adına göre alfabetik sıralama
    query = query.order_by(University.name)
    
    universities = query.offset(skip).limit(limit).all()
    
    # Logo URL'lerini ekle ve response oluştur
    result = []
    for uni in universities:
        # Pydantic response oluştur
        uni_response = UniversityResponse(
            id=uni.id,
            name=uni.name,
            city=uni.city,
            university_type=uni.university_type,
            website=uni.website,
            established_year=uni.established_year,
            latitude=uni.latitude,
            longitude=uni.longitude,
            created_at=uni.created_at,
            updated_at=uni.updated_at,
            logo_url=get_university_logo_url(uni)
        )
        result.append(uni_response)
    
    return result


# Genel pattern'ler (SON SIRA - yoksa her şeyi yakalar!)
@router.get("/{university_id}", response_model=UniversityResponse)
async def get_university(university_id: int, db: Session = Depends(get_db)):
    """Belirli bir üniversiteyi getir"""
    university = db.query(University).filter(University.id == university_id).first()
    if not university:
        raise HTTPException(status_code=404, detail="Üniversite bulunamadı")
    
    # Logo URL'ini ekle
    return UniversityResponse(
        id=university.id,
        name=university.name,
        city=university.city,
        university_type=university.university_type,
        website=university.website,
        established_year=university.established_year,
        latitude=university.latitude,
        longitude=university.longitude,
        created_at=university.created_at,
        updated_at=university.updated_at,
        logo_url=get_university_logo_url(university)
    )


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
    limit: int = Query(500, ge=1, le=5000),  # ✅ Limit azaltıldı - performans için (pagination kullanın)
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
    # Sadece city veya university_type filtresi varsa join yap
    query = db.query(Department)
    
    if city or university_type:
        query = query.join(University, Department.university_id == University.id)
    
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
    
    # ✅ Bölüm adına göre alfabetik sıralama
    query = query.order_by(Department.name)
    
    departments = query.offset(skip).limit(limit).all()
    
    # ✅ N+1 problemini çöz: Tüm üniversiteleri tek seferde çek
    university_ids = {dept.university_id for dept in departments}
    universities_dict = {
        uni.id: uni 
        for uni in db.query(University).filter(University.id.in_(university_ids)).all()
    }
    
    # University bilgilerini ekle
    result = []
    for dept in departments:
        university = universities_dict.get(dept.university_id)
        if not university:
            continue  # Üniversite bulunamazsa skip et
        
        # University response'unu logo URL ile oluştur
        university_response = UniversityResponse(
            id=university.id,
            name=university.name,
            city=university.city,
            university_type=university.university_type,
            website=university.website,
            established_year=university.established_year,
            latitude=university.latitude,
            longitude=university.longitude,
            created_at=university.created_at,
            updated_at=university.updated_at,
            logo_url=get_university_logo_url(university)
        )
        
        dept_response = DepartmentWithUniversityResponse(
            id=dept.id,
            university_id=dept.university_id,
            name=dept.name,
            field_type=dept.field_type,
            language=dept.language,
            faculty=dept.faculty,
            duration=dept.duration,
            degree_type=dept.degree_type,
            min_score=dept.min_score,
            min_rank=dept.min_rank,
            quota=dept.quota,
            scholarship_quota=dept.scholarship_quota,
            tuition_fee=dept.tuition_fee,
            has_scholarship=dept.has_scholarship,
            last_year_min_score=dept.last_year_min_score,
            last_year_min_rank=dept.last_year_min_rank,
            last_year_quota=dept.last_year_quota,
            description=dept.description,
            requirements=dept.requirements,
            created_at=dept.created_at,
            updated_at=dept.updated_at,
            university=university_response
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
    
    # University response'unu logo URL ile oluştur
    university_response = UniversityResponse(
        id=university.id,
        name=university.name,
        city=university.city,
        university_type=university.university_type,
        website=university.website,
        established_year=university.established_year,
        latitude=university.latitude,
        longitude=university.longitude,
        created_at=university.created_at,
        updated_at=university.updated_at,
        logo_url=get_university_logo_url(university)
    )
    
    return DepartmentWithUniversityResponse(
        id=department.id,
        university_id=department.university_id,
        name=department.name,
        field_type=department.field_type,
        language=department.language,
        faculty=department.faculty,
        duration=department.duration,
        degree_type=department.degree_type,
        min_score=department.min_score,
        min_rank=department.min_rank,
        quota=department.quota,
        scholarship_quota=department.scholarship_quota,
        tuition_fee=department.tuition_fee,
        has_scholarship=department.has_scholarship,
        last_year_min_score=department.last_year_min_score,
        last_year_min_rank=department.last_year_min_rank,
        last_year_quota=department.last_year_quota,
        description=department.description,
        requirements=department.requirements,
        created_at=department.created_at,
        updated_at=department.updated_at,
        university=university_response
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


# Cities ve field-types endpoint'leri dosyanın başına taşındı (satır 19-30)
