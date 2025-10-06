import logging
import logging.handlers
import os
from datetime import datetime
from typing import Optional


class StructuredLogger:
    """Structured logging configuration for ÖSYM Rehberi"""
    
    def __init__(self, name: str, log_level: str = "INFO"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(getattr(logging, log_level.upper()))
        
        # Create logs directory if it doesn't exist
        os.makedirs("logs", exist_ok=True)
        
        # Clear existing handlers
        self.logger.handlers.clear()
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(
            '%(asctime)s — %(name)s — %(levelname)s — %(message)s'
        )
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        
        # File handler with rotation
        file_handler = logging.handlers.RotatingFileHandler(
            'logs/app.log',
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s — %(name)s — %(levelname)s — %(message)s'
        )
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)
        
        # Error file handler
        error_handler = logging.handlers.RotatingFileHandler(
            'logs/error.log',
            maxBytes=5*1024*1024,  # 5MB
            backupCount=3
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(file_formatter)
        self.logger.addHandler(error_handler)
    
    def info(self, message: str, user_id: Optional[int] = None, **kwargs):
        """Log info message with optional user context"""
        context = f"user_id={user_id}" if user_id else ""
        if kwargs:
            context += " " + " ".join([f"{k}={v}" for k, v in kwargs.items()])
        
        full_message = f"{message} — {context}" if context else message
        self.logger.info(full_message)
    
    def error(self, message: str, user_id: Optional[int] = None, **kwargs):
        """Log error message with optional user context"""
        context = f"user_id={user_id}" if user_id else ""
        if kwargs:
            context += " " + " ".join([f"{k}={v}" for k, v in kwargs.items()])
        
        full_message = f"{message} — {context}" if context else message
        self.logger.error(full_message)
    
    def warning(self, message: str, user_id: Optional[int] = None, **kwargs):
        """Log warning message with optional user context"""
        context = f"user_id={user_id}" if user_id else ""
        if kwargs:
            context += " " + " ".join([f"{k}={v}" for k, v in kwargs.items()])
        
        full_message = f"{message} — {context}" if context else message
        self.logger.warning(full_message)
    
    def debug(self, message: str, user_id: Optional[int] = None, **kwargs):
        """Log debug message with optional user context"""
        context = f"user_id={user_id}" if user_id else ""
        if kwargs:
            context += " " + " ".join([f"{k}={v}" for k, v in kwargs.items()])
        
        full_message = f"{message} — {context}" if context else message
        self.logger.debug(full_message)


# Module-specific loggers
def get_logger(module_name: str) -> StructuredLogger:
    """Get structured logger for specific module"""
    return StructuredLogger(module_name)


# Global loggers for different modules
api_logger = get_logger("api")
recommendation_logger = get_logger("api.recommendation")
auth_logger = get_logger("api.auth")
net_calc_logger = get_logger("api.net_calc")
