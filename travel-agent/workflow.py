from models import QueryAnalysisResult, TripPlan, WorkflowState, HotelInfo
from services.query_analyzer import QueryAnalyzer
from services.hotels import HotelFinder
from services.weather import WeatherService
from services.attractions import AttractionFinder
from services.currency import CurrencyConverter
from services.calculator import Calculator
from services.itinerary import ItineraryBuilder
from services.summary import TripSummary
from langgraph.graph import StateGraph, START, END
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, BaseMessage, AIMessage
from langgraph.types import Command
from services.llm_utils import get_llm, make_system_prompt
from typing import Optional, Dict, Any, List, Union, Literal
import datetime
import json
from pydantic import ValidationError, BaseModel
from langchain_tavily import TavilySearch
import re
import pprint

# Instantiate all agents/tools
query_analyzer = QueryAnalyzer()
hotel_finder = HotelFinder()
weather_service = WeatherService()
attraction_finder = AttractionFinder()
currency_converter = CurrencyConverter()
calculator = Calculator()
itinerary_builder = ItineraryBuilder()
summary_generator = TripSummary()
search_tool = TavilySearch()

def get_today() -> str:
  """Returns today's date in YYYY-MM-DD format."""
  return datetime.date.today().isoformat()

_today = get_today()

def clean_agent_output(raw_content: Union[str, List[Union[str, Dict[str, Any]]]]) -> str:
  """
  Extracts clean text content from agent output, removing tool calls and signatures.

  Args:
      raw_content (Union[str, List[Union[str, Dict]]]): The raw output from an agent, which can be a string
                                                       or a list of content blocks.

  Returns:
      str: The cleaned text content.
  """
  if isinstance(raw_content, list):
      # If it's a list of content blocks, extract only text parts
      text_parts = []
      for item in raw_content:
          if isinstance(item, dict):
              if 'text' in item:
                  text_parts.append(item['text'])
              # Skip tool calls, signatures, and other metadata
          elif isinstance(item, str):
              # Filter out tool call patterns and signatures
              if not (item.strip().startswith('{') and 'signature' in item.lower()):
                  text_parts.append(item)
      return '\n'.join(text_parts) if text_parts else ""
  elif isinstance(raw_content, str):
      # Filter out tool call JSON and signature patterns
      lines = raw_content.split('\n')
      clean_lines = []
      skip_json = False
      for line in lines:
          stripped = line.strip()
          # Skip JSON tool calls
          if stripped.startswith('{') and ('signature' in stripped.lower() or 'tool_call' in stripped.lower()):
              skip_json = True
              continue
          elif stripped.endswith('}') and skip_json:
              skip_json = False
              continue
          elif skip_json:
              continue
          else:
              clean_lines.append(line)
      return '\n'.join(clean_lines)
  else:
      return str(raw_content)

# Create agents using the traditional LangChain approach
def create_agent_with_tools(model: Any, tools: List[Any], system_message: str) -> AgentExecutor:
    """
    Creates a LangChain agent executor with specified tools and system message.

    Args:
        model (Any): The language model to use.
        tools (List[Any]): A list of tools available to the agent.
        system_message (str): The system prompt defining the agent's role and behavior.

    Returns:
        AgentExecutor: A configured agent executor ready to be invoked.
    """
    prompt = ChatPromptTemplate.from_messages([
        ("system", system_message),
        ("placeholder", "{chat_history}"),
        ("human", "{input}"),
        ("placeholder", "{agent_scratchpad}"),
    ])
    agent = create_tool_calling_agent(model, tools, prompt)
    return AgentExecutor(agent=agent, tools=tools, verbose=False)

# Create a simple travel query evaluator
travel_evaluator = create_agent_with_tools(
    model=get_llm(),
    tools=[],
    system_message="""
    You are a travel query evaluator. Your job is to determine if a user message is travel-related.
    A travel-related query should mention or imply:
    - A destination or place to visit
    - Travel dates or duration
    - Travel activities, accommodation, or budget

    Respond with ONLY "TRAVEL" if it's travel-related, or "NOT_TRAVEL" if it's not.
    """
)

