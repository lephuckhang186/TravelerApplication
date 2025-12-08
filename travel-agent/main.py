from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Optional
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Create the FastAPI app
api = FastAPI()

# Add CORS middleware
api.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Define the request body model
class InvokeRequest(BaseModel):
    input: str
    history: List[Dict[str, str]] = []

# Define the request body model for plan editing
class PlanEditRequest(BaseModel):
    command: str
    trip_id: str
    conversation_history: List[Dict[str, str]] = []

# Define the request body model for trip planning
class TripPlanRequest(BaseModel):
    prompt: str
    user_id: Optional[str] = None

# Define the API endpoint for general AI queries
@api.post("/invoke")
async def invoke_workflow(request: InvokeRequest):
    """
    General AI assistant endpoint for queries that don't involve plan modifications.
    Plan modifications are handled by the /edit-plan endpoint with Gemini AI.
    """
    user_input = request.input.strip()

    # For now, just return a simple acknowledgment
    # All intelligent plan modifications are handled by Gemini AI in /edit-plan
    return {"summary": f"AI: Tôi đã nhận được yêu cầu của bạn. Hãy sử dụng tính năng chỉnh sửa kế hoạch thông minh nếu bạn muốn thay đổi kế hoạch du lịch!"}

# Define the plan editing endpoint with Gemini AI
@api.post("/edit-plan")
async def edit_plan(request: PlanEditRequest):
    """
    Handles intelligent plan editing using Gemini AI with conversation context.
    When user wants to edit plan, AI generates a completely new plan that replaces the old one.
    """
    try:
        command = request.command.strip()
        trip_id = request.trip_id.strip()
        conversation_history = request.conversation_history

        print(f"PLAN_EDIT: Processing command '{command}' for trip {trip_id}")

        # Check if API key is configured
        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key or api_key == "your-actual-gemini-api-key-here":
            return {
                "success": False,
                "message": "Gemini API key chưa được cấu hình.",
                "command": command
            }

        # Use Gemini AI to process the plan modification request
        from services.llm_utils import get_llm, get_default_prompt

        llm = get_llm()

        # Build conversation context
        context_messages = []
        if conversation_history:
            for msg in conversation_history[-10:]:  # Last 10 messages for context
                role = msg.get('role', 'user')
                content = msg.get('content', '')
                if role == 'user':
                    context_messages.append(f"User: {content}")
                elif role == 'assistant':
                    context_messages.append(f"Assistant: {content}")

        context_str = "\n".join(context_messages) if context_messages else "No previous context"

        system_message = f"""
        Bạn là một chuyên gia lập kế hoạch du lịch thông minh. Nhiệm vụ của bạn là tạo ra một kế hoạch du lịch hoàn toàn mới dựa trên yêu cầu chỉnh sửa của người dùng.

        QUY TẮC HOẠT ĐỘNG:
        1. Khi người dùng muốn SỬA ĐỔI kế hoạch, hãy tạo HOÀN TOÀN kế hoạch mới thay thế kế hoạch cũ
        2. KHÔNG thêm/bớt/xóa hoạt động cụ thể, mà tạo lại toàn bộ kế hoạch phù hợp với yêu cầu mới
        3. Phân tích yêu cầu mới và tạo kế hoạch từ đầu với các hoạt động, thời gian, và chi phí mới

        THÔNG TIN NGỮ CẢNH:
        - ID chuyến đi: {trip_id}
        - Lịch sử cuộc trò chuyện gần đây:
        {context_str}

        YÊU CẦU ĐẦU RA:
        Tạo kế hoạch du lịch hoàn chỉnh mới với cấu trúc JSON chuẩn.
        QUAN TRỌNG: Mỗi hoạt động PHẢI có địa chỉ CHI TIẾT, đầy đủ để có thể load trên bản đồ và route đường đi.
        Địa chỉ phải bao gồm: tên địa điểm cụ thể, tên đường, phường/xã, quận/huyện, thành phố/tỉnh, mã bưu chính, quốc gia.
        Ví dụ: "Ar Ti So, Hồ Tùng Mậu, Ấp Xuân An, Da Lat, Phường Xuân Hương - Đà Lạt, Lâm Đồng Province, 02633, Vietnam" thay vì chỉ "Phố cổ Hà Nội".
        Tọa độ GPS PHẢI được cung cấp ở định dạng "latitude,longitude" với độ chính xác cao (ví dụ: "11.9404,108.4583" cho Đà Lạt).
        KHÔNG được để trống hoặc dùng placeholder - PHẢI cung cấp tọa độ GPS thực tế và chính xác.

        Cấu trúc JSON chuẩn:
        {{
            "action_type": "full_replace",
            "message": "Đã tạo kế hoạch mới dựa trên yêu cầu của bạn",
            "new_plan": {{
                "trip_info": {{
                    "name": "Tên chuyến đi mới",
                    "destination": "Điểm đến",
                    "start_date": "YYYY-MM-DD",
                    "end_date": "YYYY-MM-DD",
                    "duration_days": số,
                    "travelers_count": số,
                    "total_budget": số,
                    "currency": "VND"
                }},
                "daily_plans": [
                    {{
                        "day": số,
                        "date": "YYYY-MM-DD",
                        "activities": [
                            {{
                                "title": "Tên hoạt động",
                                "description": "Mô tả chi tiết",
                                "start_time": "HH:MM",
                                "duration_hours": số,
                                "activity_type": "activity|restaurant|lodging|flight|tour",
                            "estimated_cost": số,
                            "location": "Tên địa điểm",
                            "address": "Địa chỉ đầy đủ cho bản đồ (đường, quận/huyện, thành phố)",
                            "coordinates": "Tọa độ GPS (latitude,longitude) nếu có thể"
                            }}
                        ]
                    }}
                ],
                "summary": {{
                    "total_estimated_cost": số,
                    "recommendations": ["Lời khuyên"],
                    "tips": ["Mẹo du lịch"]
                }}
            }}
        }}

        QUAN TRỌNG:
        - Luôn trả về action_type: "full_replace"
        - Tạo HOÀN TOÀN kế hoạch mới, không phải chỉnh sửa cục bộ
        - Thời gian bắt đầu tính từ ngày hiện tại + 7 ngày
        - Chi phí tính bằng VND
        - Hoạt động phải đa dạng và thực tế

        CHỈ TRẢ VỀ JSON, KHÔNG CÓ TEXT KHÁC.
        """

        human_message = f"Yêu cầu chỉnh sửa kế hoạch của người dùng: {command}"

        chat_prompt = get_default_prompt(system_message, human_message)
        chain = chat_prompt | llm

        try:
            print(f"Calling Gemini API for full plan replacement")
            response = chain.invoke({})
            print(f"Gemini API call successful for full plan replacement")
        except Exception as api_error:
            print(f"Gemini API error: {api_error}")
            return {
                "success": False,
                "message": f"Lỗi gọi Gemini API: {str(api_error)}",
                "command": command
            }

        # Parse the JSON response
        try:
            response_text = response.content.strip()

            # Find JSON in the response
            json_start = response_text.find('{')
            json_end = response_text.rfind('}') + 1

            if json_start >= 0 and json_end > json_start:
                json_str = response_text[json_start:json_end]
                result = json.loads(json_str)

                action_type = result.get('action_type', 'full_replace')
                message = result.get('message', 'Đã tạo kế hoạch mới')
                new_plan = result.get('new_plan', {})

                # Validate the new plan structure
                if not new_plan or 'trip_info' not in new_plan or 'daily_plans' not in new_plan:
                    raise ValueError("Invalid new plan structure")

                return {
                    "success": True,
                    "action_type": action_type,
                    "message": message,
                    "new_plan": new_plan,
                    "command": command,
                    "trip_id": trip_id
                }
            else:
                raise ValueError("No JSON found in response")

        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            return {
                "success": False,
                "message": f"Không thể phân tích kế hoạch mới: {str(e)}",
                "command": command,
                "raw_response": response.content
            }

    except Exception as e:
        print(f"PLAN_EDIT_ERROR: {e}")
        return {
            "success": False,
            "message": f"Có lỗi xảy ra khi tạo kế hoạch mới: {str(e)}",
            "command": command
        }

