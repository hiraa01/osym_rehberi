from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Tuple
import os
import google.generativeai as genai

from database import get_db
from core.logging_config import api_logger
from models.student import Student
from services.recommendation_engine import RecommendationEngine
from services.ml_recommendation_engine import MLRecommendationEngine


class ChatRequest(BaseModel):
    student_id: int
    message: str = Field(..., min_length=1, max_length=4000)
    use_ml: bool = True
    limit: int = 20
    w_c: Optional[float] = 0.4
    w_s: Optional[float] = 0.4
    w_p: Optional[float] = 0.2
    target_department_id: Optional[int] = None


class ChatResponse(BaseModel):
    reply: str
    used_weights: Tuple[float, float, float]
    used_ml: bool


router = APIRouter()


def _normalize_weights(w_c: Optional[float], w_s: Optional[float], w_p: Optional[float]) -> Tuple[float, float, float]:
    wc = float(w_c or 0.0)
    ws = float(w_s or 0.0)
    wp = float(w_p or 0.0)
    total = wc + ws + wp
    if total <= 0:
        return (0.4, 0.4, 0.2)
    return (wc / total, ws / total, wp / total)


@router.post("/coach", response_model=ChatResponse)
async def coach_chat(payload: ChatRequest, db: Session = Depends(get_db)):
    try:
        api_logger.info("Coach chat requested", user_id=payload.student_id)

        # Öğrenciyi getir
        student = db.query(Student).filter(Student.id == payload.student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")

        weights = _normalize_weights(payload.w_c, payload.w_s, payload.w_p)

        # ✅ Önce mevcut önerileri kontrol et (cache'den)
        from models.university import Recommendation
        existing_recs = db.query(Recommendation).filter(
            Recommendation.student_id == payload.student_id
        ).order_by(Recommendation.final_score.desc()).limit(payload.limit).all()
        
        recs: List[Dict[str, Any]] = []
        
        # Eğer öneriler varsa, cache'den kullan; yoksa yeni oluştur
        if existing_recs and len(existing_recs) >= payload.limit:
            api_logger.info("Using cached recommendations for coach chat", user_id=payload.student_id)
            # Cache'den gelen önerileri dict formatına çevir
            for rec in existing_recs:
                rec_dict = {
                    'final_score': rec.final_score,
                    'compatibility_score': rec.compatibility_score,
                    'success_probability': rec.success_probability,
                    'preference_score': rec.preference_score,
                    'is_safe_choice': rec.is_safe_choice,
                    'is_dream_choice': rec.is_dream_choice,
                    'is_realistic_choice': rec.is_realistic_choice,
                    'department': rec.department if hasattr(rec, 'department') else None,
                }
                recs.append(rec_dict)
        else:
            # Önerileri hazırla (ML tercihiyle)
            if payload.use_ml:
                ml_engine = MLRecommendationEngine(db)
                recs = ml_engine.generate_recommendations(student_id=payload.student_id, limit=payload.limit, weights=weights)
            else:
                rule_engine = RecommendationEngine(db)
                rule_recs = rule_engine.generate_recommendations(student_id=payload.student_id, limit=payload.limit, weights=weights)
                # ✅ RecommendationResponse'ları Dict'e çevir
                recs = []
                for rec in rule_recs:
                    rec_dict = {
                        'final_score': rec.final_score,
                        'compatibility_score': rec.compatibility_score,
                        'success_probability': rec.success_probability,
                        'preference_score': rec.preference_score,
                        'is_safe_choice': rec.is_safe_choice,
                        'is_dream_choice': rec.is_dream_choice,
                        'is_realistic_choice': rec.is_realistic_choice,
                        'department': rec.department,
                    }
                    recs.append(rec_dict)

        # Özetlenmiş öneri metni hazırla ve kategorize et
        def summarize_recs(rlist: List[Any]) -> str:
            lines: List[str] = []
            for r in rlist[: payload.limit]:
                try:
                    if isinstance(r, dict):
                        d = r
                        dept_name = d['department'].name
                        uni_id = d['department'].university_id
                        lines.append(f"- {dept_name} (uni_id={uni_id}) | final={d['final_score']:.2f} comp={d['compatibility_score']:.2f} succ={d['success_probability']:.2f} pref={d['preference_score']:.2f}")
                    else:
                        dept_name = getattr(r.department, 'name', '') if hasattr(r, 'department') else ''
                        lines.append(f"- {dept_name} | final={r.final_score:.2f} comp={r.compatibility_score:.2f} succ={r.success_probability:.2f} pref={r.preference_score:.2f}")
                except Exception:
                    continue
            return "\n".join(lines)

        rec_text = summarize_recs(recs)

        # Kategorize edilmiş kısa özet
        def to_dict(r: Any) -> Dict[str, Any]:
            if isinstance(r, dict):
                return r
            return {
                'is_safe_choice': r.is_safe_choice,
                'is_realistic_choice': r.is_realistic_choice,
                'is_dream_choice': r.is_dream_choice,
                'final_score': r.final_score,
                'success_probability': r.success_probability,
                'department': getattr(r, 'department', None),
            }

        dlist = [to_dict(r) for r in recs]
        def topk(lst: List[Dict[str, Any]], k: int = 3) -> List[str]:
            out: List[str] = []
            for d in lst[:k]:
                dept = d.get('department')
                name = getattr(dept, 'name', '') if dept is not None else ''
                out.append(f"- {name} | final={float(d['final_score']):.2f} succ={float(d['success_probability']):.2f}")
            return out

        safe_list = [x for x in dlist if x.get('is_safe_choice')]
        realistic_list = [x for x in dlist if x.get('is_realistic_choice')]
        dream_list = [x for x in dlist if x.get('is_dream_choice')]

        categorized_text = (
            f"Güvenli (ilk 3):\n" + ("\n".join(topk(safe_list)) or "- yok") + "\n\n"
            f"Realistik (ilk 3):\n" + ("\n".join(topk(realistic_list)) or "- yok") + "\n\n"
            f"Hayal (ilk 3):\n" + ("\n".join(topk(dream_list)) or "- yok")
        )

        # Hedef yakınlığı (opsiyonel)
        proximity_text = ""
        if payload.target_department_id:
            try:
                from services.score_calculator import ScoreCalculator
                from models.university import Department
                dept = db.query(Department).filter(Department.id == payload.target_department_id).first()
                if dept:
                    t_tyt = 0.0
                    t_ayt = float(dept.min_score or 0.0)
                    prox = ScoreCalculator.calculate_goal_proximity(
                        student_tyt_score=float(student.tyt_total_score or 0.0),
                        student_ayt_score=float(student.ayt_total_score or 0.0),
                        target_tyt_score=t_tyt,
                        target_ayt_score=t_ayt,
                    )
                    proximity_text = (
                        f"Hedef yakınlık: overall={prox['overall_proximity']}% ayt_gap={prox['ayt_gap']} hazır_mı={'evet' if prox['is_ready'] else 'hayır'}\n\n"
                    )
            except Exception:
                proximity_text = ""

        # Gemini yapılandırması
        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key:
            raise HTTPException(status_code=500, detail="LLM API anahtarı tanımlı değil (GOOGLE_API_KEY)")
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-1.5-flash")

        # Persona ve sistem yönlendirmesi
        system_prompt = (
            "ROL: Türkiye'de YKS hazırlık koçusun. \n"
            "STIL: Empatik, net, motive edici; kısa paragraflar, gerektiğinde madde işaretleri kullan. \n"
            "VERI: Öğrenci ve öneri bağlamı aşağıda. Gizli/özel verileri ifşa etme. \n"
            "KAPSAM: Haftalık/aylık çalışma planları, ders dağılımı, kaynak önerileri, zaman yönetimi, sınav kaygısı yönetimi, \n"
            "deneme analizi ve sonuçlara göre aksiyonlar. Tıbbi/klinik iddialardan kaçın; destek telkinleri ver. \n"
            "ÇIKTI: 1) Kısa özet, 2) Adım adım plan, 3) Bu hafta görev listesi, 4) İsteğe bağlı motivasyon cümlesi. \n"
            "DIL: Türkçe yanıt ver."
        )

        student_context = (
            f"Öğrenci: id={student.id}, alan={student.field_type}, sınav_türü={student.exam_type}, "
            f"TYT={student.tyt_total_score}, AYT={student.ayt_total_score}, TOPLAM={student.total_score}, yüzdelik={student.percentile}."
        )

        weight_context = f"Ağırlıklar: uyumluluk={weights[0]:.2f}, başarı={weights[1]:.2f}, tercih={weights[2]:.2f}."

        user_message = payload.message.strip()

        prompt = (
            f"{system_prompt}\n\n"
            f"{student_context}\n{weight_context}\n"
            f"Öneriler (ilk {payload.limit}):\n{rec_text if rec_text else '- (öneri bulunamadı)'}\n\n"
            f"{categorized_text}\n\n"
            f"{proximity_text}"
            f"Kullanıcı mesajı: {user_message}\n"
            f"İstenilenler: 1) Kısa ama net yanıt, 2) Haftalık/aylık plan, 3) Psikolojik destek önerileri, 4) Somut aksiyonlar."
        )

        completion = model.generate_content(prompt)
        reply = completion.text or ""  # type: ignore

        return ChatResponse(reply=reply.strip(), used_weights=weights, used_ml=payload.use_ml)

    except HTTPException:
        raise
    except Exception as e:
        api_logger.error("Coach chat failed", error=str(e), user_id=payload.student_id)
        raise HTTPException(status_code=500, detail=f"Sohbet yanıtı üretilemedi: {str(e)}")


