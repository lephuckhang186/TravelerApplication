from models import QueryAnalysisResult
from services.llm_utils import get_llm, get_default_prompt
import os
from datetime import datetime, timedelta
import re

class QueryAnalyzer:
  def __init__(self):
    self.llm = get_llm()
    system_prompt = (
      "Bạn là một chuyên gia tư vấn du lịch thông minh và thân thiện. "
      "Nhiệm vụ của bạn là phân tích yêu cầu của người dùng và trích xuất thông tin cần thiết để lập kế hoạch du lịch. "
      "\n\nHãy xác định các thông tin sau:\n"
      "- destination (điểm đến): tên thành phố, quốc gia hoặc khu vực du lịch\n"
      "- budget (ngân sách): số tiền cụ thể, có thể tính bằng VND, USD, EUR, etc.\n"
      "- native_currency (loại tiền): VND cho người Việt, USD cho người nước ngoài\n"
      "- start_date và end_date (ngày bắt đầu và kết thúc): định dạng YYYY-MM-DD\n"
      "- days (số ngày): tự động tính từ start_date và end_date\n"
      "- activity_preferences (sở thích hoạt động): ăn uống, tham quan, mua sắm, etc.\n"
      "\n\nQuy tắc quan trọng:\n"
      "1. KHÔNG tự động đoán start_date hoặc end_date nếu người dùng không cung cấp rõ ràng\n"
      "2. Đánh dấu các trường thiếu trong missing_fields: destination, budget, start_date, end_date\n"
      "3. Nếu có khoảng giá hoặc số ngày, lấy giá trị tối đa\n"
      "4. Nếu không rõ loại tiền, mặc định VND cho người Việt, USD cho người khác\n"
      "5. Nếu câu hỏi không liên quan du lịch, trả về QueryAnalysisResult rỗng\n"
      "\nHãy trả lời một cách chính xác và chi tiết."
    )
    human_prompt = "{user_query}"
    self.prompt = get_default_prompt(system_prompt, human_prompt)
    self.structured_llm = self.llm.with_structured_output(QueryAnalysisResult)

  def analyze(self, user_query: str) -> QueryAnalysisResult:
    """Uses an LLM to extract trip details and identify missing fields."""
    chain = self.prompt | self.structured_llm
    result = chain.invoke({"user_query": user_query})
    
    # Post-process to handle date logic
    result = self._handle_date_logic(result, user_query)
    
    return result
  
  def _handle_date_logic(self, result: QueryAnalysisResult, user_query: str) -> QueryAnalysisResult:
    """Handle automatic date filling based on user requirements."""
    today = datetime.now().date()
    
    # Rule 1: If user provides end_date but no start_date, set start_date to today
    if not result.start_date and result.end_date:
      result.start_date = today.strftime('%Y-%m-%d')
      # Remove start_date from missing_fields if it was there
      if result.missing_fields and 'start_date' in result.missing_fields:
        result.missing_fields.remove('start_date')
    
    # Rule 2: If user provides start_date but no end_date, keep end_date as missing
    # Rule 3: If both dates missing, keep both as missing - let the interactive system ask
    # Rule 4: If both dates provided, keep as is
    
    # Calculate days if we have both dates
    if result.start_date and result.end_date:
      try:
        start = datetime.strptime(result.start_date, '%Y-%m-%d').date()
        end = datetime.strptime(result.end_date, '%Y-%m-%d').date()
        result.days = str((end - start).days + 1)  # Include both start and end day, convert to string
      except ValueError:
        pass  # Keep original days if date parsing fails
    
    return result 