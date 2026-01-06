#!/usr/bin/env python3
"""
Eski ML modellerini sil ve XGBoost ile yeniden eğit
Bu script XGBoost'a geçiş için kullanılır
"""

import sys
import os

# Script'in bulunduğu dizini path'e ekle
script_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(script_dir)
sys.path.insert(0, backend_dir)

# Import'ları script dizininden yap
os.chdir(script_dir)
from clean_ml_models import clean_old_models
os.chdir(backend_dir)
from scripts.train_ml_models import train_models

def reset_and_retrain():
    """Eski modelleri sil ve yeniden eğit"""
    print("=" * 60)
    print("🔄 ML Modelleri Sıfırlama ve Yeniden Eğitim")
    print("=" * 60)
    print()
    
    # 1. Eski modelleri temizle
    print("📋 Adım 1: Eski modelleri temizle")
    print("-" * 60)
    clean_old_models()
    print()
    
    # 2. Yeni modelleri eğit
    print("📋 Adım 2: XGBoost modellerini eğit")
    print("-" * 60)
    train_models()
    print()
    
    print("=" * 60)
    print("✅ İşlem tamamlandı! XGBoost modelleri hazır.")
    print("=" * 60)

if __name__ == "__main__":
    reset_and_retrain()