hotel_agent = create_agent_with_tools(
    model=get_llm(),
    tools=[HotelFinder.find_hotels_static],
    system_message=f"""
    You are a hotel search expert. Your job is to find and list specific hotels with their exact names and prices.

    IMPORTANT: Return ONLY a simple list of hotels in Vietnamese like this format:

    Khách sạn có sẵn tại [destination]:
    1. [Hotel Name] - [price] VND/đêm
    2. [Hotel Name] - [price] VND/đêm
    3. [Hotel Name] - [price] VND/đêm

    Example:
    Khách sạn có sẵn tại Hà Nội:
    1. Hanoi La Siesta Hotel & Spa - 1.200.000 VND/đêm
    2. Oriental Central Hotel - 950.000 VND/đêm
    3. May De Ville Old Quarter - 800.000 VND/đêm

    Do NOT provide full travel plans, descriptions, or other information. Only hotel names and prices.
    Today is {_today}. Do not use dates in the past.
    """
)

weather_agent = create_agent_with_tools(
    model=get_llm(),
    tools=[weather_service.get_weather],
    system_message=f"""
You are a weather expert. Your job is to provide ONLY weather information, not full travel plans.

IMPORTANT: Return ONLY weather information in Vietnamese like this format:

Thời tiết tại [destination] từ [start_date] đến [end_date]:
- [date]: [condition], nhiệt độ [min]°C - [max]°C
- [date]: [condition], nhiệt độ [min]°C - [max]°C
- [date]: [condition], nhiệt độ [min]°C - [max]°C

Example:
Thời tiết tại Hà Nội từ 25/11/2025 đến 27/11/2025:
- 25/11: Nhiều mây, nhiệt độ 19°C - 24°C
- 26/11: Trời quang đãng, nhiệt độ 15°C - 24°C
- 27/11: Mây rải rác, nhiệt độ 15°C - 24°C

Do NOT provide travel recommendations, itineraries, or other information. Only weather data.
Today is {_today}. Do not use dates in the past.
"""
)

attractions_agent = create_agent_with_tools(
    model=get_llm(),
    tools=[attraction_finder.find_attractions, attraction_finder.estimate_attractions_cost, search_tool],
    system_message=f"""
You are an attractions expert. Your job is to provide ONLY a list of attractions and their ticket prices.

IMPORTANT: Return ONLY attractions information in Vietnamese like this format:

Các điểm tham quan tại [destination]:
1. [Attraction Name] - Vé vào cửa: [price] VND/người (hoặc Miễn phí)
2. [Attraction Name] - Vé vào cửa: [price] VND/người
3. [Attraction Name] - Vé vào cửa: [price] VND/người

Example:
Các điểm tham quan tại Hà Nội:
1. Đền Ngọc Sơn - Vé vào cửa: 30.000 VND/người
2. Văn Miếu - Quốc Tử Giám - Vé vào cửa: 30.000 VND/người
3. Lăng Chủ tịch Hồ Chí Minh - Vé vào cửa: Miễn phí
4. Hoàng Thành Thăng Long - Vé vào cửa: 30.000 VND/người
5. Nhà tù Hỏa Lò - Vé vào cửa: 30.000 VND/người

Do NOT provide full travel plans, descriptions, or recommendations. Only attraction names and ticket prices.
If you are routed back by the supervisor, you may use the search tool to look up the latest information.
Today is {_today}. Do not use dates in the past.
"""
)

