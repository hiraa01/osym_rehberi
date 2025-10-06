from typing import Dict, Any
import math
from core.logging_config import net_calc_logger
from core.exceptions import InvalidScoreError


class ScoreCalculator:
    """TYT ve AYT puan hesaplama servisi"""
    
    # TYT katsayıları (2024 güncel)
    TYT_COEFFICIENTS = {
        'turkish': 1.32,
        'math': 1.32,
        'social': 1.36,
        'science': 1.36
    }
    
    # AYT katsayıları (2024 güncel)
    AYT_COEFFICIENTS = {
        'math': 3.0,
        'physics': 2.85,
        'chemistry': 3.07,
        'biology': 3.07,
        'literature': 3.0,
        'history1': 2.8,
        'geography1': 3.33,
        'philosophy': 3.0,
        'history2': 2.91,
        'geography2': 2.91,
        'foreign_language': 3.0
    }
    
    # Alan türüne göre AYT dersleri
    FIELD_SUBJECTS = {
        'SAY': ['math', 'physics', 'chemistry', 'biology'],
        'EA': ['math', 'literature', 'history1', 'geography1'],
        'SÖZ': ['literature', 'history1', 'geography1', 'philosophy'],
        'DİL': ['foreign_language']
    }
    
    @classmethod
    def calculate_tyt_score(cls, nets: Dict[str, float]) -> float:
        """TYT puanını hesapla"""
        total_score = 0.0
        
        for subject, net in nets.items():
            if subject in cls.TYT_COEFFICIENTS:
                total_score += net * cls.TYT_COEFFICIENTS[subject]
        
        # TYT ham puanı 100 ile çarpılıp 500'e eklenir
        return (total_score * 100) + 500
    
    @classmethod
    def calculate_ayt_score(cls, nets: Dict[str, float], field_type: str) -> float:
        """AYT puanını hesapla"""
        if field_type not in cls.FIELD_SUBJECTS:
            return 0.0
        
        total_score = 0.0
        valid_subjects = cls.FIELD_SUBJECTS[field_type]
        
        for subject in valid_subjects:
            if subject in nets and subject in cls.AYT_COEFFICIENTS:
                total_score += nets[subject] * cls.AYT_COEFFICIENTS[subject]
        
        # AYT ham puanı 100 ile çarpılıp 100'e eklenir
        return (total_score * 100) + 100
    
    @classmethod
    def calculate_total_score(cls, tyt_score: float, ayt_score: float, field_type: str) -> float:
        """Toplam puanı hesapla"""
        if field_type == 'SAY':
            return tyt_score * 0.4 + ayt_score * 0.6
        elif field_type == 'EA':
            return tyt_score * 0.4 + ayt_score * 0.6
        elif field_type == 'SÖZ':
            return tyt_score * 0.4 + ayt_score * 0.6
        elif field_type == 'DİL':
            return tyt_score * 0.4 + ayt_score * 0.6
        else:
            return tyt_score
    
    @classmethod
    def estimate_rank(cls, total_score: float, field_type: str) -> int:
        """Puanına göre yaklaşık başarı sırası tahmin et"""
        # Bu basit bir tahmin algoritmasıdır
        # Gerçek uygulamada YÖK verilerine dayalı daha karmaşık hesaplama yapılmalı
        
        base_ranks = {
            'SAY': 500000,
            'EA': 200000,
            'SÖZ': 150000,
            'DİL': 50000
        }
        
        if field_type not in base_ranks:
            return 1000000
        
        # Puan aralığına göre sıralama tahmini
        if total_score >= 500:
            return int(base_ranks[field_type] * 0.01)
        elif total_score >= 450:
            return int(base_ranks[field_type] * 0.05)
        elif total_score >= 400:
            return int(base_ranks[field_type] * 0.15)
        elif total_score >= 350:
            return int(base_ranks[field_type] * 0.35)
        elif total_score >= 300:
            return int(base_ranks[field_type] * 0.65)
        else:
            return int(base_ranks[field_type] * 0.9)
    
    @classmethod
    def calculate_percentile(cls, rank: int, field_type: str) -> float:
        """Başarı sırasına göre yüzdelik dilim hesapla"""
        total_candidates = {
            'SAY': 500000,
            'EA': 200000,
            'SÖZ': 150000,
            'DİL': 50000
        }
        
        if field_type not in total_candidates:
            return 0.0
        
        return (1 - (rank / total_candidates[field_type])) * 100
    
    @classmethod
    def calculate_all_scores(cls, student_data: Dict[str, Any]) -> Dict[str, float]:
        """Öğrenci verilerine göre tüm puanları hesapla"""
        try:
            student_id = student_data.get('id')
            net_calc_logger.info("Starting score calculation", user_id=student_id)
            
            # TYT netleri
            tyt_nets = {
                'turkish': student_data.get('tyt_turkish_net', 0.0),
                'math': student_data.get('tyt_math_net', 0.0),
                'social': student_data.get('tyt_social_net', 0.0),
                'science': student_data.get('tyt_science_net', 0.0)
            }
            
            # AYT netleri
            ayt_nets = {
                'math': student_data.get('ayt_math_net', 0.0),
                'physics': student_data.get('ayt_physics_net', 0.0),
                'chemistry': student_data.get('ayt_chemistry_net', 0.0),
                'biology': student_data.get('ayt_biology_net', 0.0),
                'literature': student_data.get('ayt_literature_net', 0.0),
                'history1': student_data.get('ayt_history1_net', 0.0),
                'geography1': student_data.get('ayt_geography1_net', 0.0),
                'philosophy': student_data.get('ayt_philosophy_net', 0.0),
                'history2': student_data.get('ayt_history2_net', 0.0),
                'geography2': student_data.get('ayt_geography2_net', 0.0),
                'foreign_language': student_data.get('ayt_foreign_language_net', 0.0)
            }
            
            field_type = student_data.get('field_type', 'SAY')
            
            # Puanları hesapla
            tyt_score = cls.calculate_tyt_score(tyt_nets)
            ayt_score = cls.calculate_ayt_score(ayt_nets, field_type)
            total_score = cls.calculate_total_score(tyt_score, ayt_score, field_type)
            rank = cls.estimate_rank(total_score, field_type)
            percentile = cls.calculate_percentile(rank, field_type)
            
            result = {
                'tyt_total_score': round(tyt_score, 2),
                'ayt_total_score': round(ayt_score, 2),
                'total_score': round(total_score, 2),
                'rank': rank,
                'percentile': round(percentile, 2)
            }
            
            net_calc_logger.info(
                "Score calculation completed successfully",
                user_id=student_id,
                tyt_score=tyt_score,
                ayt_score=ayt_score,
                total_score=total_score,
                rank=rank
            )
            
            return result
            
        except Exception as e:
            net_calc_logger.error(
                "Score calculation failed",
                user_id=student_data.get('id'),
                error=str(e)
            )
            raise InvalidScoreError(f"Score calculation failed: {str(e)}")
