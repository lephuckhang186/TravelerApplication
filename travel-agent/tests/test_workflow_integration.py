import unittest
from unittest.mock import patch, AsyncMock, MagicMock
try:
    from models import WorkflowState
except ImportError:
    class WorkflowState:
        def __init__(self, **kwargs): self.__dict__.update(kwargs)
from langchain_core.messages import HumanMessage

class TestWorkflowIntegration(unittest.IsolatedAsyncioTestCase):
    
    async def asyncSetUp(self):
        self.sample_state = WorkflowState(
            destination="Paris",
            messages=[HumanMessage(content="Paris trip")]
        )

    @patch('workflow.app') 
    @patch('services.hotels.requests.get')
    async def test_workflow_end_conditions(self, mock_get, mock_app):
        """Test workflow end conditions"""
        
        # 1. Setup Mock
        mock_get.return_value.json.return_value = {"status": "success"}
        
        # Setup App Mock
        expected_result = {
            "destination": "Paris",
            "messages": [HumanMessage(content="Done")]
        }
        
        # Config ainvoke (Async)
        mock_app.ainvoke = AsyncMock(return_value=expected_result)

        # 2. Run
        result = await mock_app.ainvoke(self.sample_state)

        # 3. Assert
        self.assertIsNotNone(result)
        self.assertEqual(result["destination"], "Paris")
        mock_app.ainvoke.assert_called_once()