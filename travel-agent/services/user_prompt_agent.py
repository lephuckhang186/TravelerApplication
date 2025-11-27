from typing import Tuple, Dict, Any
from langchain_core.messages import HumanMessage, AIMessage
from langchain_core.prompts import ChatPromptTemplate, SystemMessagePromptTemplate, HumanMessagePromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from services.llm_utils import get_llm
from models import WorkflowState

def extract_user_fields_from_messages(state: WorkflowState) -> Tuple[Dict[str, Any], AIMessage]:
    """
    Given the state (with messages and missing_fields), use an LLM to extract the missing fields from the latest user message.
    Returns a tuple: (dict of updated fields, AIMessage with the LLM's output or error message).
    Raises an error if extraction fails.
    """
    missing_items = ', '.join(state.missing_fields or [])
    user_msg = next((m for m in reversed(state.messages) if isinstance(m, HumanMessage)), None)
    user_input = user_msg.content if user_msg else ""
    system_prompt = (
        f"Bạn là một tư vấn viên du lịch thông minh. "
        f"Danh sách thông tin còn thiếu: {missing_items}. "
        f"Câu trả lời từ người dùng: '{user_input}'. "
        f"Hãy phân tích thông tin người dùng cung cấp và cập nhật các trường thích hợp. "
        f"Trích xuất thông tin chính xác và trả về JSON object với các trường đã cập nhật. "
        f"Lưu ý: "
        f"- Ngày tháng phải ở định dạng YYYY-MM-DD "
        f"- Ngân sách phải là số cụ thể "
        f"- Điểm đến phải là tên địa danh rõ ràng "
        f"- Chỉ trả về các trường có thông tin hợp lệ"
    )
    prompt_messages = [
        SystemMessagePromptTemplate.from_template(system_prompt),
        HumanMessagePromptTemplate.from_template(user_input)
    ]
    chat_prompt = ChatPromptTemplate.from_messages(prompt_messages)
    llm = get_llm()
    parser = JsonOutputParser()
    chain = chat_prompt | llm | parser
    try:
        result = chain.invoke({})
        ai_msg = AIMessage(content=f"Updated fields: {result}")
        return result, ai_msg
    except Exception as e:
        ai_msg = AIMessage(content=f"Failed to extract fields: {e}")
        raise 