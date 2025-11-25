"""
Travel Agent API endpoints for AI-powered trip planning
"""
import logging
from typing import Any, Dict, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import subprocess
import json
import os

# Set up logging
logger = logging.getLogger(__name__)

# Request/Response models
class TravelAgentRequest(BaseModel):
    """Request model for travel agent queries"""
    input: str = Field(..., description="The travel planning query")
    history: List[Dict[str, str]] = Field(default=[], description="Conversation history")

class TravelAgentResponse(BaseModel):
    """Response model for travel agent results"""
    summary: str = Field(..., description="Travel plan summary")
    status: str = Field(default="success", description="Response status")

# Create router
router = APIRouter(prefix="/travel-agent", tags=["Travel Agent"])

def call_travel_agent_service(input_text: str, history: List[Dict[str, str]] = None) -> dict:
    """
    Process travel agent request with real user data
    """
    try:
        # Validate input
        if not input_text or not input_text.strip():
            return {"summary": "Please provide a travel query", "status": "error"}
        
        # Process the actual user request
        # TODO: Integrate with AI travel planning workflow here
        
        # For now, acknowledge receipt of real user data
        return {
            "summary": f"Processing your travel request: {input_text.strip()}",
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Error processing travel request: {e}")
        return {
            "summary": "Error processing travel request. Please try again.",
            "status": "error"
        }

@router.post("/invoke", response_model=TravelAgentResponse)
async def invoke_travel_agent(request: TravelAgentRequest) -> TravelAgentResponse:
    """
    Invoke the AI travel agent with user input and conversation history
    """
    try:
        logger.info(f"Processing travel query: {request.input}")
        
        # Call the travel agent service
        result = call_travel_agent_service(request.input, request.history)
        
        return TravelAgentResponse(
            summary=result["summary"],
            status=result["status"]
        )
        
    except Exception as e:
        logger.error(f"Error in travel planning: {str(e)}")
        return TravelAgentResponse(
            summary="Sorry, there was an error processing your request.",
            status="error"
        )

@router.get("/health")
async def health_check():
    """
    Health check for travel agent service
    """
    return {
        "status": "healthy",
        "service": "travel-agent",
        "message": "Travel agent service is ready to process real user requests"
    }

# Export router
__all__ = ["router"]