import os
from langchain.tools import tool
from services.llm_utils import get_llm, get_default_prompt
from typing import Dict, Any


class TripSummary:
  """
  A tool to generate a final summary of a trip plan using an LLM.
  """

  def __init__(self):
    self.llm = get_llm()
    system_prompt = (
      "You are a travel expert. Based on the detailed trip plan provided, "
      "generate a friendly and comprehensive summary for the user. "
      "Include key details like destination, duration, budget, weather overview, "
      "and highlights from the itinerary. The goal is to present a final, polished "
      "plan that is exciting and easy to read. "
      "IMPORTANT: Format your response as plain text without markdown syntax (no *, #, **, ###). "
      "Instead, use relevant emojis and icons to make the content visually appealing. "
      "Use emojis like 🏨 for hotels, 🍕 for food, 🌤️ for weather, 💰 for budget, "
      "📍 for locations, ✈️ for travel, 🎯 for activities, etc. "
      "Structure with clear sections using natural formatting and line breaks."
    )
    human_prompt = "Here is the complete trip plan to summarize:\n\n{trip_plan}"
    self.prompt = get_default_prompt(system_prompt, human_prompt)

  def generate_summary(self, trip_plan: dict) -> dict:
    """
    Generates a summary of the trip plan using an LLM.

    Args:
      trip_plan (dict): The complete trip plan information.

    Returns:
      dict: Dictionary with a summary string.
    """
    if not trip_plan:
      raise ValueError("A complete trip plan must be provided to generate a summary.")
    chain = self.prompt | self.llm
    result = chain.invoke({"trip_plan": trip_plan})
    return {"summary": result.content} 