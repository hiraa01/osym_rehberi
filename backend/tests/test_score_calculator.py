import pytest
from services.score_calculator import ScoreCalculator

class TestScoreCalculator:
    """ScoreCalculator servisinin testleri"""
    
    def test_calculate_tyt_score(self):
        """TYT puan hesaplama testi"""
        student_data = {
            'tyt_turkish_net': 30.0,
            'tyt_math_net': 25.0,
            'tyt_social_net': 15.0,
            'tyt_science_net': 20.0,
        }
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'tyt_total_score' in scores
        assert scores['tyt_total_score'] == 90.0  # 30 + 25 + 15 + 20
        
    def test_calculate_ayt_score(self):
        """AYT puan hesaplama testi"""
        student_data = {
            'ayt_math_net': 20.0,
            'ayt_physics_net': 15.0,
            'ayt_chemistry_net': 10.0,
            'ayt_biology_net': 12.0,
        }
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'ayt_total_score' in scores
        assert scores['ayt_total_score'] == 57.0  # 20 + 15 + 10 + 12
        
    def test_calculate_total_score(self):
        """Toplam puan hesaplama testi"""
        student_data = {
            'tyt_turkish_net': 30.0,
            'tyt_math_net': 25.0,
            'tyt_social_net': 15.0,
            'tyt_science_net': 20.0,
            'ayt_math_net': 20.0,
            'ayt_physics_net': 15.0,
            'ayt_chemistry_net': 10.0,
            'ayt_biology_net': 12.0,
        }
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'total_score' in scores
        assert scores['total_score'] == 147.0  # 90 + 57
        
    def test_calculate_rank(self):
        """Sıralama hesaplama testi"""
        student_data = {
            'total_score': 500.0,
        }
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'rank' in scores
        assert scores['rank'] > 0
        
    def test_calculate_percentile(self):
        """Yüzdelik dilim hesaplama testi"""
        student_data = {
            'total_score': 500.0,
        }
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'percentile' in scores
        assert 0 <= scores['percentile'] <= 100
        
    def test_empty_scores(self):
        """Boş skorlar için test"""
        student_data = {}
        
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        assert 'tyt_total_score' in scores
        assert 'ayt_total_score' in scores
        assert 'total_score' in scores
        assert scores['tyt_total_score'] == 0.0
        assert scores['ayt_total_score'] == 0.0
        assert scores['total_score'] == 0.0