# Define the trip planning endpoint
@api.post("/generate-trip-plan")
async def generate_trip_plan(request: TripPlanRequest):
    """
    Generates a complete trip plan based on user prompt using AI.
    Returns a structured trip plan that can be imported into the app.
    """
    try:
        from services.llm_utils import get_llm, get_default_prompt
        import json

        prompt = request.prompt.strip()
        user_id = request.user_id

        print(f"TRIP_PLAN: Generating plan for prompt: '{prompt}'")

        # Check if API key is configured
        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key or api_key == "your-actual-gemini-api-key-here":
            return {
                "success": False,
                "message": "Gemini API key chưa được cấu hình. Vui lòng thêm GOOGLE_API_KEY vào file .env"
            }

        # Use Gemini to generate comprehensive trip plan
        llm = get_llm()

        system_message = """
        Bạn là một chuyên gia lên kế hoạch du lịch chuyên nghiệp. Nhiệm vụ của bạn là tạo ra một kế hoạch du lịch hoàn chỉnh và chi tiết dựa trên yêu cầu của người dùng.

        Yêu cầu đầu ra:
        1. Phân tích yêu cầu và trích xuất thông tin chính (điểm đến, thời gian, số người, ngân sách)
        2. Tạo kế hoạch chi tiết cho từng ngày với các hoạt động cụ thể
        3. Ước tính chi phí cho từng hoạt động và tổng cộng
        4. Gợi ý phương tiện di chuyển và chỗ ở phù hợp
        5. Trả về JSON với cấu trúc chuẩn để ứng dụng có thể import

        QUAN TRỌNG: Mỗi hoạt động PHẢI có địa chỉ CHI TIẾT, đầy đủ để có thể load trên bản đồ và route đường đi.
        Địa chỉ phải bao gồm: tên địa điểm cụ thể, tên đường, phường/xã, quận/huyện, thành phố/tỉnh, mã bưu chính, quốc gia.
        Ví dụ: "Ar Ti So, Hồ Tùng Mậu, Ấp Xuân An, Da Lat, Phường Xuân Hương - Đà Lạt, Lâm Đồng Province, 02633, Vietnam" thay vì chỉ "Phố cổ Hà Nội".
        Tọa độ GPS PHẢI được cung cấp ở định dạng "latitude,longitude" với độ chính xác cao (ví dụ: "11.9404,108.4583" cho Đà Lạt).
        KHÔNG được để trống hoặc dùng placeholder - PHẢI cung cấp tọa độ GPS thực tế và chính xác.

        Cấu trúc JSON phải bao gồm:
        {{
            "trip_info": {{
                "name": "Tên chuyến đi",
                "destination": "Điểm đến",
                "start_date": "YYYY-MM-DD",
                "end_date": "YYYY-MM-DD",
                "duration_days": số,
                "travelers_count": số,
                "total_budget": số,
                "currency": "VND"
            }},
            "daily_plans": [
                {{
                    "day": số,
                    "date": "YYYY-MM-DD",
                    "activities": [
                        {{
                            "title": "Tên hoạt động",
                            "description": "Mô tả chi tiết",
                            "start_time": "HH:MM",
                            "duration_hours": số,
                            "activity_type": "activity|restaurant|lodging|flight|tour",
                            "estimated_cost": số,
                            "location": "Tên địa điểm",
                            "address": "Địa chỉ đầy đủ cho bản đồ (đường, quận/huyện, thành phố)",
                            "coordinates": "Tọa độ GPS (latitude,longitude) nếu có thể"
                        }}
                    ]
                }}
            ],
            "summary": {{
                "total_estimated_cost": số,
                "recommendations": ["Lời khuyên hữu ích"],
                "tips": ["Mẹo du lịch"]
            }}
        }}

        Lưu ý:
        - Thời gian bắt đầu tính từ ngày hiện tại + 7 ngày
        - Chi phí tính bằng VND
        - Hoạt động phải đa dạng và thực tế
        - Bao gồm ăn uống, di chuyển, tham quan, nghỉ ngơi

        Trả về CHỈ JSON, không có text khác.
        """

        human_message = f"Hãy lên kế hoạch du lịch cho yêu cầu sau: {prompt}"

        chat_prompt = get_default_prompt(system_message, human_message)
        chain = chat_prompt | llm

        # Get AI response with timeout
        try:
            print(f"Calling Gemini API with model: {os.getenv('LLM_MODEL', 'gemini-1.5-flash')}")
            print(f"API Key configured: {bool(os.getenv('GOOGLE_API_KEY'))}")
            response = chain.invoke({})
            print(f"Gemini API call successful")
        except Exception as api_error:
            print(f"Gemini API error details: {api_error}")
            print(f"Error type: {type(api_error)}")
            return {
                "success": False,
                "message": f"Lỗi gọi Gemini API: {str(api_error)}. Vui lòng kiểm tra API key và model."
            }

        # Parse the JSON response
        try:
            # Extract JSON from the response
            response_text = response.content.strip()

            # Find JSON in the response (might be wrapped in text)
            json_start = response_text.find('{')
            json_end = response_text.rfind('}') + 1

            if json_start >= 0 and json_end > json_start:
                json_str = response_text[json_start:json_end]
                trip_plan = json.loads(json_str)

                # Validate required fields
                if "trip_info" not in trip_plan or "daily_plans" not in trip_plan:
                    raise ValueError("Invalid trip plan structure")

                return {
                    "success": True,
                    "trip_plan": trip_plan,
                    "message": "Đã tạo kế hoạch du lịch thành công!"
                }
            else:
                raise ValueError("No JSON found in response")

        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            return {
                "success": False,
                "message": f"Không thể phân tích kế hoạch du lịch: {str(e)}",
                "raw_response": response.content
            }

    except Exception as e:
        print(f"❌ TRIP_PLAN_ERROR: {e}")
        return {
            "success": False,
            "message": f"Có lỗi xảy ra khi tạo kế hoạch: {str(e)}"
        }

# No longer need helper functions - Gemini AI handles all plan modifications

# To run this API, use the command:
# uvicorn main:api --reload
if __name__ == "__main__":
    uvicorn.run(api, host="0.0.0.0", port=5000)
