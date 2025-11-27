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
      "You are a travel expert. Generate a concise trip summary that's easy to scan.\\n\\n"
      "STRUCTURE (use this exact order):\\n"
      "1. Trip Header: Destination and dates\\n"
      "2. Weather Overview: Brief 2-3 sentence summary of weather conditions\\n"
      "3. Budget Breakdown: Simple bullet list with main categories (accommodation, food, transport, attractions, misc)\\n"
      "4. Accommodation: 1-2 recommended hotels/stays with brief note\\n"
      "5. Key Highlights: Top 3-5 must-do activities/attractions\\n"
      "6. Important Notes: 2-3 practical tips (booking early, cash, clothing, etc.)\\n\\n"
      "FORMATTING RULES:\\n"
      "- NO markdown syntax (no *, **, ###, ####, -, bullets)\\n"
      "- Use emojis to create visual sections: 🌤️ 💰 🏨 🎯 ⚠️\\n"
      "- Use line breaks and spacing for readability\\n"
      "- Keep total length under 500 words\\n"
      "- Write in Vietnamese if the input is in Vietnamese\\n"
      "- Use natural language: 'Chỗ ở: 1.700.000 VND' instead of bullet points\\n\\n"
      "EXAMPLE FORMAT:\\n"
      "🗺️ CHUYẾN ĐI HÀ NỘI\\n"
      "25 - 27 Tháng 11, 2025 | 3 ngày 2 đêm | 3 người\\n\\n"
      "🌤️ THỜI TIẾT\\n"
      "Cuối tháng 11 ở Hà Nội rất lý tưởng với nhiệt độ 15-24°C, trời mát mẻ và ít mưa.\\n\\n"
      "💰 NGÂN SÁCH (Tổng: 10.000.000 VND)\\n"
      "Chỗ ở: 1.700.000 VND (2 đêm)\\n"
      "Ăn uống: 2.700.000 VND\\n"
      "Di chuyển: 600.000 VND\\n"
      "Tham quan: 390.000 VND\\n"
      "Dự phòng: 3.610.000 VND\\n\\n"
      "🏨 NƠI LƯU TRÚ\\n"
      "Khách sạn 3 sao khu vực Phố Cổ, gần Hồ Hoàn Kiếm\\n\\n"
      "🎯 ĐIỂM NHẤN\\n"
      "Văn Miếu Quốc Tử Giám - Trường đại học đầu tiên VN\\n"
      "Hoàng Thành Thăng Long - Di sản thế giới\\n"
      "Phố Cổ Hà Nội - Ẩm thực và văn hóa địa phương\\n"
      "Múa rối nước - Nghệ thuật truyền thống độc đáo\\n\\n"
      "⚠️ LƯU Ý\\n"
      "Đặt phòng sớm để có giá tốt\\n"
      "Mang theo tiền mặt cho các quán ăn nhỏ\\n"
      "Mặc trang phục lịch sự khi vào Lăng Bác"
    )
    human_prompt = """Here is the complete trip plan to summarize:

Trip Plan:
{trip_plan}

Detailed Itinerary:
{itinerary}

Generate the summary based on the trip plan and itinerary above."""
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
    
    # Extract itinerary from trip_plan
    itinerary = trip_plan.get('itinerary', {})
    itinerary_content = itinerary.get('itinerary', '') if isinstance(itinerary, dict) else str(itinerary)
    
    chain = self.prompt | self.llm
    result = chain.invoke({
      "trip_plan": trip_plan,
      "itinerary": itinerary_content
    })
    
    # Add the itinerary content and format below the result
    summary_content = result.content
    
    # Add the detailed itinerary section
    itinerary_section = f"""

📅 LỊCH TRÌNH CHI TIẾT

{itinerary_content}"""
    
    final_content = summary_content + itinerary_section
    
    return {"summary": final_content} 