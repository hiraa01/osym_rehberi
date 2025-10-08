import pytest
from unittest.mock import Mock, MagicMock
from services.recommendation_engine import RecommendationEngine
from models.student import Student
from models.university import Department, University

class TestRecommendationEngine:
    """RecommendationEngine servisinin testleri"""
    
    def setup_method(self):
        """Her test öncesi çalışacak setup"""
        self.mock_db = Mock()
        self.engine = RecommendationEngine(self.mock_db)
        
    def test_calculate_compatibility_score(self):
        """Uyumluluk skoru hesaplama testi"""
        student = Student(
            name="Test Student",
            class_level="12",
            exam_type="TYT+AYT",
            field_type="SAY",
            total_score=450.0,
            rank=1000
        )
        
        department = Department(
            name="Test Department",
            field_type="SAY",
            university_id=1,
            min_score=400.0,
            min_rank=1500
        )
        
        score = self.engine._calculate_compatibility_score(student, department)
        
        assert 0 <= score <= 100
        assert score > 50  # Puanı yüksek olduğu için skor yüksek olmalı
        
    def test_calculate_success_probability(self):
        """Başarı olasılığı hesaplama testi"""
        student = Student(
            name="Test Student",
            class_level="12",
            exam_type="TYT+AYT",
            field_type="SAY",
            total_score=450.0
        )
        
        department = Department(
            name="Test Department",
            field_type="SAY",
            university_id=1,
            min_score=400.0
        )
        
        probability = self.engine._calculate_success_probability(student, department)
        
        assert 0 <= probability <= 100
        assert probability > 50  # Puanı yüksek olduğu için olasılık yüksek olmalı
        
    def test_calculate_preference_score(self):
        """Tercih skoru hesaplama testi"""
        student = Student(
            name="Test Student",
            class_level="12",
            exam_type="TYT+AYT",
            field_type="SAY",
            preferred_cities='["İstanbul"]',
            preferred_university_types='["Devlet"]',
            scholarship_preference=True
        )
        
        department = Department(
            name="Test Department",
            field_type="SAY",
            university_id=1,
            has_scholarship=True
        )
        
        # Mock university
        university = University(
            name="Test University",
            city="İstanbul",
            university_type="Devlet"
        )
        
        self.mock_db.query.return_value.filter.return_value.first.return_value = university
        
        score = self.engine._calculate_preference_score(student, department)
        
        assert 0 <= score <= 100
        assert score > 50  # Tercihler uyduğu için skor yüksek olmalı
        
    def test_generate_recommendation_reason(self):
        """Öneri sebebi oluşturma testi"""
        student = Student(
            name="Test Student",
            class_level="12",
            exam_type="TYT+AYT",
            field_type="SAY",
            total_score=450.0
        )
        
        department = Department(
            name="Test Department",
            field_type="SAY",
            university_id=1,
            min_score=400.0
        )
        
        reason = self.engine._generate_recommendation_reason(
            student, department, 80.0, 85.0, 75.0
        )
        
        assert isinstance(reason, str)
        assert len(reason) > 0
        assert "Yüksek başarı olasılığı" in reason
        assert "Yüksek uyumluluk" in reason
        
    def test_generate_recommendations_empty_departments(self):
        """Boş bölüm listesi için test"""
        student = Student(
            name="Test Student",
            class_level="12",
            exam_type="TYT+AYT",
            field_type="SAY"
        )
        
        # Mock empty departments
        self.mock_db.query.return_value.filter.return_value.all.return_value = []
        
        recommendations = self.engine.generate_recommendations(1)
        
        assert isinstance(recommendations, list)
        assert len(recommendations) == 0
        
    def test_generate_recommendations_student_not_found(self):
        """Öğrenci bulunamadığında test"""
        # Mock student not found
        self.mock_db.query.return_value.filter.return_value.first.return_value = None
        
        with pytest.raises(Exception):  # StudentNotFoundError
            self.engine.generate_recommendations(999)
