from typing import List, Dict
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/travel-agent", tags=["travel-agent"])


class TravelAgentRequest(BaseModel):
    input: str
    chat_history: List[Dict[str, str]] = []


class TravelAgentResponse(BaseModel):
    summary: str
    status: str


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
async def invoke_travel_agent(request: TravelAgentRequest):
    """
    Invoke travel agent service with user input
    """
    try:
        logger.info(f"Processing travel query: {request.input}")
        
        # Call the travel agent service
        result = call_travel_agent_service(request.input, request.chat_history)
        
        return TravelAgentResponse(
            summary=result["summary"],
            status=result["status"]
        )
        
    except Exception as e:
        logger.error(f"Error in travel agent endpoint: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")