calculator_agent = create_agent_with_tools(
    model=get_llm(),
    tools=[calculator.add, calculator.subtract, calculator.multiply, calculator.divide, currency_converter.convert, search_tool],
    system_message=f"""
You are a calculator and budget allocation expert. Your job is to:
- Extract all costs you can find from the provided state (e.g., hotel prices, attraction costs, etc.).
- Split the user's budget by these costs and provide a clear breakdown.
- If you are missing any cost or are uncertain about a cost, you may use the search tool to look up the latest prices or estimates for any travel-related expense (e.g., food, transportation, tickets, etc.).
- Use the search tool whenever you feel it is necessary to allocate the budget accurately.
- If currency conversion is needed, use the currency conversion tool.
- Return a clear, itemized breakdown of all costs and any conversions performed.
Today is {_today}. Do not use dates in the past.
"""
)

# Node functions
class TravelEvaluationResult(BaseModel):
  """Validation model for travel evaluation result."""
  result: Literal["TRAVEL", "NOT_TRAVEL"]

def router_travel_evaluator(state: WorkflowState) -> str:
  """
  Checks if query is travel-related using the travel_evaluator agent.
  
  If the query is not travel-related, it ends the conversation.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      str: Next node to go to ("query_analyzer" or END).

  Raises:
      ValueError: If agent output is invalid.
  """
  print("\n---- TRAVEL EVALUATOR ----")
  user_msg = state.messages[-1].content
  result = travel_evaluator.invoke({"input": str(user_msg)})
  response = result['output'].strip()
  try:
    TravelEvaluationResult(result=response)
  except ValidationError:
    raise ValueError(f"Invalid travel evaluator output: {response}")
  return response

def node_missing_fields_handler(state: WorkflowState) -> Command:
  """
  Handles cases where required trip information is missing.

  Checks for missing fields in the state and generates follow-up questions to ask the user.
  If questions are generated, it returns an END command to pause execution and wait for user input.
  Otherwise, it proceeds to the hotel agent.

  Args:
      state (WorkflowState): Current workflow state with potentially missing fields.

  Returns:
      Command: A LangGraph Command indicating whether to stop (END) or proceed to 'hotel_agent'.
  """
  print("\n---- MISSING FIELDS HANDLER ----")
  
  if not state.missing_fields:
    return Command(goto="hotel_agent", update=state)
  
  # Generate appropriate questions based on missing fields
  questions = []
  
  for field in state.missing_fields:
    if field == 'destination':
      questions.append("Bạn muốn du lịch đến đâu?")
    elif field == 'budget':
      questions.append("Ngân sách dự kiến của bạn là bao nhiêu? (ví dụ: 10 triệu VND)")
    elif field == 'start_date' and 'end_date' in state.missing_fields:
      questions.append("Bạn muốn du lịch từ ngày nào đến ngày nào? (ví dụ: từ 25/11/2025 đến 27/11/2025)")
      # Skip end_date since we handle both together
      continue
    elif field == 'end_date' and 'start_date' not in state.missing_fields:
      questions.append("Bạn muốn du lịch đến ngày nào? (ví dụ: 27/11/2025)")
    elif field == 'start_date' and 'end_date' not in state.missing_fields:
      # This shouldn't happen due to our logic, but handle it
      questions.append("Bạn muốn bắt đầu du lịch từ ngày nào? (ví dụ: 25/11/2025)")
  
  if questions:
    response_text = "Tôi cần thêm một số thông tin để lập kế hoạch tốt hơn:\\n\\n" + "\\n".join(f"• {q}" for q in questions)
    response_text += "\\n\\nVui lòng cung cấp thông tin còn thiếu."
    
    # Add AI response to messages
    state.messages.append(AIMessage(content=response_text))
    print(f"Asking for missing fields: {state.missing_fields}")
    print(f"Response: {response_text}")
    
    # Return END to wait for user response - this will be handled by a conversational flow
    return Command(goto=END, update=state)
  
  return Command(goto="hotel_agent", update=state)

