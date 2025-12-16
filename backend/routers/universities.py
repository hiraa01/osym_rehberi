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
    """81 il + KKTC şehirlerini getir (81 il öncelikli) - OPTIMIZED with CACHE"""
    # ✅ Cache'den kontrol et (ama her zaman 81 il + KKTC döndürmeli)
    from core.cache import get_cache, set_cache
    from datetime import timedelta
    # ✅ Cache'i kullan ama her zaman 81 il listesini ekle
    # cached_cities = get_cache("cities", ttl=timedelta(hours=24))
    # if cached_cities is not None:
    #     return cached_cities
    
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
    
    # Türkçe karakterler için özel sıralama ve normalize fonksiyonu
    def normalize_city_name(text):
        """Şehir adını normalize et (Türkçe karakterleri İngilizce karşılıklarına çevir)"""
        replacements = {
            'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
            'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u'
        }
        result = text.lower().strip()
        for tr, en in replacements.items():
            result = result.replace(tr, en)
        return result
    
    def turkish_sort_key(text):
        """Sıralama için normalize edilmiş key"""
        return normalize_city_name(text)
    
    # ✅ 81 il listesini normalize et (karşılaştırma için)
    normalized_81_cities = {normalize_city_name(city): city for city in TURKISH_81_CITIES}
    normalized_kktc_cities = {normalize_city_name(city): city for city in kktc_cities}
    
    # ✅ Sadece 81 il + KKTC şehirlerini döndür (DB'deki yanlış yazılmış şehirleri ekleme)
    # 1. 81 il (Türkçe alfabetik sıralı)
    result.extend(sorted(TURKISH_81_CITIES, key=turkish_sort_key))
    
    # 2. KKTC şehirleri (Türkçe alfabetik sıralı)
    result.extend(sorted(kktc_cities, key=turkish_sort_key))
    
    # ✅ DB'deki diğer şehirleri EKLEME (yanlış yazılmış versiyonlar olabilir)
    # Sadece 81 il + KKTC = 86 şehir döndür
    
    # ✅ Duplicate temizleme - normalize edilmiş karşılaştırma ile
    seen = set()
    unique_result = []
    for city in result:
        city_normalized = normalize_city_name(city)
        
        # Eğer normalize edilmiş versiyonu daha önce görülmüşse, ekleme
        if city_normalized not in seen:
            seen.add(city_normalized)
            unique_result.append(city)
    
    # ✅ Cache'e kaydet
    set_cache("cities", unique_result, ttl=timedelta(hours=24))
    
    # ✅ Debug: Kaç şehir döndürüldü?
    from core.logging_config import api_logger
    api_logger.info(f"Cities endpoint: {len(unique_result)} unique cities returned (81 il + KKTC + others)")
    
    return unique_result


@router.get("/field-types/", response_model=List[str])
async def get_field_types(db: Session = Depends(get_db)):
    """Tüm alan türlerini getir (cached) - OPTIMIZED with CACHE"""
    from core.cache import get_cache, set_cache
    from datetime import timedelta
    
    # ✅ Cache'den kontrol et (startup'ta yüklenen cache)
    cached = get_cache("field_types", ttl=timedelta(hours=24))
    if cached is not None:
        return cached
    
    # ✅ OPTIMIZED: Sadece distinct field_type değerlerini çek
    from sqlalchemy import distinct
    field_types_result = db.query(distinct(Department.field_type)).filter(Department.field_type.isnot(None)).all()
    result = [field_type[0] for field_type in field_types_result if field_type[0]]
    
    # ✅ Cache'e kaydet (startup cache key ile uyumlu)
    set_cache("field_types", result, ttl=timedelta(hours=24))
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


