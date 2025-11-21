"""
Greeting Handler for Travel Agent AI
Handles greeting messages and provides friendly responses
"""

import random
import re


class GreetingHandler:
    def __init__(self):
        self.greeting_keywords = [
            'hello', 'hi', 'chào', 'xin chào', 'hey', 'hì', 'halo',
            'good morning', 'good afternoon', 'good evening',
            'chào bạn', 'xin chào bạn', 'chào ai', 'ai ơi',
            'bạn khỏe không', 'how are you', 'bạn có ổn không',
            'bonjour', 'konnichiwa', 'guten tag'
        ]
        
        self.greeting_responses = [
            """Xin chào! 👋 Rất vui được gặp bạn! Tôi là AI Travel Assistant, chuyên giúp bạn lên kế hoạch du lịch tuyệt vời.

🌟 Bạn muốn đi đâu vậy? Tôi có thể giúp bạn:
• 🗺️ Gợi ý địa điểm du lịch hot nhất
• ✈️ Lên kế hoạch chi tiết cho chuyến đi  
• 🍜 Tìm hiểu ẩm thực địa phương đặc sắc
• 🏨 Tư vấn chỗ ở phù hợp với ngân sách
• 🚗 Hướng dẫn phương tiện di chuyển tốt nhất
• 💰 Ước tính chi phí hợp lý

Hãy cho tôi biết bạn muốn đi đâu và bao lâu nhé! 😊""",

            """Chào bạn! 🌟 Tôi là trợ lý AI chuyên về du lịch Việt Nam. Tôi ở đây để biến ước mơ du lịch của bạn thành hiện thực!

✨ Từ Bắc đến Nam, tôi có thể giúp bạn:
• Khám phá những địa điểm tuyệt vời nhất
• Lập kế hoạch từng ngày chi tiết và thú vị
• Tìm món ăn ngon đậm chất địa phương
• Chọn khách sạn/homestay ưng ý
• Tính toán chi phí thông minh
• Tư vấn thời điểm du lịch lý tưởng

Bạn đang mơ về chuyến đi nào? Hãy kể cho tôi nghe nhé! 🎒""",

            """Hello! 🎉 Chào mừng bạn đến với AI Travel Assistant! Tôi rất hào hứng được đồng hành cùng bạn trong hành trình khám phá Việt Nam tuyệt đẹp.

🚀 Với kinh nghiệm sâu rộng về du lịch Việt Nam, tôi biết rõ:
• Các điểm đến hot nhất mỗi mùa
• Lịch trình tối ưu cho mọi thời gian  
• Món ăn đặc sản không thể bỏ lỡ
• Tips tiết kiệm chi phí thông minh
• Cách di chuyển tiện lợi nhất
• Thời gian lý tưởng cho từng địa điểm

Bạn có kế hoạch gì chưa? Hay để tôi gợi ý cho bạn một chuyến đi tuyệt vời nhé! 🗺️✨""",

            """Xin chào và chào mừng! 🌏 Tôi là AI Travel Assistant - người bạn đồng hành tin cậy trong mọi chuyến du lịch Việt Nam của bạn!

🎯 Tôi chuyên về:
• 📍 Tư vấn địa điểm phù hợp với sở thích
• 📅 Lập lịch trình chi tiết từng giờ
• 🍴 Gợi ý ẩm thực authentic địa phương  
• 🛏️ Tìm chỗ nghỉ chất lượng giá tốt
• 🚌 Hướng dẫn di chuyển thuận tiện
• 💸 Tối ưu hóa ngân sách du lịch

Hãy chia sẻ với tôi: Bạn muốn khám phá vùng đất nào của Việt Nam? 🇻🇳"""
        ]
    
    def is_greeting_message(self, message: str) -> bool:
        """
        Check if the message is a greeting
        """
        if not message or not isinstance(message, str):
            return False
            
        # Convert to lowercase and clean up
        clean_message = message.lower().strip()
        
        # Remove punctuation for better matching
        clean_message = re.sub(r'[^\w\s]', ' ', clean_message)
        
        # Check if any greeting keywords are present
        return any(keyword in clean_message for keyword in self.greeting_keywords)
    
    def generate_greeting_response(self, user_message: str = "") -> str:
        """
        Generate a friendly greeting response
        """
        # Choose a random response to make it feel more natural
        response = random.choice(self.greeting_responses)
        
        return response
    
    def is_simple_thanks(self, message: str) -> bool:
        """
        Check if message is a simple thank you
        """
        thanks_keywords = [
            'cảm ơn', 'thank you', 'thanks', 'cám ơn', 
            'tks', 'thx', 'merci', 'arigatou'
        ]
        
        clean_message = message.lower().strip()
        clean_message = re.sub(r'[^\w\s]', ' ', clean_message)
        
        return any(keyword in clean_message for keyword in thanks_keywords)
    
    def generate_thanks_response(self) -> str:
        """
        Generate response for thank you messages
        """
        thanks_responses = [
            "Không có gì! 😊 Tôi luôn sẵn sàng giúp bạn lên kế hoạch du lịch tuyệt vời. Còn gì khác tôi có thể hỗ trợ không?",
            "Rất vui được giúp bạn! 🌟 Nếu có thêm câu hỏi gì về du lịch, đừng ngại hỏi tôi nhé!",
            "Đó là niềm vui của tôi! ✨ Chúc bạn có những chuyến đi thật tuyệt vời!",
            "Cảm ơn bạn! 😄 Tôi hy vọng thông tin của tôi sẽ giúp ích cho chuyến đi của bạn!"
        ]
        
        return random.choice(thanks_responses)


# Global instance
greeting_handler = GreetingHandler()