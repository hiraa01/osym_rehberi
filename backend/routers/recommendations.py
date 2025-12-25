# -*- coding: utf-8 -*-
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from models.student import Student
from models.university import Recommendation
from schemas.university import RecommendationResponse, RecommendationListResponse
from services.recommendation_engine import RecommendationEngine
from services.score_calculator import ScoreCalculator
from core.logging_config import api_logger

router = APIRouter()


@router.post("/generate/{student_id}", response_model=List[RecommendationResponse])
async def generate_recommendations(
    student_id: int,
    limit: int = Query(50, ge=1, le=200),
    w_c: float = Query(0.4, ge=0.0, le=1.0, description="Weight for compatibility"),
    w_s: float = Query(0.4, ge=0.0, le=1.0, description="Weight for success probability"),
    w_p: float = Query(0.2, ge=0.0, le=1.0, description="Weight for preference"),
    force_regenerate: bool = Query(False, description="Force regeneration even if recommendations exist"),
    db: Session = Depends(get_db)
):
    """Öğrenci için tercih önerileri oluştur"""
    try:
        api_logger.info("Starting recommendation generation", user_id=student_id, limit=limit)
        
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
        
        # ✅ Cache kontrolü: Eğer öneriler varsa ve force_regenerate=False ise, mevcut önerileri döndür
        if not force_regenerate:
            existing_recs = db.query(Recommendation).filter(
                Recommendation.student_id == student_id
            ).order_by(Recommendation.final_score.desc()).limit(limit).all()
            
            if existing_recs and len(existing_recs) > 0:
                api_logger.info("Returning cached recommendations", user_id=student_id, count=len(existing_recs))
                # Mevcut önerileri formatla ve döndür
                from models.university import Department, University
                from schemas.university import DepartmentWithUniversityResponse
                
                department_ids = {rec.department_id for rec in existing_recs}
                departments_dict = {
                    dept.id: dept
                    for dept in db.query(Department).filter(Department.id.in_(department_ids)).all()
                }
                university_ids = {dept.university_id for dept in departments_dict.values()}
                universities_dict = {
                    uni.id: uni
                    for uni in db.query(University).filter(University.id.in_(university_ids)).all()
                }
                
                result = []
                for rec in existing_recs:
                    department = departments_dict.get(rec.department_id)
                    if not department:
                        continue
                    
                    # ✅ NULL PUAN KORUMASI: Cache'den gelen önerilerde de kontrol et
                    if department.min_score is None or department.min_score <= 0:
                        api_logger.debug(
                            f"Skipping cached recommendation {rec.id} - department {department.id} has null min_score",
                            recommendation_id=rec.id,
                            department_id=department.id
                        )
                        continue
                    
                    university = universities_dict.get(department.university_id)
                    if not university:
                        continue
                    department_response = DepartmentWithUniversityResponse(
                        **department.__dict__,
                        university=university
                    )
                    result.append(RecommendationResponse(
                        **rec.__dict__,
                        department=department_response
                    ))
                
                # ✅ Eğer cache'den gelen sonuç varsa döndür
                if result:
                    return result
        
        # ✅ Önce eski önerileri temizle (yeniden hesaplama için)
        db.query(Recommendation).filter(Recommendation.student_id == student_id).delete()
        db.commit()
        
        # Öneri motorunu çalıştır (try-except ile güvenli hale getir)
        try:
            recommendation_engine = RecommendationEngine(db)
            # normalize weights (total>0 ise)
            total_w = max(1e-9, (w_c + w_s + w_p))
            weights = (w_c / total_w, w_s / total_w, w_p / total_w)
            recommendations = recommendation_engine.generate_recommendations(student_id, limit, weights)
            
            # ✅ NULL PUAN KORUMASI: min_score None olan bölümleri filtrele
            filtered_recommendations = []
            for rec in recommendations:
                if hasattr(rec, 'department') and rec.department:
                    dept = rec.department
                    if hasattr(dept, 'min_score') and dept.min_score is not None and dept.min_score > 0:
                        filtered_recommendations.append(rec)
                    else:
                        api_logger.debug(
                            f"Skipping recommendation - department has null/zero min_score",
                            recommendation_id=getattr(rec, 'id', None),
                            department_id=getattr(dept, 'id', None) if hasattr(dept, 'id') else None
                        )
                else:
                    # Department bilgisi yoksa da ekle (fallback için)
                    filtered_recommendations.append(rec)
            
            recommendations = filtered_recommendations
            
        except Exception as engine_error:
            # ✅ Öneri motoru hatası durumunda logla ve fallback'e geç
            api_logger.error(
                f"Recommendation engine error: {str(engine_error)}",
                user_id=student_id,
                error=str(engine_error)
            )
            recommendations = []  # Boş liste - fallback'e geç
        
        # ✅ Eğer öneri bulunduysa döndür
        if recommendations and len(recommendations) > 0:
            api_logger.info("Recommendations generated successfully", user_id=student_id, count=len(recommendations))
            return recommendations
        
        # ✅ FALLBACK: Eğer öneri bulunamazsa, en yüksek puanlı 10 bölümü "Popüler Bölümler" olarak döndür
        api_logger.info("No recommendations found, returning popular departments", user_id=student_id)
        from models.university import Department, University
        from schemas.university import DepartmentWithUniversityResponse
        
        # ✅ min_score None olan bölümleri filtreleme dışında bırak
        popular_query = db.query(Department).filter(
            Department.min_score.isnot(None),
            Department.min_score > 0
        )
        
        # Öğrencinin alan türüne uygun popüler bölümleri getir
        if student.field_type:
            popular_query = popular_query.filter(Department.field_type == student.field_type)
        
        popular_departments = popular_query.order_by(
            Department.min_score.desc()
        ).limit(10).all()  # En yüksek puanlı 10 bölüm
        
        # Eğer alan türüne uygun yoksa, tüm popüler bölümleri getir
        if not popular_departments:
            popular_departments = db.query(Department).filter(
                Department.min_score.isnot(None),
                Department.min_score > 0
            ).order_by(
                Department.min_score.desc()
            ).limit(10).all()
        
        # University'leri çek
        university_ids = {dept.university_id for dept in popular_departments}
        universities_dict = {
            uni.id: uni
            for uni in db.query(University).filter(University.id.in_(university_ids)).all()
        }
        
        # Response formatına çevir (Popüler Bölümler olarak)
        fallback_result = []
        for dept in popular_departments:
            university = universities_dict.get(dept.university_id)
            if not university:
                continue
            
            department_response = DepartmentWithUniversityResponse(
                **dept.__dict__,
                university=university
            )
            
            # Dummy recommendation oluştur (Popüler Bölüm olarak işaretle)
            fallback_result.append(RecommendationResponse(
                student_id=student_id,
                department_id=dept.id,
                department=department_response,
                compatibility_score=50.0,
                success_probability=50.0,
                preference_score=50.0,
                final_score=50.0,
                recommendation_reason="Popüler Bölüm",
                is_safe_choice=False,
                is_dream_choice=False,
                is_realistic_choice=True
            ))
        
        api_logger.info("Returning popular departments as fallback", user_id=student_id, count=len(fallback_result))
        return fallback_result
        
    except HTTPException:
        # HTTPException'ları tekrar fırlat (404 gibi)
        raise
    except Exception as e:
        # ✅ FALLBACK: Herhangi bir hata durumunda popüler bölümleri döndür (500 hatası verme)
        api_logger.error(f"Error generating recommendations: {str(e)}", user_id=student_id, error=str(e))
        
        try:
            student = db.query(Student).filter(Student.id == student_id).first()
            if not student:
                # Öğrenci yoksa bile popüler bölümleri döndür
                student = None
            
            from models.university import Department, University
            from schemas.university import DepartmentWithUniversityResponse
            
            # ✅ min_score None olan bölümleri filtreleme dışında bırak
            popular_query = db.query(Department).filter(
                Department.min_score.isnot(None),
                Department.min_score > 0
            )
            
            if student and student.field_type:
                popular_query = popular_query.filter(Department.field_type == student.field_type)
            
            popular_departments = popular_query.order_by(
                Department.min_score.desc()
            ).limit(10).all()
            
            if not popular_departments:
                popular_departments = db.query(Department).filter(
                    Department.min_score.isnot(None),
                    Department.min_score > 0
                ).order_by(
                    Department.min_score.desc()
                ).limit(10).all()
            
            university_ids = {dept.university_id for dept in popular_departments}
            universities_dict = {
                uni.id: uni
                for uni in db.query(University).filter(University.id.in_(university_ids)).all()
            }
            
            fallback_result = []
            for dept in popular_departments:
                university = universities_dict.get(dept.university_id)
                if not university:
                    continue
                
                department_response = DepartmentWithUniversityResponse(
                    **dept.__dict__,
                    university=university
                )
                
                fallback_result.append(RecommendationResponse(
                    student_id=student_id if student else 0,
                    department_id=dept.id,
                    department=department_response,
                    compatibility_score=50.0,
                    success_probability=50.0,
                    preference_score=50.0,
                    final_score=50.0,
                    recommendation_reason="Popüler Bölüm",
                    is_safe_choice=False,
                    is_dream_choice=False,
                    is_realistic_choice=True
                ))
            
            api_logger.info("Returning popular departments after error", user_id=student_id, count=len(fallback_result))
            return fallback_result
        except Exception as fallback_error:
            # Son çare: Boş liste döndür (ama 500 hatası verme)
            api_logger.error(f"Fallback also failed: {str(fallback_error)}", user_id=student_id, error=str(fallback_error))
            return []


