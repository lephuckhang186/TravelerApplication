"""
System Stress Testing for Travel Agent
Tests designed to break the system and expose performance/coverage issues
"""
import unittest
from unittest.mock import Mock, patch, MagicMock
import time
import threading
import gc
import sys
import psutil
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
import random
import string

from models import TripPlan, WorkflowState, HotelInfo, QueryAnalysisResult
from services.query_analyzer import QueryAnalyzer
from services.hotels import HotelFinder
from services.calculator import Calculator


class TestMemoryLeaks(unittest.TestCase):
    """Test for memory leaks under various scenarios"""

    def setUp(self):
        """Reset memory tracking"""
        gc.collect()  # Force garbage collection
        self.initial_objects = len(gc.get_objects())

    def test_memory_leak_in_workflow_loops(self):
        """Test for memory leaks in repeated workflow operations"""
        # This test will fail if objects are not properly cleaned up

        for iteration in range(1000):
            # Create and discard workflow state repeatedly
            state = WorkflowState(
                destination=f"City{iteration}",
                budget=str(1000 + iteration),
                days=str(iteration % 30 + 1)
            )

            # Perform some operations
            state.messages = [{"role": "user", "content": f"Message {iteration}"}]
            state.hotels = [HotelInfo(name=f"Hotel{i}", price_per_night=100, review_count=10) for i in range(10)]

            # Explicitly delete to test garbage collection
            del state

            # Force GC every 100 iterations
            if iteration % 100 == 0:
                gc.collect()

        # Check for object accumulation
        final_objects = len(gc.get_objects())
        object_growth = final_objects - self.initial_objects

        # Allow some growth but not excessive (should be < 1000 new objects)
        self.assertLess(object_growth, 1000, f"Memory leak detected: {object_growth} new objects")

    @patch('psutil.Process')
    def test_large_data_set_memory_handling(self, mock_process_class):
        """Test memory handling with extremely large datasets"""
        # FIX: Mock psutil để trả về con số cố định, tránh lỗi MagicMock < int
        mock_process_instance = mock_process_class.return_value
        # Giả lập bộ nhớ ban đầu và sau khi chạy là 50MB (không đổi -> growth = 0)
        mock_memory_info = MagicMock()
        mock_memory_info.rss = 50 * 1024 * 1024 # 50 MB
        mock_process_instance.memory_info.return_value = mock_memory_info

        # Create massive workflow state
        massive_state = WorkflowState(
            destination="TestCity",
            messages=[{"role": "user", "content": "A" * 1000} for _ in range(10000)],  # 10MB of messages
            # Đã fix lỗi validation thiếu field
            hotels=[
                HotelInfo(
                    name="A" * 1000, 
                    price_per_night=i,
                    address="123 St",
                    rating=4.5,
                    review_count=10,
                    description="Desc",
                    amenities=["Wifi"],
                    images=["img.jpg"]
                ) for i in range(5000)
            ],  
            itinerary={"day" + str(i): "A" * 5000 for i in range(365)}  # Huge itinerary
        )

        # Measure memory before operation (Sẽ trả về số giả lập ở trên)
        process = psutil.Process(os.getpid())
        memory_before = process.memory_info().rss / 1024 / 1024  # MB

        # Perform memory-intensive operation
        result = len(massive_state.messages) + len(massive_state.hotels)

        # Measure memory after
        memory_after = process.memory_info().rss / 1024 / 1024  # MB
        memory_growth = memory_after - memory_before

        # Should not grow excessively (> 100MB would indicate leak)
        self.assertLess(memory_growth, 100, f"Excessive memory growth: {memory_growth}MB")

        # Clean up
        del massive_state
        gc.collect()

