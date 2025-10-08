from typing import List, Dict, Any, Tuple
from sqlalchemy.orm import Session
from models.student import Student
from models.university import Department, University, Recommendation
from schemas.university import RecommendationResponse, DepartmentWithUniversityResponse
from core.logging_config import recommendation_logger
from core.exceptions import RecommendationError, StudentNotFoundError
import json


class RecommendationEngine:
    """Yapay zeka destekli tercih öneri motoru"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def generate_recommendations(self, student_id: int, limit: int = 50) -> List[RecommendationResponse]:
        """Öğrenci için tercih önerileri oluştur"""
        try:
            recommendation_logger.info(
                "Starting recommendation generation",
                user_id=student_id,
                limit=limit
            )
            
            student = self.db.query(Student).filter(Student.id == student_id).first()
            if not student:
                recommendation_logger.warning(
                    "Student not found for recommendation generation",
                    user_id=student_id
                )
                raise StudentNotFoundError(f"Student with ID {student_id} not found")
            
            # Öğrencinin alan türüne uygun bölümleri getir
            departments = self.db.query(Department).filter(
                Department.field_type == student.field_type
            ).all()
            
            recommendations = []
            
            for department in departments:
                # Uyumluluk skorunu hesapla
                compatibility_score = self._calculate_compatibility_score(student, department)
                
                # Başarı olasılığını hesapla
                success_probability = self._calculate_success_probability(student, department)
                
                # Tercih skorunu hesapla
                preference_score = self._calculate_preference_score(student, department)
                
                # Final skorunu hesapla (ağırlıklı ortalama)
                final_score = (
                    compatibility_score * 0.4 +
                    success_probability * 0.4 +
                    preference_score * 0.2
                )
                
                # Öneri türünü belirle
                is_safe = success_probability >= 80
                is_dream = success_probability <= 30
                is_realistic = 30 < success_probability < 80
                
                # Öneri sebebini oluştur
                reason = self._generate_recommendation_reason(
                    student, department, compatibility_score, 
                    success_probability, preference_score
                )
                
                # Veritabanına kaydet
                recommendation = Recommendation(
                    student_id=student_id,
                    department_id=department.id,
                    compatibility_score=compatibility_score,
                    success_probability=success_probability,
                    preference_score=preference_score,
                    final_score=final_score,
                    recommendation_reason=reason,
                    is_safe_choice=is_safe,
                    is_dream_choice=is_dream,
                    is_realistic_choice=is_realistic
                )
                
                self.db.add(recommendation)
                recommendations.append(recommendation)
            
            self.db.commit()
            
            # Final skora göre sırala ve limit uygula
            recommendations.sort(key=lambda x: x.final_score, reverse=True)
            recommendations = recommendations[:limit]
            
            # Response formatına çevir
            result = []
            for rec in recommendations:
                department = self.db.query(Department).filter(Department.id == rec.department_id).first()
                university = self.db.query(University).filter(University.id == department.university_id).first()
                
                department_response = DepartmentWithUniversityResponse(
                    **department.__dict__,
                    university=university
                )
                
                result.append(RecommendationResponse(
                    **rec.__dict__,
                    department=department_response
                ))
            
            recommendation_logger.info(
                "Recommendations generated successfully",
                user_id=student_id,
                count=len(result)
            )
            return result
            
        except StudentNotFoundError:
            recommendation_logger.error("Student not found", user_id=student_id)
            raise
        except Exception as e:
            recommendation_logger.error(f"Error generating recommendations: {str(e)}", user_id=student_id)
            self.db.rollback()
            raise RecommendationError(f"Tercih önerileri oluşturulurken bir hata oluştu: {str(e)}")
    
    def _calculate_compatibility_score(self, student: Student, department: Department) -> float:
        """Uyumluluk skorunu hesapla (0-100)"""
        score = 50.0  # Base score
        
        # Puan uyumluluğu
        if department.min_score and student.total_score:
            score_diff = student.total_score - department.min_score
            if score_diff > 50:
                score += 20
            elif score_diff > 20:
                score += 15
            elif score_diff > 0:
                score += 10
            elif score_diff > -20:
                score += 5
            else:
                score -= 10
        
        # Sıralama uyumluluğu
        if department.min_rank and student.rank:
            rank_diff = department.min_rank - student.rank
            if rank_diff > 10000:
                score += 15
            elif rank_diff > 5000:
                score += 10
            elif rank_diff > 0:
                score += 5
            else:
                score -= 5
        
        # Alan uyumluluğu
        if student.field_type == department.field_type:
            score += 10
        
        return max(0, min(100, score))
    
    def _calculate_success_probability(self, student: Student, department: Department) -> float:
        """Başarı olasılığını hesapla (0-100)"""
        if not department.min_score or not student.total_score:
            return 50.0
        
        score_diff = student.total_score - department.min_score
        
        if score_diff > 50:
            return 95.0
        elif score_diff > 30:
            return 85.0
        elif score_diff > 10:
            return 70.0
        elif score_diff > 0:
            return 60.0
        elif score_diff > -10:
            return 40.0
        elif score_diff > -30:
            return 20.0
        else:
            return 5.0
    
    def _calculate_preference_score(self, student: Student, department: Department) -> float:
        """Tercih skorunu hesapla (0-100)"""
        score = 50.0  # Base score
        
        # Şehir tercihi
        if student.preferred_cities:
            try:
                preferred_cities = json.loads(student.preferred_cities)
                university = self.db.query(University).filter(University.id == department.university_id).first()
                if university and university.city in preferred_cities:
                    score += 20
            except:
                pass
        
        # Üniversite türü tercihi
        if student.preferred_university_types:
            try:
                preferred_types = json.loads(student.preferred_university_types)
                university = self.db.query(University).filter(University.id == department.university_id).first()
                if university and university.university_type in preferred_types:
                    score += 15
            except:
                pass
        
        # Burs tercihi
        if student.scholarship_preference and department.has_scholarship:
            score += 15
        
        # Bütçe tercihi
        if student.budget_preference == 'low' and department.tuition_fee and department.tuition_fee < 10000:
            score += 10
        elif student.budget_preference == 'high' and department.tuition_fee and department.tuition_fee > 50000:
            score += 10
        
        # İlgi alanları
        if student.interest_areas:
            try:
                interest_areas = json.loads(student.interest_areas)
                # Basit anahtar kelime eşleştirmesi
                department_name_lower = department.name.lower()
                for area in interest_areas:
                    if area.lower() in department_name_lower:
                        score += 5
            except:
                pass
        
        return max(0, min(100, score))
    
    def _generate_recommendation_reason(self, student: Student, department: Department, 
                                      compatibility: float, success: float, preference: float) -> str:
        """Öneri sebebini oluştur"""
        reasons = []
        
        if success >= 80:
            reasons.append("Yüksek başarı olasılığı")
        elif success >= 60:
            reasons.append("Orta başarı olasılığı")
        else:
            reasons.append("Düşük başarı olasılığı")
        
        if compatibility >= 80:
            reasons.append("Yüksek uyumluluk")
        elif compatibility >= 60:
            reasons.append("Orta uyumluluk")
        
        if preference >= 80:
            reasons.append("Tercihlerinize uygun")
        elif preference >= 60:
            reasons.append("Kısmen tercihlerinize uygun")
        
        # Puan farkı
        if department.min_score and student.total_score:
            score_diff = student.total_score - department.min_score
            if score_diff > 20:
                reasons.append("Puanınız bölümün taban puanından yüksek")
            elif score_diff > 0:
                reasons.append("Puanınız bölümün taban puanına yakın")
            else:
                reasons.append("Puanınız bölümün taban puanından düşük")
        
        return ", ".join(reasons) if reasons else "Genel uyumluluk"
