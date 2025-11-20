import os
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate

load_dotenv()

def get_llm() -> ChatGoogleGenerativeAI:
  """
  Returns a configured ChatGoogleGenerativeAI instance using environment variables.
  """
  return ChatGoogleGenerativeAI(
    model=os.getenv("LLM_MODEL", "gemini-2.5-flash"),
    temperature=0,
    google_api_key=os.getenv("GOOGLE_API_KEY"),
  )

def get_default_prompt(system_message: str, human_message: str) -> ChatPromptTemplate:
  """
  Returns a ChatPromptTemplate with the given system and human messages.
  """
  return ChatPromptTemplate.from_messages([
    ("system", system_message),
    ("human", human_message)
  ]) 

def make_system_prompt(instruction:str)->str:
    return  (
        "You are a helpful AI assistant, collaborating with other assistants."
        " Use the provided tools to progress towards answering the question."
        " If you are unable to fully answer, that's OK, another assistant with different tools "
        " will help where you left off. Execute what you can to make progress."
        " If you or any of the other assistants have the final answer or deliverable,"
        " prefix your response with FINAL ANSWER so the team knows when to stop."
        f"\n{instruction}"
    )