def node_query_analyzer(state: WorkflowState) -> Command:
  """
  Analyzes the latest user message to extract trip details.

  Invokes the QueryAnalyzer service to parse the user's natural language input
  and updates the workflow state with extracted entities (destination, dates, etc.).
  Checks if critical fields are still missing.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: A command to proceed to 'missing_fields_handler' if critical info is missing,
               or 'hotel_agent' otherwise.
  """
  print("\n---- QUERY ANALYZER ----")
  user_msg = state.messages[-1].content
  result: QueryAnalysisResult = query_analyzer.analyze(str(user_msg))
  
  # Merge result into state
  for k, v in result.model_dump().items():
    setattr(state, k, v)
  
  print(f"Analysis result: {result.model_dump()}")
  
  # Check if critical fields are missing
  if result.missing_fields:
    critical_missing = [f for f in result.missing_fields if f in ['destination', 'budget', 'start_date', 'end_date']]
    if critical_missing:
      return Command(goto="missing_fields_handler", update=state)
  
  return Command(goto="hotel_agent", update=state)

def node_hotel_agent(state: WorkflowState) -> Command:
  """
  Finds hotel options for the destination.

  Invokes the hotel_agent (tool-calling agent) to search for hotels available
  in the specified destination and dates. Updates the state with the result.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceed to 'weather_agent'.
  """
  print("\n---- HOTEL AGENT ----")
  result = hotel_agent.invoke({"input": f"Find hotels in {state.destination}"})
  raw_content = result['output']

  # Clean the output to remove signatures and tool calls
  clean_content = clean_agent_output(raw_content)

  # Store the hotels text directly instead of trying to parse JSON
  if clean_content and clean_content.strip():
    state.hotels = clean_content.strip()
    print("Hotels:")
    print(state.hotels)
  else:
    print("Hotel agent returned empty content")
    state.hotels = "Không tìm thấy khách sạn phù hợp"

  return Command(goto="weather_agent", update=state)

def node_weather_agent(state: WorkflowState) -> Command:
  """
  Fetches weather forecast for the trip dates.

  Invokes the weather_agent to get forecast data for the destination
  during the planned travel period. Updates the state with the weather report.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceed to 'attractions_agent'.
  """
  print("\n---- WEATHER AGENT ----")
  result = weather_agent.invoke({"input": f"Get weather for {state.destination} from {state.start_date} to {state.end_date}"})
  weather_message = result['output']

  state.weather = str(weather_message)
  print("Weather:")
  print(state.weather)
  return Command(goto="attractions_agent", update=state)

def node_attractions_agent(state: WorkflowState) -> Command:
  """
  Finds tourist attractions based on destination and preferences.

  Invokes the attractions_agent to search for points of interest.
  Updates the state with a list of attractions and ticket prices.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceed to 'calculator_agent'.
  """
  print("\n---- ATTRACTIONS AGENT ----")
  result = attractions_agent.invoke({"input": f"Find attractions in {state.destination}"})
  raw_content = result['output']

  # Extract only the text content, ignore tool calls and signatures
  state.attractions = clean_agent_output(raw_content)

  print("Attractions found:")
  print(state.attractions)
  return Command(goto="calculator_agent", update=state)

def node_calculator_agent(state: WorkflowState) -> Command:
  """
  Calculates a budget breakdown for the trip.

  Invokes the calculator_agent to estimate costs for hotels, attractions,
  and other expenses, ensuring they fit within the total budget.
  Updates the state with the calculation result.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceed to 'itinerary_agent'.
  """
  print("\n---- CALCULATOR AGENT ----")
  result = calculator_agent.invoke({"input": f"Calculate budget for trip to {state.destination} with budget {state.budget}"})
  raw_content = result['output']

  # Extract only the text content, ignore tool calls and signatures
  state.calculator_result = clean_agent_output(raw_content)

  print("Calculator result:")
  print(state.calculator_result)
  return Command(goto="itinerary_agent", update=state)

def node_itinerary_agent(state: WorkflowState) -> Command:
  """
  Generates the detailed day-by-day itinerary.

  Uses the ItineraryBuilder service to compile all collected information (hotels, weather, attractions)
  into a cohesive timeline. Updates the state with the itinerary object.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceed to 'summary_agent'.
  """
  print("\n---- ITINERARY AGENT ----")
  itinerary = itinerary_builder.build(state)
  state.itinerary = itinerary
  print("Itinerary:")
  pprint.pprint(itinerary)
  return Command(goto="summary_agent", update=state)