@router.get("/student/{student_id}", response_model=RecommendationListResponse)
async def get_student_recommendations(
    student_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    recommendation_type: Optional[str] = Query(None, description="safe, dream, realistic"),
    db: Session = Depends(get_db)
):
    """Öğrencinin mevcut önerilerini getir"""
    # Öğrenci var mı kontrol et
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    query = db.query(Recommendation).filter(Recommendation.student_id == student_id)
    
    # Öneri türüne göre filtrele
    if recommendation_type == "safe":
        query = query.filter(Recommendation.is_safe_choice == True)
    elif recommendation_type == "dream":
        query = query.filter(Recommendation.is_dream_choice == True)
    elif recommendation_type == "realistic":
        query = query.filter(Recommendation.is_realistic_choice == True)
    
    # Final skora göre sırala
    query = query.order_by(Recommendation.final_score.desc())
    
    total = query.count()
    recommendations = query.offset(skip).limit(limit).all()
    
    # ✅ N+1 problemini çöz: Tüm department ve university'leri tek seferde çek
    from models.university import Department, University
    from schemas.university import DepartmentWithUniversityResponse
    
    department_ids = {rec.department_id for rec in recommendations}
    departments_dict = {
        dept.id: dept
        for dept in db.query(Department).filter(Department.id.in_(department_ids)).all()
    }
    
    university_ids = {dept.university_id for dept in departments_dict.values()}
    universities_dict = {
        uni.id: uni
        for uni in db.query(University).filter(University.id.in_(university_ids)).all()
    }
    
    # Response formatına çevir
    result = []
    for rec in recommendations:
        department = departments_dict.get(rec.department_id)
        if not department:
            continue
        
        university = universities_dict.get(department.university_id)
        if not university:
            continue
        
        department_response = DepartmentWithUniversityResponse(
            **department.__dict__,
            university=university
        )
        
        result.append(RecommendationResponse(
            **rec.__dict__,
            department=department_response
        ))
    
    # ✅ FALLBACK: Eğer öneri yoksa popüler bölümleri döndür
    if not result or len(result) == 0:
        api_logger.info("No recommendations found, returning popular departments", user_id=student_id)
        from models.university import Department, University
        from schemas.university import DepartmentWithUniversityResponse
        
        # ✅ min_score None olan bölümleri filtreleme dışında bırak
        popular_query = db.query(Department).filter(
            Department.min_score.isnot(None),
            Department.min_score > 0
        )
        
        # Öğrencinin alan türüne uygun popüler bölümleri getir
        if student.field_type:
            popular_query = popular_query.filter(Department.field_type == student.field_type)
        
        popular_departments = popular_query.order_by(
            Department.min_score.desc()  # En yüksek puanlılar önce
        ).limit(min(limit, 10)).all()  # Maksimum 10 bölüm
        
        if not popular_departments:
            # Eğer alan türüne uygun yoksa, tüm popüler bölümleri getir
            popular_departments = db.query(Department).filter(
                Department.min_score.isnot(None),
                Department.min_score > 0
            ).order_by(
                Department.min_score.desc()
            ).limit(min(limit, 10)).all()
        
        # University'leri çek
        university_ids = {dept.university_id for dept in popular_departments}
        universities_dict = {
            uni.id: uni
            for uni in db.query(University).filter(University.id.in_(university_ids)).all()
        }
        
        # Response formatına çevir (dummy RecommendationResponse oluştur)
        for dept in popular_departments:
            university = universities_dict.get(dept.university_id)
            if not university:
                continue
            
            department_response = DepartmentWithUniversityResponse(
                **dept.__dict__,
                university=university
            )
            
            # Dummy recommendation oluştur (final_score = 50.0 varsayılan)
            result.append(RecommendationResponse(
                student_id=student_id,
                department_id=dept.id,
                department=department_response,
                compatibility_score=50.0,
                success_probability=50.0,
                preference_score=50.0,
                final_score=50.0,
                is_safe_choice=False,
                is_dream_choice=False,
                is_realistic_choice=True
            ))
        
        total = len(result)
    
    return RecommendationListResponse(
        recommendations=result,
        total=total,
        page=skip // limit + 1,
        size=limit
    )


