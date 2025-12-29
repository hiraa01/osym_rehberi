from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional

from database import get_db
from models import ForumPost, ForumComment, Student
from schemas.forum import (
    ForumPostCreate, ForumPostResponse, ForumPostDetailResponse,
    ForumCommentCreate, ForumCommentResponse, ForumPostListResponse
)
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


@router.get("/posts", response_model=ForumPostListResponse)
async def get_forum_posts(
    page: int = Query(1, ge=1, description="Sayfa numarası"),
    size: int = Query(20, ge=1, le=100, description="Sayfa başına kayıt sayısı"),
    category: Optional[str] = Query(None, description="Kategori filtresi: TYT, AYT, Rehberlik"),
    db: Session = Depends(get_db)
):
    """
    Tüm forum gönderilerini listele (Sayfalama ile)
    
    Parametreler:
    - page: Sayfa numarası (varsayılan: 1)
    - size: Sayfa başına kayıt sayısı (varsayılan: 20, maksimum: 100)
    - category: Kategori filtresi (opsiyonel)
    """
    try:
        # Base query
        query = db.query(ForumPost)
        
        # Kategori filtresi
        if category:
            query = query.filter(ForumPost.category == category)
        
        # Toplam sayı
        total = query.count()
        
        # Sayfalama
        skip = (page - 1) * size
        posts = query.order_by(desc(ForumPost.created_at)).offset(skip).limit(size).all()
        
        # Yorum sayılarını hesapla
        result_posts = []
        for post in posts:
            comment_count = db.query(func.count(ForumComment.id)).filter(
                ForumComment.post_id == post.id
            ).scalar()
            
            result_posts.append(ForumPostResponse(
                id=post.id,
                student_id=post.student_id,
                title=post.title,
                content=post.content,
                category=post.category,
                created_at=post.created_at,
                updated_at=post.updated_at,
                comment_count=comment_count or 0
            ))
        
        api_logger.info(f"Retrieved {len(result_posts)} forum posts (page={page}, size={size})")
        
        return ForumPostListResponse(
            posts=result_posts,
            total=total,
            page=page,
            size=size
        )
        
    except Exception as e:
        api_logger.error(f"Error getting forum posts: {str(e)}", error=str(e))
        raise HTTPException(status_code=500, detail=f"Gönderiler getirilemedi: {str(e)}")


@router.post("/posts", response_model=ForumPostResponse)
async def create_forum_post(
    post: ForumPostCreate,
    db: Session = Depends(get_db)
):
    """Yeni forum gönderisi oluştur (soru sor)"""
    try:
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == post.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {post.student_id}")
        
        # Yeni gönderi oluştur
        db_post = ForumPost(
            student_id=post.student_id,
            title=post.title,
            content=post.content,
            category=post.category
        )
        db.add(db_post)
        db.commit()
        db.refresh(db_post)
        
        api_logger.info(
            f"Forum post created: id={db_post.id}, student_id={post.student_id}",
            user_id=post.student_id
        )
        
        return ForumPostResponse(
            id=db_post.id,
            student_id=db_post.student_id,
            title=db_post.title,
            content=db_post.content,
            category=db_post.category,
            created_at=db_post.created_at,
            updated_at=db_post.updated_at,
            comment_count=0
        )
        
    except StudentNotFoundError:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error creating forum post: {str(e)}", error=str(e), user_id=post.student_id)
        raise HTTPException(status_code=500, detail=f"Gönderi oluşturulamadı: {str(e)}")


@router.get("/posts/{post_id}", response_model=ForumPostDetailResponse)
async def get_forum_post_detail(
    post_id: int,
    db: Session = Depends(get_db)
):
    """Forum gönderisi detayını ve yorumlarını getir"""
    try:
        post = db.query(ForumPost).filter(ForumPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Gönderi bulunamadı")
        
        # Yorumları getir
        comments = db.query(ForumComment).filter(
            ForumComment.post_id == post_id
        ).order_by(ForumComment.created_at.asc()).all()
        
        comment_responses = [
            ForumCommentResponse(
                id=comment.id,
                post_id=comment.post_id,
                student_id=comment.student_id,
                content=comment.content,
                created_at=comment.created_at,
                updated_at=comment.updated_at
            )
            for comment in comments
        ]
        
        return ForumPostDetailResponse(
            id=post.id,
            student_id=post.student_id,
            title=post.title,
            content=post.content,
            category=post.category,
            created_at=post.created_at,
            updated_at=post.updated_at,
            comment_count=len(comment_responses),
            comments=comment_responses
        )
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error getting forum post detail: {str(e)}", error=str(e))
        raise HTTPException(status_code=500, detail=f"Gönderi detayı getirilemedi: {str(e)}")


@router.post("/posts/{post_id}/comments", response_model=ForumCommentResponse)
async def create_forum_comment(
    post_id: int,
    comment: ForumCommentCreate,
    db: Session = Depends(get_db)
):
    """Forum gönderisine yorum yap"""
    try:
        # Gönderi kontrolü
        post = db.query(ForumPost).filter(ForumPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Gönderi bulunamadı")
        
        # post_id'yi comment'ten al, ama URL'deki ile eşleşmeli
        if comment.post_id != post_id:
            raise HTTPException(status_code=400, detail="Gönderi ID'leri eşleşmiyor")
        
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == comment.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {comment.student_id}")
        
        # Yeni yorum oluştur
        db_comment = ForumComment(
            post_id=comment.post_id,
            student_id=comment.student_id,
            content=comment.content
        )
        db.add(db_comment)
        db.commit()
        db.refresh(db_comment)
        
        api_logger.info(
            f"Forum comment created: id={db_comment.id}, post_id={post_id}, student_id={comment.student_id}",
            user_id=comment.student_id
        )
        
        return ForumCommentResponse(
            id=db_comment.id,
            post_id=db_comment.post_id,
            student_id=db_comment.student_id,
            content=db_comment.content,
            created_at=db_comment.created_at,
            updated_at=db_comment.updated_at
        )
        
    except (HTTPException, StudentNotFoundError):
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error creating forum comment: {str(e)}", error=str(e), user_id=comment.student_id)
        raise HTTPException(status_code=500, detail=f"Yorum oluşturulamadı: {str(e)}")

