"""
Makine öğrenmesi destekli öneri motoru
Bu modül, geçmiş verilerle eğitilmiş modeller kullanarak daha akıllı öneriler sunar
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from typing import List, Dict, Any, Tuple, Optional
import joblib
import os
from sqlalchemy.orm import Session
from models.student import Student
from models.university import Department, Recommendation, University
from core.logging_config import recommendation_logger

class MLRecommendationEngine:
    """Makine öğrenmesi destekli öneri motoru"""
    
    def __init__(self, db: Session):
        self.db = db
        self.models = {}
        self.scalers = {}
        self.is_trained = False
        self.model_path = "models/"
        
        # Model dosyalarını yükle
        self._load_models()
    
    def train_models(self, training_data: List[Dict[str, Any]]):
        """Modelleri eğit"""
        try:
            recommendation_logger.info("Starting ML model training", data_size=len(training_data))
            
            # Veriyi DataFrame'e çevir
            df = pd.DataFrame(training_data)
            
            # Özellik mühendisliği
            X, y = self._prepare_features(df)
            
            # Modelleri eğit
            self._train_compatibility_model(X, y['compatibility'])
            self._train_success_model(X, y['success_probability'])
            self._train_preference_model(X, y['preference'])
            
            # Modelleri kaydet
            self._save_models()
            
            self.is_trained = True
            recommendation_logger.info("ML models trained successfully")
            
        except Exception as e:
            recommendation_logger.error("ML training failed", error=str(e))
            raise
    
    def generate_recommendations(
        self,
        student_id: int,
        limit: int = 50,
        weights: Tuple[float, float, float] | None = None
    ) -> List[Dict[str, Any]]:
        """ML destekli öneriler oluştur"""
        if not self.is_trained:
            recommendation_logger.warning("Models not trained, falling back to rule-based")
            return self._fallback_recommendations(student_id, limit)
        
        try:
            student = self.db.query(Student).filter(Student.id == student_id).first()
            if not student:
                raise ValueError(f"Student {student_id} not found")
            
            # Öğrenci özelliklerini hazırla
            student_features = self._prepare_student_features(student)
            
            # Bölümleri getir
            departments = self.db.query(Department).filter(
                Department.field_type == student.field_type
            ).all()
            
            # Ağırlıklar (compatibility, success, preference)
            if not weights:
                weights = (0.4, 0.4, 0.2)
            w_c, w_s, w_p = weights
            total_w = max(1e-9, (w_c + w_s + w_p))
            w_c, w_s, w_p = w_c / total_w, w_s / total_w, w_p / total_w

            recommendations = []
            
            for department in departments:
                # Bölüm özelliklerini hazırla
                dept_features = self._prepare_department_features(department)
                
                # Özellikleri birleştir
                combined_features = np.concatenate([student_features, dept_features])
                combined_features = combined_features.reshape(1, -1)
                
                # Skorları tahmin et
                compatibility = self._predict_compatibility(combined_features)
                success_prob = self._predict_success_probability(combined_features)
                preference = self._predict_preference(combined_features)
                
                # Final skor
                final_score = (compatibility * w_c + success_prob * w_s + preference * w_p)
                
                # Öneri türünü belirle
                is_safe = success_prob >= 0.8
                is_dream = success_prob <= 0.3
                is_realistic = 0.3 < success_prob < 0.8
                
                # Öneri sebebi
                reason = self._generate_ml_reason(compatibility, success_prob, preference)
                
                recommendations.append({
                    'student_id': student_id,
                    'department_id': department.id,
                    'compatibility_score': float(compatibility),
                    'success_probability': float(success_prob),
                    'preference_score': float(preference),
                    'final_score': float(final_score),
                    'recommendation_reason': reason,
                    'is_safe_choice': is_safe,
                    'is_dream_choice': is_dream,
                    'is_realistic_choice': is_realistic,
                    'department': department,
                })
            
            # Skora göre sırala
            recommendations.sort(key=lambda x: x['final_score'], reverse=True)
            
            return recommendations[:limit]
            
        except Exception as e:
            recommendation_logger.error("ML recommendation failed", error=str(e))
            return self._fallback_recommendations(student_id, limit)
    
    def _prepare_features(self, df: pd.DataFrame) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
        """Eğitim verilerini hazırla"""
        # Öğrenci özellikleri
        student_features = [
            'total_score', 'rank', 'percentile', 'tyt_total_score', 'ayt_total_score',
            'field_type_encoded', 'exam_type_encoded', 'class_level_encoded'
        ]
        
        # Bölüm özellikleri
        dept_features = [
            'min_score', 'min_rank', 'quota', 'tuition_fee', 'has_scholarship',
            'university_type_encoded', 'city_encoded'
        ]
        
        # Hedef değişkenler
        targets = ['compatibility', 'success_probability', 'preference']
        
        X = df[student_features + dept_features].values
        y = {target: df[target].values for target in targets}
        
        return X, y
    
    def _prepare_student_features(self, student: Student) -> np.ndarray:
        """Öğrenci özelliklerini hazırla"""
        features = [
            student.total_score or 0,
            student.rank or 0,
            student.percentile or 0,
            student.tyt_total_score or 0,
            student.ayt_total_score or 0,
            self._encode_field_type(student.field_type),
            self._encode_exam_type(student.exam_type),
            self._encode_class_level(student.class_level),
        ]
        return np.array(features)
    
    def _prepare_department_features(self, department: Department) -> np.ndarray:
        """Bölüm özelliklerini hazırla (Üniversite bilgilerini ilişki üzerinden getirir)."""
        # University bilgilerini yükle
        university: Optional[University] = self.db.query(University).filter(University.id == department.university_id).first()
        university_type = (university.university_type if university and getattr(university, 'university_type', None) else 'Devlet')
        university_city = (university.city if university and getattr(university, 'city', None) else '')

        features = [
            float(department.min_score or 0.0),
            float(department.min_rank or 0.0),
            float(department.quota or 0.0),
            float(department.tuition_fee or 0.0),
            1 if bool(department.has_scholarship) else 0,
            self._encode_university_type(university_type),
            self._encode_city(university_city),
        ]
        return np.array(features)
    
    def _train_compatibility_model(self, X: np.ndarray, y: np.ndarray):
        """Uyumluluk modelini eğit"""
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Özellikleri ölçeklendir
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Modeli eğit
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train_scaled, y_train)
        
        # Modeli kaydet
        self.models['compatibility'] = model
        self.scalers['compatibility'] = scaler
        
        # Performansı logla
        score = model.score(X_test_scaled, y_test)
        recommendation_logger.info("Compatibility model trained", score=score)
    
    def _train_success_model(self, X: np.ndarray, y: np.ndarray):
        """Başarı olasılığı modelini eğit"""
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train_scaled, y_train)
        
        self.models['success'] = model
        self.scalers['success'] = scaler
        
        score = model.score(X_test_scaled, y_test)
        recommendation_logger.info("Success model trained", score=score)
    
    def _train_preference_model(self, X: np.ndarray, y: np.ndarray):
        """Tercih modelini eğit"""
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train_scaled, y_train)
        
        self.models['preference'] = model
        self.scalers['preference'] = scaler
        
        score = model.score(X_test_scaled, y_test)
        recommendation_logger.info("Preference model trained", score=score)
    
    def _predict_compatibility(self, features: np.ndarray) -> float:
        """Uyumluluk skorunu tahmin et"""
        if 'compatibility' not in self.models:
            return 0.5  # Default value
        
        features_scaled = self.scalers['compatibility'].transform(features)
        return self.models['compatibility'].predict(features_scaled)[0]
    
    def _predict_success_probability(self, features: np.ndarray) -> float:
        """Başarı olasılığını tahmin et"""
        if 'success' not in self.models:
            return 0.5
        
        features_scaled = self.scalers['success'].transform(features)
        return self.models['success'].predict(features_scaled)[0]
    
    def _predict_preference(self, features: np.ndarray) -> float:
        """Tercih skorunu tahmin et"""
        if 'preference' not in self.models:
            return 0.5
        
        features_scaled = self.scalers['preference'].transform(features)
        return self.models['preference'].predict(features_scaled)[0]
    
    def _generate_ml_reason(self, compatibility: float, success: float, preference: float) -> str:
        """ML destekli öneri sebebi oluştur"""
        reasons = []
        
        if success >= 0.8:
            reasons.append("Yüksek başarı olasılığı (ML tahmini)")
        elif success >= 0.6:
            reasons.append("Orta başarı olasılığı (ML tahmini)")
        else:
            reasons.append("Düşük başarı olasılığı (ML tahmini)")
        
        if compatibility >= 0.8:
            reasons.append("Yüksek uyumluluk (ML tahmini)")
        elif compatibility >= 0.6:
            reasons.append("Orta uyumluluk (ML tahmini)")
        
        if preference >= 0.8:
            reasons.append("Tercihlerinize uygun (ML tahmini)")
        elif preference >= 0.6:
            reasons.append("Kısmen tercihlerinize uygun (ML tahmini)")
        
        return ", ".join(reasons) if reasons else "ML destekli genel uyumluluk"
    
    def _fallback_recommendations(self, student_id: int, limit: int) -> List[Dict[str, Any]]:
        """ML modelleri yoksa kural tabanlı sisteme geri dön"""
        from services.recommendation_engine import RecommendationEngine
        rule_engine = RecommendationEngine(self.db)
        return rule_engine.generate_recommendations(student_id, limit)
    
    def _save_models(self):
        """Modelleri kaydet"""
        os.makedirs(self.model_path, exist_ok=True)
        
        for name, model in self.models.items():
            joblib.dump(model, f"{self.model_path}{name}_model.pkl")
        
        for name, scaler in self.scalers.items():
            joblib.dump(scaler, f"{self.model_path}{name}_scaler.pkl")
    
    def _load_models(self):
        """Modelleri yükle"""
        try:
            for name in ['compatibility', 'success', 'preference']:
                model_path = f"{self.model_path}{name}_model.pkl"
                scaler_path = f"{self.model_path}{name}_scaler.pkl"
                
                if os.path.exists(model_path) and os.path.exists(scaler_path):
                    self.models[name] = joblib.load(model_path)
                    self.scalers[name] = joblib.load(scaler_path)
                    self.is_trained = True
            
            if self.is_trained:
                recommendation_logger.info("ML models loaded successfully")
        except Exception as e:
            recommendation_logger.warning("Failed to load ML models", error=str(e))
    
    def _encode_field_type(self, field_type: str) -> int:
        """Alan türünü encode et"""
        mapping = {'SAY': 0, 'EA': 1, 'SÖZ': 2, 'DİL': 3}
        return mapping.get(field_type, 0)
    
    def _encode_exam_type(self, exam_type: str) -> int:
        """Sınav türünü encode et"""
        mapping = {'TYT': 0, 'AYT': 1, 'TYT+AYT': 2}
        return mapping.get(exam_type, 2)
    
    def _encode_class_level(self, class_level: str) -> int:
        """Sınıf seviyesini encode et"""
        mapping = {'12': 0, 'mezun': 1}
        return mapping.get(class_level, 0)
    
    def _encode_university_type(self, uni_type: str) -> int:
        """Üniversite türünü encode et"""
        mapping = {'Devlet': 0, 'Vakıf': 1, 'Özel': 2}
        return mapping.get(uni_type, 0)
    
    def _encode_city(self, city: str) -> int:
        """Şehri encode et"""
        # Basit hash fonksiyonu
        return hash(city) % 1000
