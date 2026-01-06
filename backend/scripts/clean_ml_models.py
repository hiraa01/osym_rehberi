#!/usr/bin/env python3
"""
Eski ML model dosyalarını temizle
XGBoost'a geçiş için eski GradientBoosting modellerini sil
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import glob

def clean_old_models():
    """Eski model dosyalarını sil"""
    print("🧹 Eski ML model dosyaları temizleniyor...")
    
    # Model dosyalarının bulunabileceği yerler
    model_paths = [
        "models/",  # Local development
        "ml_models/",  # Docker volume (local)
        "/app/models/",  # Docker container içi
        "/app/ml_models/",  # Docker container içi (Docker volume)
    ]
    
    # Mevcut dizini kontrol et
    current_dir = os.getcwd()
    if "backend" in current_dir:
        model_paths.append(os.path.join(current_dir, "models/"))
        model_paths.append(os.path.join(current_dir, "ml_models/"))
    
    model_files = [
        "compatibility_model.pkl",
        "compatibility_scaler.pkl",
        "success_model.pkl",
        "success_scaler.pkl",
        "preference_model.pkl",
        "preference_scaler.pkl",
    ]
    
    deleted_count = 0
    
    for model_path in model_paths:
        if not os.path.exists(model_path):
            continue
            
        for model_file in model_files:
            file_path = os.path.join(model_path, model_file)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                    print(f"  ✅ Silindi: {file_path}")
                    deleted_count += 1
                except Exception as e:
                    print(f"  ⚠️  Silinemedi: {file_path} - {e}")
    
    # Wildcard ile de kontrol et
    for pattern in ["**/*_model.pkl", "**/*_scaler.pkl"]:
        for file_path in glob.glob(pattern, recursive=True):
            try:
                os.remove(file_path)
                print(f"  ✅ Silindi: {file_path}")
                deleted_count += 1
            except Exception as e:
                print(f"  ⚠️  Silinemedi: {file_path} - {e}")
    
    if deleted_count == 0:
        print("  ℹ️  Silinecek model dosyası bulunamadı (zaten temiz)")
    else:
        print(f"\n✅ Toplam {deleted_count} dosya silindi")
        print("🔄 Artık yeni XGBoost modellerini eğitebilirsiniz!")

if __name__ == "__main__":
    clean_old_models()