@router.get("/{recommendation_id}", response_model=RecommendationResponse)
async def get_recommendation(recommendation_id: int, db: Session = Depends(get_db)):
    """Belirli bir öneriyi getir"""
    recommendation = db.query(Recommendation).filter(Recommendation.id == recommendation_id).first()
    if not recommendation:
        raise HTTPException(status_code=404, detail="Öneri bulunamadı")
    
    # Department ve University bilgilerini getir
    from models.university import Department, University
    from schemas.university import DepartmentWithUniversityResponse
    
    department = db.query(Department).filter(Department.id == recommendation.department_id).first()
    university = db.query(University).filter(University.id == department.university_id).first()
    
    department_response = DepartmentWithUniversityResponse(
        **department.__dict__,
        university=university
    )
    
    return RecommendationResponse(
        **recommendation.__dict__,
        department=department_response
    )


@router.get("/goal-proximity/{student_id}/{department_id}")
async def get_goal_proximity(
    student_id: int,
    department_id: int,
    db: Session = Depends(get_db)
):
    """Öğrencinin seçilen bölüme hedef yakınlığını döndürür.
    TYT/AYT hedefleri yoksa toplam puan vs bölüm min_score üzerinden yaklaşık yakınlık verir.
    """
    from models.university import Department

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")

    department = db.query(Department).filter(Department.id == department_id).first()
    if not department:
        raise HTTPException(status_code=404, detail="Bölüm bulunamadı")

    target_tyt = 0.0
    target_ayt = 0.0
    # ✅ min_score None kontrolü: Eğer min_score None ise, 0.0 kullan
    if getattr(department, 'min_score', None) is not None and department.min_score > 0:
        target_ayt = float(department.min_score)

    try:
        proximity = ScoreCalculator.calculate_goal_proximity(
            student_tyt_score=float(student.tyt_total_score or 0.0),
            student_ayt_score=float(student.ayt_total_score or 0.0),
            target_tyt_score=target_tyt,
            target_ayt_score=target_ayt,
        )
    except Exception:
        overall = 0.0
        # ✅ min_score None kontrolü: Eğer min_score None ise, hesaplama yapma
        if getattr(department, 'min_score', None) is not None and department.min_score > 0:
            student_score = float(student.total_score or 0.0)
            dept_score = float(department.min_score)
            if dept_score > 0:
                overall = min(100.0, (student_score / dept_score) * 100.0)
        
        # ✅ min_score None ise gap hesaplama yapma
        dept_score = float(department.min_score) if (getattr(department, 'min_score', None) is not None and department.min_score > 0) else 0.0
        student_score = float(student.total_score or 0.0)
        
        proximity = {
            'tyt_proximity': 0.0,
            'ayt_proximity': round(overall, 2),
            'overall_proximity': round(overall, 2),
            'tyt_gap': 0.0,
            'ayt_gap': round(dept_score - student_score, 2) if dept_score > 0 else 0.0,
            'is_ready': student_score >= dept_score if dept_score > 0 else False,
        }

    api_logger.info("Goal proximity calculated", user_id=student_id, department_id=department_id)
    return proximity


