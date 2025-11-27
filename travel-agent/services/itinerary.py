import os
from services.llm_utils import get_llm, get_default_prompt
from typing import Any

class ItineraryBuilder:
    """
    Builds a day-by-day itinerary for a trip using an LLM, using the full workflow state.
    """
    def __init__(self):
        self.llm = get_llm()
        system_prompt = (
            "You are a travel assistant. Generate a detailed day-by-day itinerary with SPECIFIC TIMES, LOCATIONS and DESCRIPTIONS.\\n\\n"
            "CRITICAL FORMATTING RULES:\\n"
            "1. Structure: Use exact format 'DAY_NAME, DD MONTH YYYY' for date headers\\n"
            "2. Time entries: ALWAYS include DEPARTURE TIME and ARRIVAL TIME for each activity\\n"
            "3. Format each activity as:\\n"
            "   HH:MM - 🔸 [Activity Name] ([Specific Location])\\n"
            "   Xuất phát: HH:MM | Đến nơi: HH:MM | Thời gian tham quan: X giờ\\n"
            "   [Detailed description with address, cost, tips]\\n\\n"
            "4. Include practical details: exact addresses, transportation time, entry fees\\n"
            "5. Write descriptions in Vietnamese\\n"
            "6. Use relevant emojis for each activity type\\n"
            "7. Plan realistic travel times between locations\\n\\n"
            "EXAMPLE FORMAT:\\n"
            "TUESDAY, 25 NOVEMBER 2025\\n\\n"
            "8:00 - 🍜 Ăn sáng (Phở Bát Đàn)\\n"
            "Xuất phát: 7:45 | Đến nơi: 8:00 | Thời gian ăn: 45 phút\\n"
            "Thưởng thức phở truyền thống tại quán nổi tiếng. Địa chỉ: 49 Bát Đàn, Hoàn Kiếm. Giá: 50.000 VND/tô.\\n\\n"
            "9:30 - 🏛️ Tham quan Văn Miếu - Quốc Tử Giám\\n"
            "Xuất phát: 9:15 | Đến nơi: 9:30 | Thời gian tham quan: 2 giờ\\n"
            "Di chuyển 15 phút bằng taxi. Khám phá trường đại học đầu tiên Việt Nam. Địa chỉ: 58 Quốc Tử Giám. Vé: 30.000 VND/người.\\n\\n"
            "12:00 - 🍽️ Ăn trưa (Bún Chả Hương Liên)\\n"
            "Xuất phát: 11:45 | Đến nơi: 12:00 | Thời gian ăn: 1 giờ\\n"
            "Di chuyển 15 phút bằng xe máy. Thưởng thức bún chả authentic. Địa chỉ: 24 Lê Văn Hưu. Giá: 80.000 VND/phần.\\n\\n"
            "14:00 - ☕ Cà phê trứng (Café Giảng)\\n"
            "Xuất phát: 13:50 | Đến nơi: 14:00 | Thời gian thưởng thức: 45 phút\\n"
            "Đi bộ 10 phút. Thưởng thức cà phê trứng độc đáo. Địa chỉ: 39 Nguyễn Hữu Huân. Giá: 35.000 VND/cốc.\\n\\n"
            "15:30 - 🏮 Dạo phố cổ Hà Nội\\n"
            "Xuất phát: 15:00 | Đến nơi: 15:30 | Thời gian dạo: 2 giờ\\n"
            "Đi bộ khám phá 36 phố phường, mua sắm quà lưu niệm. Khu vực: Hoàn Kiếm, Hà Nội.\\n\\n"
            "18:00 - 🍽️ Ăn tối (Chả cá Lã Vọng)\\n"
            "Xuất phát: 17:45 | Đến nơi: 18:00 | Thời gian ăn: 1.5 giờ\\n"
            "Di chuyển 15 phút. Thưởng thức chả cá truyền thống. Địa chỉ: 14 Chả Cá. Giá: 180.000 VND/người.\\n\\n"
            "20:00 - 🏨 Trở về khách sạn\\n"
            "Xuất phát: 19:45 | Đến nơi: 20:00 | Nghỉ ngơi\\n"
            "Di chuyển về khách sạn, chuẩn bị cho ngày hôm sau.\\n\\n"
            "IMPORTANT:\\n"
            "- Use 7-9 time slots per day\\n"
            "- NO markdown (no *, **, ###, ####)\\n"
            "- Use plain text with emojis and line breaks only"
        )
        human_prompt = """
Trip State:
{state}

Generate the itinerary in the timeline format specified above.
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