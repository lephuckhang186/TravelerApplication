from models import QueryAnalysisResult
from services.llm_utils import get_llm, get_default_prompt
import os
from datetime import datetime, timedelta
import re

class QueryAnalyzer:
  """
  Analyzes user queries to identify trip details and potential missing information.

  This class uses a Language Model to parse natural language inputs and extract
  structured data such as destination, budget, dates, and number of travelers.
  It primarily relies on the `QueryAnalysisResult` model.
  """
  def __init__(self):
    """
    Initializes the QueryAnalyzer.

    Sets up the LLM, prompt templates, and the JSON output parser with
    specific instructions for extracting travel-related entities.
    """
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
    # Use a different approach for structured output to avoid langchain-core beta issues
    from langchain_core.output_parsers import JsonOutputParser
    self.output_parser = JsonOutputParser(pydantic_object=QueryAnalysisResult)
    self.chain = self.prompt | self.llm | self.output_parser

  def analyze(self, user_query: str) -> QueryAnalysisResult:
    """
    Uses an LLM to extract trip details and identify missing fields.

    Args:
      user_query (str): The natural language query from the user (e.g., "Plan a trip to Paris next week").

    Returns:
      QueryAnalysisResult: A structured object containing extracted fields like destination,
                           dates, budget, and a list of any missing required fields.
    """
    try:
      result_dict = self.chain.invoke({"user_query": user_query})
      result = QueryAnalysisResult(**result_dict)
    except Exception as e:
      # Fallback: return empty result if parsing fails
      result = QueryAnalysisResult()

    # Post-process to handle date logic
    result = self._handle_date_logic(result, user_query)

    return result

  def analyze_query(self, user_query: str) -> QueryAnalysisResult:
    """
    Alias for analyze method.

    Args:
      user_query (str): The user's input string.

    Returns:
      QueryAnalysisResult: The analysis result.
    """
    return self.analyze(user_query)
  
  def _handle_date_logic(self, result: QueryAnalysisResult, user_query: str) -> QueryAnalysisResult:
    """
    Handle automatic date filling based on user requirements.

    Applies business rules to infer dates where possible (e.g., infer start date as today if only end date is given).
    Also tries to calculate 'days' if both start and end dates are present.

    Args:
      result (QueryAnalysisResult): The initial analysis result from the LLM.
      user_query (str): The original user query (unused in current logic but kept for context).

    Returns:
      QueryAnalysisResult: The updated analysis result with post-processed date logic.
    """
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
