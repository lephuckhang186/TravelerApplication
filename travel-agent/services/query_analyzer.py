from models import QueryAnalysisResult
from services.llm_utils import get_llm, get_default_prompt
import os

class QueryAnalyzer:
  def __init__(self):
    self.llm = get_llm()
    system_prompt = (
      "You are an expert travel planning assistant. Your task is to analyze the user's request "
      "and extract the required information for planning a trip. "
      "Identify the user's destination, budget, native currency, travel duration in days, and any specific activities they mention. "
      "Based on the provided information, you must also determine which of the essential fields "
      "(destination, budget, native_currency, days) are missing from the user's query. "
      "For budget and days, if a user provides a range, take the maximum value. "
      "If the currency is not specified, assume USD but still list 'native_currency' as a missing field for the user to confirm."
      "If the user's query is not travel-related, return an empty QueryAnalysisResult."
    )
    human_prompt = "{user_query}"
    self.prompt = get_default_prompt(system_prompt, human_prompt)
    self.structured_llm = self.llm.with_structured_output(QueryAnalysisResult)

  def analyze(self, user_query: str) -> QueryAnalysisResult:
    """Uses an LLM to extract trip details and identify missing fields."""
    chain = self.prompt | self.structured_llm
    return chain.invoke({"user_query": user_query}) 