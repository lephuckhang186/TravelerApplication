import os
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate

load_dotenv()

def get_llm() -> ChatGoogleGenerativeAI:
  """
  Returns a configured ChatGoogleGenerativeAI instance using environment variables.

  Returns:
      ChatGoogleGenerativeAI: An instance of the Gemini chat model configured with the API key and model name.
  """
  return ChatGoogleGenerativeAI(
    model=os.getenv("LLM_MODEL", "gemini-2.5-flash"),
    temperature=0,
    google_api_key=os.getenv("GOOGLE_API_KEY"),
  )

def get_default_prompt(system_message: str, human_message: str) -> ChatPromptTemplate:
  """
  Returns a ChatPromptTemplate with the given system and human messages.

  Args:
      system_message (str): The system instruction (persona/role).
      human_message (str): The user input template.

  Returns:
      ChatPromptTemplate: A configured chat prompt template.
  """
  return ChatPromptTemplate.from_messages([
    ("system", system_message),
    ("human", human_message)
  ]) 

def make_system_prompt(instruction:str)->str:
    """
    Creates a standard system prompt for multi-agent collaboration instructions.

    Args:
        instruction (str): Specific instructions for the agent.

    Returns:
        str: A complete system prompt string including collaboration protocols.
    """
    return  (
        "You are a helpful AI assistant, collaborating with other assistants."
        " Use the provided tools to progress towards answering the question."
        " If you are unable to fully answer, that's OK, another assistant with different tools "
        " will help where you left off. Execute what you can to make progress."
        " If you or any of the other assistants have the final answer or deliverable,"
        " prefix your response with FINAL ANSWER so the team knows when to stop."
        f"\n{instruction}"
    )