@router.delete("/student/{student_id}")
async def clear_student_recommendations(student_id: int, db: Session = Depends(get_db)):
    """Öğrencinin tüm önerilerini temizle"""
    # Öğrenci var mı kontrol et
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    # Önerileri sil
    db.query(Recommendation).filter(Recommendation.student_id == student_id).delete()
    db.commit()
    
    return {"message": "Öğrencinin tüm önerileri temizlendi"}


@router.delete("/{recommendation_id}")
async def delete_recommendation(recommendation_id: int, db: Session = Depends(get_db)):
    """Belirli bir öneriyi sil"""
    recommendation = db.query(Recommendation).filter(Recommendation.id == recommendation_id).first()
    if not recommendation:
        raise HTTPException(status_code=404, detail="Öneri bulunamadı")
    
    db.delete(recommendation)
    db.commit()
    
    return {"message": "Öneri başarıyla silindi"}


@router.get("/stats/{student_id}")
async def get_recommendation_stats(student_id: int, db: Session = Depends(get_db)):
    """Öğrencinin öneri istatistiklerini getir"""
    # Öğrenci var mı kontrol et
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    # İstatistikleri hesapla
    total_recommendations = db.query(Recommendation).filter(Recommendation.student_id == student_id).count()
    safe_choices = db.query(Recommendation).filter(
        Recommendation.student_id == student_id,
        Recommendation.is_safe_choice == True
    ).count()
    dream_choices = db.query(Recommendation).filter(
        Recommendation.student_id == student_id,
        Recommendation.is_dream_choice == True
    ).count()
    realistic_choices = db.query(Recommendation).filter(
        Recommendation.student_id == student_id,
        Recommendation.is_realistic_choice == True
    ).count()
    
    # Ortalama skorları hesapla
    avg_compatibility = db.query(Recommendation).filter(Recommendation.student_id == student_id).with_entities(
        db.func.avg(Recommendation.compatibility_score)
    ).scalar() or 0
    
    avg_success = db.query(Recommendation).filter(Recommendation.student_id == student_id).with_entities(
        db.func.avg(Recommendation.success_probability)
    ).scalar() or 0
    
    avg_preference = db.query(Recommendation).filter(Recommendation.student_id == student_id).with_entities(
        db.func.avg(Recommendation.preference_score)
    ).scalar() or 0
    
    return {
        "student_id": student_id,
        "total_recommendations": total_recommendations,
        "safe_choices": safe_choices,
        "dream_choices": dream_choices,
        "realistic_choices": realistic_choices,
        "average_scores": {
            "compatibility": round(avg_compatibility, 2),
            "success_probability": round(avg_success, 2),
            "preference": round(avg_preference, 2)
        }
    }