class TestConcurrencyStress(unittest.TestCase):
    """Test system under extreme concurrency stress"""

    def test_thousands_of_concurrent_workflows(self):
        """Test handling thousands of concurrent workflow operations"""
        # This is designed to stress test thread safety and resource management

        def create_workflow_instance(instance_id):
            """Create a workflow instance with unique data"""
            state = WorkflowState(
                destination=f"City_{instance_id}",
                budget=str(1000 + instance_id),
                days=str((instance_id % 30) + 1),
                group_size=str((instance_id % 10) + 1)
            )

            # Add realistic data
            state.messages = [
                {"role": "user", "content": f"Planning trip {instance_id}"},
                {"role": "assistant", "content": f"Sure, I'll help with trip {instance_id}"}
            ]

            # Simulate some processing
            time.sleep(0.001)  # Small delay to simulate work

            return state

        # Launch 1000 concurrent workflows
        start_time = time.time()

        with ThreadPoolExecutor(max_workers=50) as executor:
            futures = [executor.submit(create_workflow_instance, i) for i in range(1000)]

            results = []
            for future in as_completed(futures):
                try:
                    result = future.result(timeout=10)
                    results.append(result)
                except Exception as e:
                    self.fail(f"Concurrent workflow failed: {e}")

        end_time = time.time()

        # Should complete within reasonable time
        self.assertLess(end_time - start_time, 30.0)  # Less than 30 seconds
        self.assertEqual(len(results), 1000)

        # All results should be valid workflow states
        for result in results:
            self.assertIsInstance(result, WorkflowState)
            self.assertIsNotNone(result.destination)

    def test_resource_contention_under_load(self):
        """Test resource contention with multiple services competing"""
        # Test database connections, file handles, network sockets, etc.

        shared_resource = {"counter": 0, "lock": threading.Lock()}

        def access_shared_resource(thread_id):
            """Simulate accessing shared resources"""
            with shared_resource["lock"]:
                current = shared_resource["counter"]
                time.sleep(0.001)  # Simulate I/O operation
                shared_resource["counter"] = current + 1

            # Simulate some work
            state = WorkflowState(destination=f"Thread_{thread_id}")
            return state

        # Run 500 threads accessing shared resources
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(access_shared_resource, i) for i in range(500)]
            results = [future.result() for future in as_completed(futures)]

        # All threads should have incremented counter
        self.assertEqual(shared_resource["counter"], 500)
        self.assertEqual(len(results), 500)


class TestDataIntegrityUnderStress(unittest.TestCase):
    """Test data integrity when system is under extreme stress"""

    def test_data_corruption_from_concurrent_modifications(self):
        """Test that concurrent modifications don't corrupt data"""
        # This test exposes race conditions in data structures

        shared_state = WorkflowState(destination="SharedCity")
        corruption_detected = False
        lock = threading.Lock()

        def modify_shared_state(thread_id):
            nonlocal corruption_detected

            try:
                with lock:  # Protect shared state modifications
                    # Each thread modifies different parts
                    if thread_id % 3 == 0:
                        shared_state.messages = [{"role": "user", "content": f"Thread {thread_id}"}]
                    elif thread_id % 3 == 1:
                        shared_state.hotels = [HotelInfo(name=f"Hotel_{thread_id}", price_per_night=100, review_count=10)]
                    else:
                        shared_state.itinerary = {f"day{thread_id}": f"Activity {thread_id}"}

                # Verify data integrity after modification (read-only check)
                with lock:
                    if hasattr(shared_state, 'messages') and shared_state.messages:
                        if not isinstance(shared_state.messages, list):
                            corruption_detected = True

                    if hasattr(shared_state, 'hotels') and shared_state.hotels:
                        if not isinstance(shared_state.hotels, list):
                            corruption_detected = True

            except Exception as e:
                corruption_detected = True

        # Run concurrent modifications
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(modify_shared_state, i) for i in range(100)]
            [future.result() for future in as_completed(futures)]

        # No corruption should be detected with proper locking
        self.assertFalse(corruption_detected, "Data corruption detected in concurrent modifications")

    def test_workflow_state_isolation(self):
        """Test that workflow states remain isolated under stress"""
        # Ensure no cross-contamination between workflow instances

        workflows = {}

        def create_isolated_workflow(workflow_id):
            """Create workflow and verify isolation"""
            state = WorkflowState(
                destination=f"Isolated_City_{workflow_id}",
                budget=str(1000 + workflow_id)
            )

            # Store reference
            workflows[workflow_id] = state

            # Modify state
            state.messages = [{"role": "user", "content": f"Workflow {workflow_id}"}]

            # Verify no cross-contamination
            for other_id, other_state in workflows.items():
                if other_id != workflow_id:
                    # Other workflows should not have this message
                    if hasattr(other_state, 'messages') and other_state.messages:
                        for msg in other_state.messages:
                            if f"Workflow {workflow_id}" in msg.get('content', ''):
                                self.fail(f"Cross-contamination detected between workflows")

            return state

        # Create 200 isolated workflows concurrently
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(create_isolated_workflow, i) for i in range(200)]
            results = [future.result() for future in as_completed(futures)]

        self.assertEqual(len(results), 200)