def node_summary_agent(state: WorkflowState) -> Command:
  """
  Generates the final trip summary and formatted output.

  Uses the TripSummary service to create a user-friendly overview of the entire plan.
  Also checks for supervisor signals in the output (e.g., 'regenerate').

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      Command: Proceeds to specific agent if regeneration requested, otherwise END.
  """
  print("\n---- SUMMARY AGENT ----")
  summary = summary_generator.generate_summary({
    'messages': state.messages,
    "destination": state.destination,
    "days": state.days,
    "attractions": state.attractions or [],
    "hotel_info": state.hotels,
    "weather": state.weather,
    "itinerary": state.itinerary,
    "calculator_result": state.calculator_result
  })
  state.summary = summary
  print("Summary:")
  pprint.pprint(summary)
  # Parse for next step signal
  content = summary.get('summary') if isinstance(summary, dict) else str(summary)
  match = re.search(r'regenerate:(\w+_agent)', content)
  if match:
    next_agent = match.group(1)
    print(f"Supervisor requests regeneration: {next_agent}")
    return Command(goto=next_agent, update=state)
  elif 'final' in content.lower():
    return Command(goto=END, update=state)
  else:
    # Default: end if no clear signal
    return Command(goto=END, update=state)

def summary_supervisor_router(state: WorkflowState) -> str:
  """
  Determines the next step based on the summary agent's output.

  Parses the summary content for explicit regeneration commands or completion signals.

  Args:
      state (WorkflowState): Current workflow state.

  Returns:
      str: Next node name or END.
  """
  content = state.summary.get('summary') if isinstance(state.summary, dict) else str(state.summary)
  match = re.search(r'regenerate:(\w+_agent)', content)
  if match:
    return match.group(1)
  elif 'final' in content.lower():
    return END
  return END

# Build the simplified graph
workflow = StateGraph(WorkflowState)
workflow.add_node("query_analyzer", node_query_analyzer)
workflow.add_node("missing_fields_handler", node_missing_fields_handler)
workflow.add_node("hotel_agent", node_hotel_agent)
workflow.add_node("weather_agent", node_weather_agent)
workflow.add_node("attractions_agent", node_attractions_agent)
workflow.add_node("calculator_agent", node_calculator_agent)
workflow.add_node("itinerary_agent", node_itinerary_agent)
workflow.add_node("summary_agent", node_summary_agent)

# Conditional edge for travel_evaluator
workflow.add_conditional_edges(
    START,
    router_travel_evaluator,
    {"TRAVEL": "query_analyzer", "NOT_TRAVEL": END}
)

workflow.add_edge("missing_fields_handler", "hotel_agent")
workflow.add_edge("hotel_agent", "weather_agent")
workflow.add_edge("weather_agent", "attractions_agent")
workflow.add_edge("attractions_agent", "calculator_agent")
workflow.add_edge("calculator_agent", "itinerary_agent")
workflow.add_edge("itinerary_agent", "summary_agent")
workflow.add_conditional_edges("summary_agent", summary_supervisor_router, {
  "attractions_agent": "attractions_agent",
  "itinerary_agent": "itinerary_agent",
  "calculator_agent": "calculator_agent",
  END: END
})
workflow.add_edge("summary_agent", END)

app = workflow.compile()

# For CLI/manual test
if __name__ == "__main__":
  state = WorkflowState(
    destination=None,
    budget=None,
    native_currency=None,
    days=None,
    group_size=None,
    activity_preferences=None,
    accommodation_type=None,
    dietary_restrictions=None,
    transportation_preferences=None,
    messages=[HumanMessage(content="I want to go to Paris for 3 days, my budget is 1000 EUR, I like art and culture, my currency is USD")]
  )
  result = app.invoke(state)