@router.get("/departments/unique/", response_model=List[dict])
async def get_unique_departments(
    university_type: Optional[str] = Query(None, description="Üniversite türü: devlet, vakif"),
    field_type: Optional[str] = Query(None, description="Alan türü: SAY, EA, SÖZ, DİL"),
    db: Session = Depends(get_db)
):
    """
    ✅ Normalize edilmiş bölüm isimlerini TEKİL olarak listele
    
    Kullanım Senaryosu:
    1. Üniversite türü seçilir (devlet/vakif)
    2. Bu endpoint çağrılır -> unique bölüm isimleri döner
    3. Kullanıcı bir bölüm seçer (örn: "Psikoloji")
    4. /departments/ endpoint'i normalized_name filtresi ile çağrılır -> tüm varyasyonları döner
    """
    from sqlalchemy import distinct, func
    from sqlalchemy.orm import selectinload
    
    # ✅ Normalize edilmiş isimlere göre unique bölümleri getir
    query = db.query(
        Department.normalized_name,
        func.count(Department.id).label('variation_count'),
        func.min(Department.id).label('representative_id')
    ).filter(
        Department.normalized_name.isnot(None)
    )
    
    # Üniversite türü filtresi için join
    if university_type:
        query = query.join(University, Department.university_id == University.id)
        query = query.filter(University.university_type == university_type)
    
    # Alan türü filtresi
    if field_type:
        query = query.filter(Department.field_type == field_type)
    
    # Grupla ve sırala
    query = query.group_by(Department.normalized_name)
    query = query.order_by(Department.normalized_name)
    
    results = query.all()
    
    # Response formatı
    unique_departments = []
    for result in results:
        normalized_name = result.normalized_name
        variation_count = result.variation_count
        representative_id = result.representative_id
        
        # Representative department'ı al (attributes için)
        rep_dept = db.query(Department).filter(Department.id == representative_id).first()
        attributes = []
        if rep_dept and rep_dept.attributes:
            import json
            try:
                attributes = json.loads(rep_dept.attributes)
            except:
                attributes = []
        
        unique_departments.append({
            'normalized_name': normalized_name,
            'variation_count': variation_count,
            'attributes_examples': attributes[:3] if attributes else [],  # İlk 3 attribute örneği
        })
    
    return unique_departments


@router.get("/departments/", response_model=List[DepartmentWithUniversityResponse])
async def get_departments(
    skip: int = Query(0, ge=0),
    limit: int = Query(2000, ge=1, le=5000),  # ✅ Default 2000, max 5000 - tüm veriler gelsin
    field_type: Optional[str] = Query(None),
    university_id: Optional[int] = Query(None),
    city: Optional[str] = Query(None),
    university_type: Optional[str] = Query(None),
    normalized_name: Optional[str] = Query(None, description="✅ Normalize edilmiş bölüm ismi (unique endpoint'ten alınır)"),
    min_score: Optional[float] = Query(None),
    max_score: Optional[float] = Query(None),
    has_scholarship: Optional[bool] = Query(None),
    db: Session = Depends(get_db)
):
    """Bölüm listesini getir - OPTIMIZED with eager loading and selectinload"""
    # ✅ OPTIMIZED: selectinload ile N+1 problemini tamamen önle
    from sqlalchemy.orm import selectinload
    
    # ✅ OPTIMIZED: Sadece city veya university_type filtresi varsa join yap
    query = db.query(Department)
    
    # ✅ OPTIMIZED: selectinload ile University bilgilerini tek sorguda çek (N+1 problemini önler)
    query = query.options(selectinload(Department.university))
    
    # Filtreleme - city veya university_type için join gerekli
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
    if normalized_name:  # ✅ Normalize edilmiş isme göre filtrele (tüm varyasyonları getir)
        query = query.filter(Department.normalized_name == normalized_name)
    if min_score:
        query = query.filter(Department.min_score >= min_score)
    if max_score:
        query = query.filter(Department.min_score <= max_score)
    if has_scholarship is not None:
        query = query.filter(Department.has_scholarship == has_scholarship)
    
    # ✅ Bölüm adına göre alfabetik sıralama
    query = query.order_by(Department.name)
    
    # ✅ OPTIMIZED: Tek sorguda tüm verileri çek (selectinload ile University bilgileri de dahil)
    departments = query.offset(skip).limit(limit).all()
    
    # ✅ N+1 problemi çözüldü: selectinload sayesinde University bilgileri zaten yüklendi
    result = []
    for dept in departments:
        university = dept.university  # ✅ Artık ek sorgu yok, zaten yüklü
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
        
        # ✅ Attributes'ı parse et
        import json
        attributes = []
        if dept.attributes:
            try:
                attributes = json.loads(dept.attributes)
            except:
                attributes = []
        
        dept_response = DepartmentWithUniversityResponse(
            id=dept.id,
            university_id=dept.university_id,
            name=dept.name,  # Orijinal isim
            normalized_name=dept.normalized_name,  # ✅ Normalize edilmiş isim
            attributes=attributes,  # ✅ Attributes listesi
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
