import os
from .llm_utils import get_llm, get_default_prompt
from typing import Any

class ItineraryBuilder:
    """
    Builds a day-by-day itinerary for a trip using an LLM, using the full workflow state.
    """
    def __init__(self):
        self.llm = get_llm()
        system_prompt = (
            "You are a travel assistant. Given the full state of a trip planning workflow, generate a detailed, day-by-day itinerary. "
            "Use all available information: destination, number of days, budget, hotels, attractions, weather, group size, preferences, etc. "
            "If there are too many attractions or activities to fit in the trip, intelligently drop or prioritize them and mention this in your output. "
            "If any required info is missing, do NOT raise an error. Instead, either use the search tool to find the missing info, or return a message indicating which agent (e.g., hotel, attractions, weather, etc.) should be called to provide the missing info. "
            "IMPORTANT: Format your response as plain text without markdown syntax (no *, #, **, ###). "
            "Instead, use relevant emojis and icons to make the itinerary visually appealing and easy to read. "
            "Use emojis like 🌅 for morning, 🌞 for afternoon, 🌙 for evening, 🍽️ for meals, "
            "🏛️ for museums, 🏖️ for beaches, 🚶 for walking, 🚗 for transportation, "
            "📍 for locations, ⏰ for time, 💡 for tips, etc. Structure each day clearly with natural formatting."
        )
        human_prompt = """
Trip State:
{state}
"""
        self.prompt = get_default_prompt(system_prompt, human_prompt)

    def build(self, state: Any) -> dict:
        """
        Generates a detailed, day-by-day itinerary using an LLM, given the full workflow state.

        Args:
            state: The full workflow state (should be serializable as a dict).

        Returns:
            dict: Dictionary with the generated itinerary.
        """
        chain = self.prompt | self.llm
        result = chain.invoke({"state": state})
        return {"itinerary": result.content} 