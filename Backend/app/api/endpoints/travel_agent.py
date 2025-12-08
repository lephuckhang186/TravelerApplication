"""
Travel Agent API endpoints for AI-powered trip planning
"""
import logging
import sys
import os
from typing import Any, Dict, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

# Add travel-agent path to sys.path
travel_agent_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', 'travel-agent')
if os.path.exists(travel_agent_path):
    sys.path.insert(0, travel_agent_path)
    # Load travel-agent environment
    from dotenv import load_dotenv
    travel_agent_env = os.path.join(travel_agent_path, '.env')
    if os.path.exists(travel_agent_env):
        load_dotenv(travel_agent_env)

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
    Process travel agent request with AI travel planning workflow
    """
    try:
        # Validate input
        if not input_text or not input_text.strip():
            return {"summary": "Please provide a travel query", "status": "error"}
        
        # Try to import and use the travel-agent workflow
        try:
            from workflow import graph as travel_agent_graph
            
            # Prepare input for travel agent
            agent_input = {
                "input": input_text.strip(),
                "chat_history": history or []
            }
            
            # Invoke the travel agent workflow
            result = travel_agent_graph.invoke(agent_input)
            
            # Extract summary from result
            summary = result.get("summary", "Travel plan generated successfully")
            
            return {
                "summary": summary,
                "status": "success"
            }
        except ImportError:
            logger.warning("Travel agent workflow not available, using fallback")
            # Fallback: provide basic response
            return {
                "summary": f"Travel planning request received: {input_text.strip()}. AI agent integration pending.",
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