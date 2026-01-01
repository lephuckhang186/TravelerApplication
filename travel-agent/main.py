from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Optional
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import json

# Load environment variables from root .env file
load_dotenv(dotenv_path="../.env")

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
    """
    Request model for the general invocation endpoint.

    Attributes:
        input (str): The user's input message.
        history (List[Dict[str, str]]): Conversation history, default is empty.
    """
    input: str
    history: List[Dict[str, str]] = []

# Define the request body model for plan editing
class PlanEditRequest(BaseModel):
    """
    Request model for editing an existing trip plan.

    Attributes:
        command (str): The user's command describing how to modify the plan.
        trip_id (str): The unique identifier of the trip to edit.
        conversation_history (List[Dict[str, str]]): Recent chat history for context.
    """
    command: str
    trip_id: str
    conversation_history: List[Dict[str, str]] = []

# Define the request body model for trip planning
class TripPlanRequest(BaseModel):
    """
    Request model for generating a new trip plan.

    Attributes:
        prompt (str): The user's prompt describing the desired trip.
        user_id (Optional[str]): The user's ID, if authenticated.
    """
    prompt: str
    user_id: Optional[str] = None

# Define the API endpoint for general AI queries
@api.post("/invoke")
async def invoke_workflow(request: InvokeRequest):
    """
    General AI assistant endpoint for queries that don't involve plan modifications.
    
    This endpoint handles general conversation. Plan modifications are routed 
    separately to the /edit-plan endpoint.

    Args:
        request (InvokeRequest): The request payload containing user input.

    Returns:
        dict: A simple acknowledgment summary.
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

    When a user wants to edit a plan, this endpoint uses an LLM to generate a 
    completely new plan structure that incorporates the requested changes 
    while maintaining the logic of the original plan.

    Args:
        request (PlanEditRequest): The request payload with edit command and context.

    Returns:
        dict: A response indicating success/failure and containing the new plan data.
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
    
    This endpoint uses a comprehensive prompt to generate a detailed day-by-day
    itinerary, including logistics, estimated costs, and specific addresses.

    Args:
        request (TripPlanRequest): The request payload containing the trip prompt.

    Returns:
        dict: A structured JSON trip plan or an error message.
    """
    try:
        from services.llm_utils import get_llm, get_default_prompt

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
        Bạn là một chuyên gia lên kế hoạch du lịch chuyên nghiệp với kiến thức thực tế về Việt Nam. Nhiệm vụ của bạn là tạo ra một kế hoạch du lịch hoàn chỉnh và chi tiết dựa trên yêu cầu của người dùng.

        Yêu cầu đầu ra:
        1. Phân tích yêu cầu và trích xuất thông tin chính (điểm đến, thời gian, số người, ngân sách, ĐIỂM KHỞI HÀNH, PHƯƠNG TIỆN DI CHUYỂN ƯA THÍCH)
        2. Tạo kế hoạch chi tiết cho từng ngày với các hoạt động cụ thể THEO TRẬT TỰ ĐỊA LÝ LOGIC
        3. Ước tính chi phí cho từng hoạt động và tổng cộng
        4. Gợi ý phương tiện di chuyển và chỗ ở phù hợp
        5. Trả về JSON với cấu trúc chuẩn để ứng dụng có thể import

        QUAN TRỌNG VỀ TỔ CHỨC ĐƯỜNG ĐI:
        - XÁC ĐỊNH ĐIỂM KHỞI HÀNH từ yêu cầu người dùng (ví dụ: ga xe lửa Hồ Chí Minh, sân bay, nhà ga...)
        - XÁC ĐỊNH MÚI GIỜ: Tự động xác định múi giờ của điểm khởi hành và điểm đến (ví dụ: VN UTC+7, Mỹ UTC-5, châu Âu UTC+1)
        - CHUYỂN ĐỔI THỜI GIAN: Điều chỉnh giờ khởi hành và hoạt động theo múi giờ địa phương
        - XỬ LÝ JET LAG: Cân nhắc thời gian bay dài và hiệu ứng jet lag khi lên lịch hoạt động
        - SẮP XẾP HOẠT ĐỘNG THEO MÚI GIỜ: Đảm bảo giờ hoạt động hợp lý theo thời gian địa phương
        - TÍNH TOÁN THỜI GIAN DI CHUYỂN THỰC TẾ: Sử dụng khoảng cách địa lý và phương tiện để ước lượng chính xác
        - TRÁNH nhảy cóc giữa các địa điểm xa xôi không hợp lý
        - ĐẢM BẢO kế hoạch có thể thực hiện được về mặt logistics và múi giờ

        QUAN TRỌNG VỀ ƯỚC LƯỢNG THỜI GIAN DI CHUYỂN:
        - TÍNH TOÁN DỰA TRÊN KHOẢNG CÁCH THỰC TẾ: Sử dụng khoảng cách địa lý và tốc độ di chuyển hợp lý
        - ĐI BỘ: ~5km/h trong thành phố, cộng thêm thời gian chờ đèn đỏ và đường cong
        - XE CỘ: Tùy traffic, giờ cao điểm có thể chậm hơn 2-3 lần so với bình thường
        - PHƯƠNG TIỆN CÔNG CỘNG: Bao gồm thời gian chờ, mua vé, di chuyển đến điểm dừng
        - MÁY BAY: Thời gian bay thực tế + thời gian sân bay (check-in, security, boarding, lấy hành lý)
        - TÀU/XE BUÝT LIÊN THÀNH PHỐ: Tra cứu lịch trình thực tế, cộng thời gian lên/xuống phương tiện
        - THỜI GIAN DỰ PHÒNG: Cộng thêm 15-30 phút cho các yếu tố bất ngờ (traffic, thời tiết, nghỉ ngơi)
        - CẬP NHẬT THEO THỜI GIAN THỰC: Xem xét điều kiện traffic hiện tại, mùa vụ, giờ cao điểm

        QUAN TRỌNG VỀ LỰA CHỌN PHƯƠNG TIỆN DI CHUYỂN THEO KHOẢNG CÁCH:
        - ĐÁNH GIÁ KHOẢNG CÁCH: Tính toán khoảng cách địa lý giữa các điểm đến để chọn phương tiện phù hợp
        - KHOẢNG CÁCH NGẮN (< 5km): Đi bộ, xe đạp, xe máy, taxi/Grab - ưu tiên đi bộ nếu thời tiết thuận lợi
        - KHOẢNG CÁCH TRUNG BÌNH (5-50km): Xe buýt, tàu điện ngầm, taxi, xe thuê - cân nhắc thời gian và chi phí
        - KHOẢNG CÁCH DÀI (50-500km): Tàu hỏa, máy bay nội địa - ưu tiên máy bay nếu muốn nhanh, tàu nếu muốn tiết kiệm
        - KHOẢNG CÁCH RẤT DÀI (>500km): Máy bay quốc tế - thường là lựa chọn duy nhất thực tế
        - CÂN NHẮC YẾU TỐ: Thời gian, chi phí, tiện nghi, sở thích người dùng, điều kiện thời tiết, giờ cao điểm
        - ƯU TIÊN PHƯƠNG TIỆN NGƯỜI DÙNG CHỌN: Nếu người dùng chỉ định phương tiện cụ thể, ưu tiên phương tiện đó nhưng vẫn xem xét tính thực tế

        QUAN TRỌNG VỀ PHƯƠNG TIỆN DI CHUYỂN CỤ THỂ:
        - BAY: Sử dụng lịch bay thực tế (Vietnam Airlines, VietJet, Bamboo Airways) - phù hợp cho >50km
        - TÀU: Ga Sapa, Hà Nội, Đà Nẵng, Hồ Chí Minh - phù hợp cho 100-800km, tiết kiệm và thoải mái
        - XE BUÝT: The Sinh Tourist, Sapaco Tourist, Kumho Samco - phù hợp cho 5-200km, giá rẻ
        - XE Ô TÔ/XE MÁY: Thuê xe hoặc Grab - phù hợp cho <50km trong thành phố
        - KHÔNG sáng tạo lịch trình không tồn tại - chỉ đề xuất phương tiện có thực tại điểm đến

        QUAN TRỌNG VỀ ƯỚC LƯỢNG CHI PHÍ THỰC TẾ:
        - NGHIÊN CỨU GIÁ THỰC TẾ: Sử dụng kiến thức cập nhật về giá cả tại điểm đến cụ thể
        - ĐIỀU CHỈNH THEO QUỐC GIA: Sử dụng đơn vị tiền tệ phù hợp (VND ở VN, USD ở Mỹ, EUR ở châu Âu, etc.)
        - PHÙ HỢP VỚI MỨC ĐỘ SANG TRỌNG: Budget (tiết kiệm), Mid-range (trung cấp), Luxury (sang trọng) (tính toán dựa trên total budget và số người)
        - CẬP NHẬT THEO THỜI GIAN: Giá có thể thay đổi theo mùa, sự kiện đặc biệt

        QUAN TRỌNG VỀ ĐỊA CHỈ: Mỗi hoạt động PHẢI có địa chỉ CHI TIẾT, đầy đủ để có thể load trên bản đồ và route đường đi.
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
                "currency": "VND",
                "starting_point": "Điểm khởi hành từ yêu cầu người dùng"
            }},
            "daily_plans": [
                {{
                    "day": số,
                    "date": "YYYY-MM-DD",
                    "activities": [
                        {{
                            "title": "Tên hoạt động",
                            "description": "Mô tả chi tiết với thông tin di chuyển từ điểm trước",
                            "start_time": "HH:MM",
                            "duration_hours": số,
                            "activity_type": "activity|restaurant|lodging|flight|tour",
                            "estimated_cost": số,
                            "location": "Tên địa điểm",
                            "address": "Địa chỉ đầy đủ cho bản đồ (đường, quận/huyện, thành phố)",
                            "coordinates": "Tọa độ GPS (latitude,longitude) nếu có thể",
                            "travel_from_previous": "Mô tả cách di chuyển từ hoạt động trước với thời gian thực tế"
                        }}
                    ]
                }}
            ],
            "summary": {{
                "total_estimated_cost": số,
                "recommendations": ["Lời khuyên hữu ích về logistics và di chuyển với thông tin thực tế"],
                "tips": ["Mẹo du lịch và tối ưu hóa đường đi dựa trên kinh nghiệm thực tế"]
            }}
        }}

        Lưu ý:
        - Thời gian bắt đầu tính từ ngày hiện tại + 7 ngày
        - Chi phí tính bằng VND
        - Hoạt động phải đa dạng và thực tế
        - Bao gồm ăn uống, di chuyển, tham quan, nghỉ ngơi
        - SỬ DỤNG THÔNG TIN PHƯƠNG TIỆN DI CHUYỂN THỰC TẾ, không bịa đặt
        - ĐẶC BIỆT CHÚ Ý đến điểm khởi hành và sắp xếp hoạt động theo thứ tự địa lý hợp lý

        Trả về CHỈ JSON, không có text khác.
        """

        human_message = f"Hãy lên kế hoạch du lịch cho yêu cầu sau: {prompt}"

        chat_prompt = get_default_prompt(system_message, human_message)
        chain = chat_prompt | llm

        # Get AI response with timeout
        try:
            print(f"Calling Gemini API with model: {os.getenv('LLM_MODEL', 'gemini-2.5-flash')}")
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
