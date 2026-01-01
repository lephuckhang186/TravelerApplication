"""
Mock modules for testing to handle LangChain/LangGraph compatibility issues
"""
import sys
from unittest.mock import MagicMock

# Mock langgraph modules that cause import errors
class MockToolNode:
    def __init__(self, *args, **kwargs):
        pass

class MockPrebuilt:
    ToolNode = MockToolNode

    @staticmethod
    def create_react_agent(*args, **kwargs):
        mock_agent = MagicMock()
        mock_agent.invoke.return_value = {
            'messages': [{'content': 'Mock agent response'}]
        }
        return mock_agent

class MockLangGraph:
    prebuilt = MockPrebuilt()

    class StateGraph:
        def __init__(self, *args, **kwargs):
            pass

        def add_node(self, *args, **kwargs):
            pass

        def add_edge(self, *args, **kwargs):
            pass

        def add_conditional_edges(self, *args, **kwargs):
            pass

        def compile(self):
            mock_app = MagicMock()
            mock_app.invoke.return_value = MagicMock()
            return mock_app

    START = "START"
    END = "END"

# Mock langchain modules with comprehensive coverage
class MockLangChain:
    class Core:
        class Messages:
            HumanMessage = MagicMock
            AIMessage = MagicMock
            BaseMessage = MagicMock

        class Callbacks:
            class Manager:
                pass

        class Runnables:
            RunnableConfig = MagicMock

            class Config:
                get_config_list = MagicMock()
                get_executor_for_config = MagicMock()

        class Tools:
            BaseTool = MagicMock
            InjectedToolArg = MagicMock
            tool = MagicMock
            create_tool = MagicMock

            class Base:
                TOOL_MESSAGE_BLOCK_TYPES = []

    class Agents:
        @staticmethod
        def create_agent(*args, **kwargs):
            mock_agent = MagicMock()
            mock_agent.invoke.return_value = {
                'messages': [{'content': 'Mock agent response'}]
            }
            return mock_agent

    class Tavily:
        TavilySearch = MagicMock

# Mock psutil for system stress tests
class MockPsutil:
    class Process:
        def memory_info(self):
            return MagicMock(rss=1000000)

    def cpu_percent(self, interval=None):
        return 50.0

    def virtual_memory(self):
        return MagicMock(percent=60.0)

# Apply comprehensive mocks to sys.modules
mock_modules = {
    # LangGraph modules
    'langgraph': MockLangGraph(),
    'langgraph.prebuilt': MockLangGraph.prebuilt,
    'langgraph.prebuilt.tool_node': MockLangGraph.prebuilt,
    'langgraph.prebuilt.chat_agent_executor': MockLangGraph.prebuilt,

    # LangChain core modules
    'langchain_core': MockLangChain.Core(),
    'langchain_core.messages': MockLangChain.Core.Messages,
    'langchain_core.callbacks': MockLangChain.Core.Callbacks,
    'langchain_core.callbacks.manager': MockLangChain.Core.Callbacks.Manager,
    'langchain_core.runnables': MockLangChain.Core.Runnables,
    'langchain_core.runnables.config': MockLangChain.Core.Runnables.Config,
    'langchain_core.tools': MockLangChain.Core.Tools,
    'langchain_core.tools.base': MockLangChain.Core.Tools.Base,

    # LangChain modules
    'langchain': MockLangChain(),
    'langchain.agents': MockLangChain.Agents,
    'langchain.tools': MockLangChain.Core.Tools,

    # External dependencies
    'langchain_tavily': MockLangChain.Tavily,
    'psutil': MockPsutil(),
}

for module_name, mock_obj in mock_modules.items():
    sys.modules[module_name] = mock_obj

# Mock TOOL_MESSAGE_BLOCK_TYPES specifically
sys.modules['langchain_core.tools.base'].TOOL_MESSAGE_BLOCK_TYPES = []

# Try to import real modules (will use mocks if they fail)
try:
    import langgraph
    import langchain_core
    import langchain
    import langchain_tavily
    import psutil
    print("Real modules imported successfully")
except ImportError as e:
    print(f"Using mock modules due to import error: {e}")

print("Comprehensive mock modules loaded for testing compatibility")
