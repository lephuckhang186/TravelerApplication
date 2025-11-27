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
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import HumanMessage, BaseMessage, AIMessage
from langgraph.types import Command
from langchain.agents import create_agent
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

def clean_agent_output(raw_content):
  """Extract clean text content from agent output, removing tool calls and signatures."""
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
      return '\n'.join(text_parts) if text_parts else str(raw_content)
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

# Create a simple travel query evaluator
travel_evaluator = create_agent(
  model=get_llm(),
  tools=[],
  system_prompt=(
    """
    You are a travel query evaluator. Your job is to determine if a user message is travel-related.
    A travel-related query should mention or imply:
    - A destination or place to visit
    - Travel dates or duration
    - Travel activities, accommodation, or budget
    
    Respond with ONLY "TRAVEL" if it's travel-related, or "NOT_TRAVEL" if it's not.
    """
  )
)

hotel_agent = create_agent(
  model=get_llm(),
  tools=[hotel_finder.find_hotels],
  system_prompt=(
    f"""
    You are a hotel search expert. Your job is to find hotels and estimate costs. Today is {_today}. Do not use dates in the past.
    Always return a list of hotels in the following strict JSON format (no text, no summary):
    [
      {{
        \"name\": \"...\",
        \"price_per_night\": ..., 
        \"review_count\": ..., 
        \"rating\": ..., 
        \"url\": \"...\"
      }}
    ]
    Do not include photos. Do not return any text or explanation, only the JSON list.
    """
  )
)

weather_agent = create_agent(
  model=get_llm(),
  tools=[weather_service.get_weather],
  system_prompt=(f"You are a weather expert. Your job is to fetch weather forecasts for the trip destination. Today is {_today}. Do not use dates in the past.")
)

attractions_agent = create_agent(
  model=get_llm(),
  tools=[attraction_finder.find_attractions, attraction_finder.estimate_attractions_cost, search_tool],
  system_prompt=(f"You are an attractions expert. Your job is to find attractions and estimate their costs. If you are routed back by the supervisor, you may use the search tool to look up the latest information. Today is {_today}. Do not use dates in the past.")
)

calculator_agent = create_agent(
  model=get_llm(),
  tools=[calculator.add, calculator.subtract, calculator.multiply, calculator.divide, currency_converter.convert, search_tool],
  system_prompt=(f"""
You are a calculator and budget allocation expert. Your job is to:
- Extract all costs you can find from the provided state (e.g., hotel prices, attraction costs, etc.).
- Split the user's budget by these costs and provide a clear breakdown.
- If you are missing any cost or are uncertain about a cost, you may use the search tool to look up the latest prices or estimates for any travel-related expense (e.g., food, transportation, tickets, etc.).
- Use the search tool whenever you feel it is necessary to allocate the budget accurately.
- If currency conversion is needed, use the currency conversion tool.
- Return a clear, itemized breakdown of all costs and any conversions performed.
Today is {_today}. Do not use dates in the past.
""")
)

# Node functions
class TravelEvaluationResult(BaseModel):
  result: Literal["TRAVEL", "NOT_TRAVEL"]

def router_travel_evaluator(state: WorkflowState) -> dict:
  """Check if query is travel-related. If not, end conversation."""
  print("\n---- TRAVEL EVALUATOR ----")
  user_msg = state.messages[-1].content
  result = travel_evaluator.invoke({"messages": [HumanMessage(content=str(user_msg))]})
  response = result['messages'][-1].content
  try:
    TravelEvaluationResult(result=response)
  except ValidationError:
    raise ValueError(f"Invalid travel evaluator output: {response}")
  return response

def node_query_analyzer(state: WorkflowState) -> Command:
  """Analyze the user message and extract trip info."""
  print("\n---- QUERY ANALYZER ----")
  user_msg = state.messages[-1].content
  result: QueryAnalysisResult = query_analyzer.analyze(str(user_msg))
  
  # Merge result into state
  for k, v in result.model_dump().items():
    setattr(state, k, v)
  
  print(f"Analysis result: {result.model_dump()}")
  return Command(goto="hotel_agent", update=state)

def node_hotel_agent(state: WorkflowState) -> Command:
  print("\n---- HOTEL AGENT ----")
  result = hotel_agent.invoke(state)
  raw_content = result['messages'][-1].content
  
  # Clean the output to remove signatures and tool calls
  clean_content = clean_agent_output(raw_content)
  
  try:
    if not clean_content or clean_content.strip() == "":
      print("Hotel agent returned empty content")
      state.hotels = []
    else:
      # Try to parse as JSON
      hotels_data = json.loads(clean_content.strip())
      hotels = [HotelInfo(**h) for h in hotels_data]
      state.hotels = hotels
      print("Hotels:")
      pprint.pprint(hotels)
  except (json.JSONDecodeError, ValidationError, TypeError) as e:
    print(f"Hotel agent error: {e}")
    print(f"Clean content received: {repr(clean_content)}")
    state.hotels = []
  return Command(goto="weather_agent", update=state)

def node_weather_agent(state: WorkflowState) -> Command:
  print("\n---- WEATHER AGENT ----")
  result = weather_agent.invoke({"messages": state.messages})
  weather_message = result['messages'][-1].content
    
  if isinstance(weather_message, List) and weather_message and 'text' in weather_message[0]:
      state.weather = weather_message[0]['text']
  else:
      state.weather = str(weather_message)
  print("Weather:")
  print(state.weather)
  return Command(goto="attractions_agent", update=state)

def node_attractions_agent(state: WorkflowState) -> Command:
  print("\n---- ATTRACTIONS AGENT ----")
  result = attractions_agent.invoke(state)
  attractions_message = result['messages'][-1]
  raw_content = attractions_message.content
  
  # Extract only the text content, ignore tool calls and signatures
  state.attractions = clean_agent_output(raw_content)
  
  print("Attractions found:")
  print(state.attractions)
  return Command(goto="calculator_agent", update=state)

def node_calculator_agent(state: WorkflowState) -> Command:
  print("\n---- CALCULATOR AGENT ----")
  result = calculator_agent.invoke(state)
  calculator_message = result['messages'][-1]
  raw_content = calculator_message.content
  
  # Extract only the text content, ignore tool calls and signatures
  state.calculator_result = clean_agent_output(raw_content)
  
  print("Calculator result:")
  print(state.calculator_result)
  return Command(goto="itinerary_agent", update=state)

def node_itinerary_agent(state: WorkflowState) -> Command:
  print("\n---- ITINERARY AGENT ----")
  itinerary = itinerary_builder.build(state)
  state.itinerary = itinerary
  print("Itinerary:")
  pprint.pprint(itinerary)
  return Command(goto="summary_agent", update=state)

def node_summary_agent(state: WorkflowState) -> Command:
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

workflow.add_edge("query_analyzer", "hotel_agent")
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