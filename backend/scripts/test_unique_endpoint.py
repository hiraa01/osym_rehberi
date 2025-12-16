"""Test script for unique departments endpoint"""
import sys
sys.path.append('/app')

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

print("=" * 70)
print("TEST: Unique Departments Endpoint")
print("=" * 70)

# Test 1: Vakıf üniversiteleri
print("\n1. Vakıf üniversiteleri için unique bölümler:")
response = client.get('/api/universities/departments/unique/', params={'university_type': 'vakif'})
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   Toplam unique bölüm: {len(data)}")
    print("\n   İlk 5 örnek:")
    for dept in data[:5]:
        print(f"     - {dept['normalized_name']} ({dept['variation_count']} varyasyon)")

# Test 2: Devlet üniversiteleri
print("\n2. Devlet üniversiteleri için unique bölümler:")
response = client.get('/api/universities/departments/unique/', params={'university_type': 'devlet'})
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   Toplam unique bölüm: {len(data)}")

# Test 3: Normalize edilmiş isme göre filtreleme
print("\n3. 'Psikoloji' bölümünün varyasyonları (Vakıf):")
response = client.get('/api/universities/departments/', params={
    'normalized_name': 'Psikoloji',
    'university_type': 'vakif',
    'limit': 5
})
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   Toplam varyasyon: {len(data)}")
    print("\n   İlk 3 örnek:")
    for dept in data[:3]:
        attrs = dept.get('attributes', [])
        print(f"     - {dept['name']} (Attributes: {attrs})")

print("\n" + "=" * 70)
print("✅ Test tamamlandı!")
print("=" * 70)