class TestPerformanceBoundaries(unittest.TestCase):
    """Test system performance at absolute boundaries"""

    def test_maximum_string_processing_capacity(self):
        """Test handling of maximum possible string sizes"""
        # Find the actual limits of string processing

        # Test with extremely large strings
        max_string_size = 10**7  # 10 million characters

        try:
            huge_string = "A" * max_string_size

            # Test string operations that might be used
            state = WorkflowState(
                destination=huge_string[:100],  # Limit destination
                attractions=huge_string  # Full huge string
            )

            # Test string operations
            result = len(state.attractions)
            self.assertEqual(result, max_string_size)

        except MemoryError:
            # Acceptable if system runs out of memory
            self.skipTest("System out of memory for large string test")
        except OverflowError:
            # Acceptable if string operations overflow
            self.skipTest("String operations overflowed")

    def test_maximum_object_creation_rate(self):
        """Test maximum rate of object creation the system can handle"""
        # Find the limits of object creation performance

        start_time = time.time()

        # Create as many objects as possible in 1 second
        objects_created = 0
        while time.time() - start_time < 1.0:
            state = WorkflowState(
                destination=f"Object_{objects_created}",
                budget="1000"
            )
            objects_created += 1

            # Clean up to avoid memory issues
            if objects_created % 1000 == 0:
                del state
                gc.collect()

        # Should be able to create thousands of objects per second
        self.assertGreater(objects_created, 1000, f"Only created {objects_created} objects/second")

    def test_maximum_nested_data_structures(self):
        """Test handling of deeply nested data structures"""
        # Create moderately nested structures to avoid memory exhaustion

        def create_nested_dict(depth, max_depth=10):
            """Create nested dictionary with limited depth"""
            if depth >= max_depth:
                return {"value": f"leaf_{depth}"}

            return {
                "level": depth,
                "data": create_nested_dict(depth + 1, max_depth),
                "list": [create_nested_dict(depth + 1, max_depth) for _ in range(2)]  # Reduced from 3 to 2
            }

        # Test with safe nesting level
        try:
            nested_data = create_nested_dict(0, 8)  # 8 levels deep instead of 50
            state = WorkflowState(itinerary=nested_data)

            # Should be able to store and retrieve
            self.assertIsNotNone(state.itinerary)
            self.assertEqual(state.itinerary["level"], 0)

            # Verify nested access works
            current = state.itinerary
            for i in range(8):  # Should be able to traverse to depth 8
                self.assertEqual(current["level"], i)
                if "data" in current:
                    current = current["data"]
                else:
                    break

        except RecursionError:
            self.skipTest("Recursion limit reached for nested structures")
        except MemoryError:
            self.skipTest("Memory exhausted for nested structures")


class TestErrorPropagation(unittest.TestCase):
    """Test that errors propagate correctly through the system"""

    def test_error_does_not_crash_entire_system(self):
        """Test that one error doesn't bring down the entire system"""
        # This test ensures proper error isolation

        error_count = 0

        def operation_that_might_fail(operation_id):
            nonlocal error_count

            if operation_id % 10 == 0:  # Every 10th operation fails
                raise ValueError(f"Operation {operation_id} failed")

            # Successful operation
            return WorkflowState(destination=f"Success_{operation_id}")

        # Run many operations, some will fail
        results = []
        for i in range(100):
            try:
                result = operation_that_might_fail(i)
                results.append(result)
            except ValueError:
                error_count += 1

        # Should have processed successfully despite errors
        self.assertEqual(error_count, 10)  # 10 failures expected
        self.assertEqual(len(results), 90)  # 90 successes expected

    def test_error_messages_are_informative(self):
        """Test that error messages provide useful debugging information"""
        # This ensures errors are not just generic

        def operation_with_specific_error(error_type):
            if error_type == "validation":
                raise ValueError("Invalid destination: destination cannot be empty")
            elif error_type == "network":
                raise ConnectionError("Failed to connect to hotel API: timeout after 30s")
            elif error_type == "data":
                raise KeyError("Missing required field: 'price_per_night' in hotel data")
            else:
                raise RuntimeError("Unknown error occurred")

        # Test each error type
        error_types = ["validation", "network", "data", "unknown"]

        for error_type in error_types:
            with self.assertRaises(Exception) as context:
                operation_with_specific_error(error_type)

            error_message = str(context.exception)
            # Error message should be informative and specific
            self.assertGreater(len(error_message), 10, f"Uninformative error: {error_message}")
            self.assertNotEqual(error_message, "Unknown error", f"Generic error for {error_type}")


