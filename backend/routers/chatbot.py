from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field

from database import get_db
from core.logging_config import api_logger

router = APIRouter()


class ChatMessageRequest(BaseModel):
    """Chatbot mesaj isteği"""
    student_id: int
    message: str = Field(..., min_length=1, max_length=2000)


class ChatMessageResponse(BaseModel):
    """Chatbot mesaj yanıtı"""
    reply: str
    intent: str  # "calculate", "recommendation", "general"


@router.post("/message", response_model=ChatMessageResponse)
async def send_chat_message(
    request: ChatMessageRequest,
    db: Session = Depends(get_db)
):
    """
    Kullanıcı mesajını al, basit AI logic ile cevap dön
    
    Logic:
    - Mesaj "hesapla" içeriyorsa -> Puan hesaplama mesajı dön
    - Mesaj "öneri" içeriyorsa -> Keşfet sayfası yönlendirmesi dön
    - Diğer durumlar için -> Genel yardım mesajı dön
    """
    try:
        message_lower = request.message.lower().strip()
        
        # Intent belirleme
        if any(keyword in message_lower for keyword in ["hesapla", "puan", "net", "skor", "score"]):
            intent = "calculate"
            reply = (
                "Senin için TYT/AYT puanını hesaplayabilirim. "
                "Lütfen netlerini yazar mısın? Örneğin: "
                "'TYT Türkçe 30, TYT Matematik 25, TYT Sosyal 15, TYT Fen 20' şeklinde yazabilirsin."
            )
        elif any(keyword in message_lower for keyword in ["öneri", "öner", "tavsiye", "keşfet", "bul"]):
            intent = "recommendation"
            reply = (
                "Sana uygun bölümleri 'Keşfet' sayfasında listeledim. "
                "Orada şehir, alan türü ve puan aralığına göre filtreleme yapabilirsin. "
                "Beğendiğin bölümleri 'Tercihlerim' sayfasına ekleyebilirsin."
            )
        else:
            intent = "general"
            reply = (
                "Şu an öğrenme aşamasındayım, ama sana tercih döneminde yardımcı olabilirim. "
                "Şunları yapabilirim:\n"
                "• Puan hesaplama (TYT/AYT netlerinden)\n"
                "• Bölüm önerileri (Keşfet sayfası)\n"
                "• Tercih listesi yönetimi\n\n"
                "Nasıl yardımcı olabilirim?"
            )
        
        api_logger.info(
            f"Chatbot message processed: student_id={request.student_id}, intent={intent}",
            user_id=request.student_id
        )
        
        return ChatMessageResponse(reply=reply, intent=intent)
        
    except Exception as e:
        api_logger.error(
            f"Error processing chat message: {str(e)}",
            error=str(e),
            user_id=request.student_id
        )
        raise HTTPException(status_code=500, detail=f"Mesaj işlenemedi: {str(e)}")

