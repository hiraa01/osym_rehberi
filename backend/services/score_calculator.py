"""
YKS Puan Hesaplama Servisi
ÖSYM resmi katsayılarına göre TYT ve AYT puan hesaplaması
"""
from typing import Dict, Optional


class ScoreCalculator:
    """YKS 2025 Puan Hesaplama"""
    
    # TYT Katsayıları (Sadece TYT'ye girenler için - 2 yıllık)
    TYT_ONLY_COEFFICIENTS = {
        'turkish': 3.3,
        'math': 3.3,
        'science': 3.4,
        'social': 3.4,
    }
    
    # TYT Katsayıları (4 yıllık için - AYT ile birlikte)
    TYT_FOR_AYT_COEFFICIENTS = {
        'turkish': 1.32,
        'math': 1.32,
        'science': 1.36,
        'social': 1.36,
    }
    
    # AYT Katsayıları - Sayısal (MF)
    AYT_SAY_COEFFICIENTS = {
        'math': 3.0,
        'physics': 2.85,
        'chemistry': 3.07,
        'biology': 3.07,
    }
    
    # AYT Katsayıları - Eşit Ağırlık (TM)
    AYT_EA_COEFFICIENTS = {
        'math': 3.0,
        'literature': 3.0,
        'history1': 2.8,
        'geography1': 3.3,
    }
    
    # AYT Katsayıları - Sözel (TS)
    AYT_SOZ_COEFFICIENTS = {
        'literature': 3.0,
        'history1': 2.8,
        'geography1': 3.3,
        'history2': 2.9,
        'geography2': 2.9,
        'philosophy': 3.0,
        'religion': 3.3,  # Din Kültürü
    }
    
    # AYT Katsayıları - Yabancı Dil
    AYT_DIL_COEFFICIENTS = {
        'language': 3.0,
    }
    
    BASE_SCORE = 100.0  # Taban puan
    MAX_SCORE = 560.0   # Maksimum puan
    
    @classmethod
    def calculate_tyt_score(
        cls,
        turkish_net: float,
        math_net: float,
        science_net: float,
        social_net: float,
        with_ayt: bool = True
    ) -> float:
        """
        TYT puanını hesaplar
        
        Args:
            turkish_net: Türkçe net sayısı
            math_net: Matematik net sayısı
            science_net: Fen net sayısı
            social_net: Sosyal net sayısı
            with_ayt: AYT'ye girecekse True (4 yıllık), sadece TYT'ye girecekse False (2 yıllık)
        
        Returns:
            TYT puanı (100-560 arası)
        """
        coefficients = cls.TYT_FOR_AYT_COEFFICIENTS if with_ayt else cls.TYT_ONLY_COEFFICIENTS
        
        tyt_raw_score = (
            turkish_net * coefficients['turkish'] +
            math_net * coefficients['math'] +
            science_net * coefficients['science'] +
            social_net * coefficients['social']
        )
        
        # Taban puan ekle
        tyt_score = cls.BASE_SCORE + tyt_raw_score
        
        # Limit kontrolü
        return min(max(tyt_score, cls.BASE_SCORE), cls.MAX_SCORE)
    
    @classmethod
    def calculate_ayt_score(
        cls,
        field_type: str,
        tyt_turkish_net: float,
        tyt_math_net: float,
        tyt_science_net: float,
        tyt_social_net: float,
        **ayt_nets
    ) -> float:
        """
        AYT puanını hesaplar (TYT katsayıları dahil)
        
        Args:
            field_type: Alan türü ('SAY', 'EA', 'SÖZ', 'DİL')
            tyt_turkish_net, tyt_math_net, tyt_science_net, tyt_social_net: TYT netleri
            **ayt_nets: AYT netleri (math_net, physics_net, chemistry_net, vb.)
        
        Returns:
            AYT puanı (100-560 arası)
        """
        field_type = field_type.upper()
        
        # TYT kısmı (AYT katsayılarıyla)
        tyt_part = (
            tyt_turkish_net * cls.TYT_FOR_AYT_COEFFICIENTS['turkish'] +
            tyt_math_net * cls.TYT_FOR_AYT_COEFFICIENTS['math'] +
            tyt_science_net * cls.TYT_FOR_AYT_COEFFICIENTS['science'] +
            tyt_social_net * cls.TYT_FOR_AYT_COEFFICIENTS['social']
        )
        
        # AYT kısmı (alan türüne göre)
        ayt_part = 0.0
        
        if field_type == 'SAY':  # Sayısal
            ayt_part = (
                ayt_nets.get('math_net', 0) * cls.AYT_SAY_COEFFICIENTS['math'] +
                ayt_nets.get('physics_net', 0) * cls.AYT_SAY_COEFFICIENTS['physics'] +
                ayt_nets.get('chemistry_net', 0) * cls.AYT_SAY_COEFFICIENTS['chemistry'] +
                ayt_nets.get('biology_net', 0) * cls.AYT_SAY_COEFFICIENTS['biology']
            )
        
        elif field_type == 'EA':  # Eşit Ağırlık
            ayt_part = (
                ayt_nets.get('math_net', 0) * cls.AYT_EA_COEFFICIENTS['math'] +
                ayt_nets.get('literature_net', 0) * cls.AYT_EA_COEFFICIENTS['literature'] +
                ayt_nets.get('history1_net', 0) * cls.AYT_EA_COEFFICIENTS['history1'] +
                ayt_nets.get('geography1_net', 0) * cls.AYT_EA_COEFFICIENTS['geography1']
            )
        
        elif field_type in ['SOZ', 'SÖZ']:  # Sözel
            ayt_part = (
                ayt_nets.get('literature_net', 0) * cls.AYT_SOZ_COEFFICIENTS['literature'] +
                ayt_nets.get('history1_net', 0) * cls.AYT_SOZ_COEFFICIENTS['history1'] +
                ayt_nets.get('geography1_net', 0) * cls.AYT_SOZ_COEFFICIENTS['geography1'] +
                ayt_nets.get('history2_net', 0) * cls.AYT_SOZ_COEFFICIENTS['history2'] +
                ayt_nets.get('geography2_net', 0) * cls.AYT_SOZ_COEFFICIENTS['geography2'] +
                ayt_nets.get('philosophy_net', 0) * cls.AYT_SOZ_COEFFICIENTS['philosophy'] +
                ayt_nets.get('religion_net', 0) * cls.AYT_SOZ_COEFFICIENTS.get('religion', 0)
            )
        
        elif field_type in ['DIL', 'DİL']:  # Yabancı Dil
            ayt_part = (
                ayt_nets.get('language_net', 0) * cls.AYT_DIL_COEFFICIENTS['language']
            )
        
        # Toplam AYT puanı
        ayt_score = cls.BASE_SCORE + tyt_part + ayt_part
        
        # Limit kontrolü
        return min(max(ayt_score, cls.BASE_SCORE), cls.MAX_SCORE)
    
    @classmethod
    def calculate_total_score_with_obp(
        cls,
        tyt_score: float,
        ayt_score: float,
        obp_score: Optional[float] = None
    ) -> float:
        """
        OBP ile toplam puan hesaplar
        
        Args:
            tyt_score: TYT puanı
            ayt_score: AYT puanı
            obp_score: OBP (Okul Başarı Puanı) - Opsiyonel
        
        Returns:
            Toplam puan (TYT + AYT + OBP)
        """
        # NOT: Kullanıcı "TYT ve AYT puanını toplamamalısın" dedi
        # Ama gerçekte YKS sistemi toplayarak hesaplıyor
        # Burada sadece OBP ekleniyor, TYT/AYT zaten ayrı tutulacak
        total = ayt_score  # AYT puanı zaten TYT'yi içeriyor
        
        if obp_score:
            total += obp_score
        
        return min(total, cls.MAX_SCORE)
    
    @classmethod
    def calculate_all_scores(cls, attempt_data: Dict) -> Dict[str, float]:
        """
        Deneme verilerinden tüm puanları hesaplar
        
        Args:
            attempt_data: Deneme verileri (netleri + field_type içermeli)
        
        Returns:
            {
                'tyt_total_score': TYT puanı,
                'ayt_total_score': AYT puanı,
                'total_score': Toplam puan,
                'rank': Tahmini sıralama (şimdilik placeholder),
                'percentile': Yüzdelik dilim (şimdilik placeholder)
            }
        """
        field_type = attempt_data.get('field_type', 'SAY')
        
        # TYT puanı hesapla
        tyt_score = cls.calculate_tyt_score(
            turkish_net=attempt_data.get('tyt_turkish_net', 0.0),
            math_net=attempt_data.get('tyt_math_net', 0.0),
            science_net=attempt_data.get('tyt_science_net', 0.0),
            social_net=attempt_data.get('tyt_social_net', 0.0),
            with_ayt=True  # AYT'ye girecek varsayıyoruz
        )
        
        # AYT puanı hesapla
        ayt_score = cls.calculate_ayt_score(
            field_type=field_type,
            tyt_turkish_net=attempt_data.get('tyt_turkish_net', 0.0),
            tyt_math_net=attempt_data.get('tyt_math_net', 0.0),
            tyt_science_net=attempt_data.get('tyt_science_net', 0.0),
            tyt_social_net=attempt_data.get('tyt_social_net', 0.0),
            math_net=attempt_data.get('ayt_math_net', 0.0),
            physics_net=attempt_data.get('ayt_physics_net', 0.0),
            chemistry_net=attempt_data.get('ayt_chemistry_net', 0.0),
            biology_net=attempt_data.get('ayt_biology_net', 0.0),
            literature_net=attempt_data.get('ayt_literature_net', 0.0),
            history1_net=attempt_data.get('ayt_history1_net', 0.0),
            geography1_net=attempt_data.get('ayt_geography1_net', 0.0),
            history2_net=attempt_data.get('ayt_history2_net', 0.0),
            geography2_net=attempt_data.get('ayt_geography2_net', 0.0),
            philosophy_net=attempt_data.get('ayt_philosophy_net', 0.0),
            religion_net=attempt_data.get('ayt_religion_net', 0.0),
            language_net=attempt_data.get('ayt_foreign_language_net', 0.0)
        )
        
        # OBP ekle (varsa)
        obp_score = attempt_data.get('obp_score', 0.0) or 0.0
        total_score = ayt_score + obp_score  # AYT zaten TYT'yi içeriyor
        
        # Rank ve percentile hesaplama (şimdilik placeholder)
        # TODO: Gerçek sıralama için tüm öğrencilerin puanlarını karşılaştır
        rank = 0
        percentile = 0.0
        
        return {
            'tyt_total_score': round(tyt_score, 4),
            'ayt_total_score': round(ayt_score, 4),
            'total_score': round(total_score, 4),
            'rank': rank,
            'percentile': percentile
        }
    
    @classmethod
    def calculate_goal_proximity(
        cls,
        student_tyt_score: float,
        student_ayt_score: float,
        target_tyt_score: float,
        target_ayt_score: float
    ) -> Dict[str, float]:
        """
        Hedefe yakınlık hesaplar (TYT ve AYT AYRI karşılaştırılır)
        
        Args:
            student_tyt_score: Öğrencinin TYT puanı
            student_ayt_score: Öğrencinin AYT puanı
            target_tyt_score: Hedef bölümün TYT taban puanı
            target_ayt_score: Hedef bölümün AYT taban puanı
        
        Returns:
            {
                'tyt_proximity': TYT yakınlık yüzdesi (0-100),
                'ayt_proximity': AYT yakınlık yüzdesi (0-100),
                'overall_proximity': Genel yakınlık yüzdesi (0-100),
                'tyt_gap': TYT puan farkı,
                'ayt_gap': AYT puan farkı,
                'is_ready': Hedef için hazır mı?
            }
        """
        tyt_gap = target_tyt_score - student_tyt_score
        ayt_gap = target_ayt_score - student_ayt_score
        
        # Yakınlık yüzdesi (100% = hedef puanına ulaşmış veya aşmış)
        tyt_proximity = min(100.0, (student_tyt_score / target_tyt_score) * 100) if target_tyt_score > 0 else 100.0
        ayt_proximity = min(100.0, (student_ayt_score / target_ayt_score) * 100) if target_ayt_score > 0 else 100.0
        
        # Genel yakınlık (TYT ve AYT ortalaması)
        overall_proximity = (tyt_proximity + ayt_proximity) / 2.0
        
        # Hedefe hazır mı? (Her iki puan da hedefi geçmiş olmalı)
        is_ready = student_tyt_score >= target_tyt_score and student_ayt_score >= target_ayt_score
        
        return {
            'tyt_proximity': round(tyt_proximity, 2),
            'ayt_proximity': round(ayt_proximity, 2),
            'overall_proximity': round(overall_proximity, 2),
            'tyt_gap': round(tyt_gap, 2),
            'ayt_gap': round(ayt_gap, 2),
            'is_ready': is_ready
        }
