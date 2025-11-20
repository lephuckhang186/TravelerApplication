from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict
from workflow import app
from models import WorkflowState
from langchain_core.messages import HumanMessage, AIMessage
import uvicorn
from fastapi.middleware.cors import CORSMiddleware

# Create the FastAPI app
api = FastAPI()

# Add CORS middleware
api.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Define the request body model
class InvokeRequest(BaseModel):
    input: str
    history: List[Dict[str, str]] = []

# Define the API endpoint
@api.post("/invoke")
async def invoke_workflow(request: InvokeRequest):
    """
    Invokes the AI travel agent workflow with the user's input and history.
    """
    # Construct the message history from the request
    messages = []
    for item in request.history:
        if item.get('role') == 'user':
            messages.append(HumanMessage(content=item.get('content', '')))
        elif item.get('role') == 'assistant':
            messages.append(AIMessage(content=item.get('content', '')))
    
    # Add the new user input
    messages.append(HumanMessage(content=request.input))

    state = WorkflowState(
        destination=None,
        budget=None,
        native_currency=None,
        days=None,
        group_size=None,
        activity_preferences=None,
        accommodation_type=None,
        dietary_restrictions=None,
        transportation_preferences=None,
        messages=messages
    )
    
    # The result of app.invoke is a dictionary
    final_state = app.invoke(state)

    # Extract the summary from the final state
    summary_output = final_state.get('summary', {})
    summary_message = summary_output.get('summary', "Sorry, I couldn't generate a summary.")
    
    return {"summary": summary_message}

# Add a root endpoint for basic checks
@api.get("/")
def read_root():
    return {"message": "AI Travel Agent is running"}

# To run this API, use the command:
# uvicorn main:api --reload
if __name__ == "__main__":
    uvicorn.run(api, host="0.0.0.0", port=8000)