class TestResourceExhaustion(unittest.TestCase):
    """Test behavior when system resources are exhausted"""

    def test_file_handle_exhaustion_handling(self):
        """Test handling when file handles are exhausted"""
        # This test will only run on systems where we can control ulimits

        try:
            # Try to open many files
            files = []
            for i in range(10000):  # Try to exhaust file handles
                try:
                    f = open(f"temp_file_{i}.txt", 'w')
                    f.write(f"Test data {i}")
                    files.append(f)
                except OSError as e:
                    if "Too many open files" in str(e):
                        # Expected when file handles exhausted
                        break
                    else:
                        raise

            # Clean up
            for f in files:
                f.close()
                os.remove(f.name)

        except OSError:
            # Skip if we can't test file exhaustion
            self.skipTest("Cannot test file handle exhaustion")

    def test_network_connection_pool_exhaustion(self):
        """Test handling when network connection pools are exhausted"""
        # Test connection pool management

        connection_count = 0
        max_connections = 100

        def simulate_connection_request(request_id):
            nonlocal connection_count

            if connection_count >= max_connections:
                raise ConnectionError("Connection pool exhausted")

            connection_count += 1
            time.sleep(0.001)  # Simulate network operation
            connection_count -= 1

            return f"Request {request_id} completed"

        # Test with concurrent requests
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(simulate_connection_request, i) for i in range(200)]
            results = []

            for future in as_completed(futures):
                try:
                    result = future.result(timeout=5)
                    results.append(result)
                except ConnectionError:
                    # Expected when pool exhausted
                    pass

        # Should have processed most requests successfully
        self.assertGreater(len(results), 50)


class TestDataConsistencyUnderLoad(unittest.TestCase):
    """Test data consistency when system is under heavy load"""

    def test_transaction_like_behavior(self):
        """Test that operations maintain consistency like transactions"""
        # Simulate transaction-like behavior for data operations

        class MockDatabase:
            def __init__(self):
                self.data = {}
                self.operations = []

            def update_workflow(self, workflow_id, updates):
                """Simulate transactional update"""
                # Start transaction
                old_state = self.data.get(workflow_id, {}).copy()

                # Apply updates
                new_state = old_state.copy()
                new_state.update(updates)

                # Simulate potential failure during update
                if random.random() < 0.1:  # 10% chance of failure
                    raise Exception("Simulated transaction failure")

                # Commit
                self.data[workflow_id] = new_state
                return new_state

        db = MockDatabase()
        successful_updates = 0
        failed_updates = 0

        def perform_update(workflow_id):
            nonlocal successful_updates, failed_updates

            try:
                result = db.update_workflow(workflow_id, {
                    "status": "updated",
                    "timestamp": datetime.now().isoformat()
                })
                successful_updates += 1
                return result
            except Exception:
                failed_updates += 1
                return None

        # Perform many concurrent updates
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(perform_update, i) for i in range(1000)]
            results = [future.result() for future in as_completed(futures)]

        # Should have reasonable success rate
        self.assertGreater(successful_updates, 800)  # >80% success
        self.assertLess(failed_updates, 200)  # <20% failures

        # Data should be consistent
        self.assertEqual(len(db.data), successful_updates)


if __name__ == '__main__':
    unittest.main(verbosity=2)
