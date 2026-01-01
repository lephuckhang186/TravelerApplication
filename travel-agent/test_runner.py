#!/usr/bin/env python3
"""
Test Runner với logging chi tiết cho Travel Agent
Tạo file log dễ hiểu cho người không biết code
"""

import os
import sys
import unittest
import json
from datetime import datetime
from pathlib import Path
import traceback
import inspect
import re

class DetailedTestLogger:
    """Logger chi tiết cho test results"""

    def __init__(self, log_file="test_results.log"):
        self.log_file = log_file
        self.test_results = []
        self.current_test = None

    def log_test_start(self, test_name, test_class, test_doc=None):
        """Bắt đầu log một test"""
        self.current_test = {
            "test_name": test_name,
            "test_class": test_class,
            "description": test_doc or "Không có mô tả",
            "start_time": datetime.now().isoformat(),
            "inputs": [],
            "outputs": [],
            "assertions": [],
            "status": "running",
            "error": None
        }

    def log_input(self, input_data, description=""):
        """Log input data"""
        if self.current_test:
            self.current_test["inputs"].append({
                "data": str(input_data),
                "description": description,
                "timestamp": datetime.now().isoformat()
            })

    def log_output(self, output_data, description=""):
        """Log output data"""
        if self.current_test:
            self.current_test["outputs"].append({
                "data": str(output_data),
                "description": description,
                "timestamp": datetime.now().isoformat()
            })

    def log_assertion(self, assertion_desc, expected, actual, passed=True):
        """Log assertion result"""
        if self.current_test:
            self.current_test["assertions"].append({
                "description": assertion_desc,
                "expected": str(expected),
                "actual": str(actual),
                "passed": passed,
                "timestamp": datetime.now().isoformat()
            })

    def log_test_end(self, status="passed", error=None):
        """Kết thúc log test"""
        if self.current_test:
            self.current_test["status"] = status
            self.current_test["end_time"] = datetime.now().isoformat()
            if error:
                self.current_test["error"] = {
                    "message": str(error),
                    "traceback": traceback.format_exc()
                }
            self.test_results.append(self.current_test)
            self.current_test = None

    def save_log(self):
        """Lưu log ra file"""
        log_data = {
            "run_timestamp": datetime.now().isoformat(),
            "total_tests": len(self.test_results),
            "passed": len([t for t in self.test_results if t["status"] == "passed"]),
            "failed": len([t for t in self.test_results if t["status"] == "failed"]),
            "errors": len([t for t in self.test_results if t["status"] == "error"]),
            "test_results": self.test_results
        }

        with open(self.log_file, 'w', encoding='utf-8') as f:
            json.dump(log_data, f, ensure_ascii=False, indent=2)

    def generate_human_readable_log(self):
        """Tạo file log dễ đọc cho người không biết code"""
        readable_log = f"tests/TEST_RESULTS_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

        with open(readable_log, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("KẾT QUẢ KIỂM TRA HỆ THỐNG TRAVEL AGENT\n")
            f.write("=" * 80 + "\n\n")

            f.write(f"Thời gian chạy: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n")
            f.write(f"Tổng số test: {len(self.test_results)}\n")
            f.write(f"Test thành công: {len([t for t in self.test_results if t['status'] == 'passed'])}\n")
            f.write(f"Test thất bại: {len([t for t in self.test_results if t['status'] == 'failed'])}\n")
            f.write(f"Test lỗi: {len([t for t in self.test_results if t['status'] == 'error'])}\n\n")

            for i, test in enumerate(self.test_results, 1):
                f.write("-" * 60 + "\n")
                f.write(f"TEST #{i}: {test['test_class']}.{test['test_name']}\n")
                f.write("-" * 60 + "\n\n")

                f.write(f"MO TA: {test['description']}\n\n")

                if test['inputs']:
                    f.write("INPUTS (Du lieu dau vao):\n")
                    for j, inp in enumerate(test['inputs'], 1):
                        f.write(f"  {j}. {inp['description']}\n")
                        f.write(f"     Du lieu: {inp['data']}\n\n")

                if test['outputs']:
                    f.write("OUTPUTS (Ket qua):\n")
                    for j, out in enumerate(test['outputs'], 1):
                        f.write(f"  {j}. {out['description']}\n")
                        f.write(f"     Ket qua: {out['data']}\n\n")

                if test['assertions']:
                    f.write("KIEM TRA (Assertions):\n")
                    for j, assertion in enumerate(test['assertions'], 1):
                        status = "PASS" if assertion['passed'] else "FAIL"
                        f.write(f"  {j}. [{status}] {assertion['description']}\n")
                        f.write(f"     Mong doi: {assertion['expected']}\n")
                        f.write(f"     Thuc te: {assertion['actual']}\n\n")

                # Status
                if test['status'] == 'passed':
                    f.write("KET QUA: THANH CONG\n")
                elif test['status'] == 'failed':
                    f.write("KET QUA: THAT BAI\n")
                else:
                    f.write("KET QUA: LOI\n")

                if test['error']:
                    f.write("CHI TIET LOI:\n")
                    f.write(f"   {test['error']['message']}\n\n")

                f.write("\n")

        return readable_log

class VerboseTestResult(unittest.TextTestResult):
    """Custom TestResult class để capture chi tiết"""

    def __init__(self, stream, descriptions, verbosity, logger):
        super().__init__(stream, descriptions, verbosity)
        self.logger = logger

    def startTest(self, test):
        super().startTest(test)
        # Extract test info
        test_method = test._testMethodName
        test_class = test.__class__.__name__

        # Get docstring
        test_doc = getattr(test, test_method).__doc__ or ""

        self.logger.log_test_start(test_method, test_class, test_doc.strip())

        # Analyze test method source to extract inputs/outputs
        self._analyze_test_method(test)

    def _analyze_test_method(self, test):
        """Phân tích test method để extract inputs và operations"""
        try:
            method = getattr(test, test._testMethodName)
            source = inspect.getsource(method)

            # Extract variable assignments và operations
            self._extract_test_operations(source)

        except Exception as e:
            # Nếu không thể analyze, bỏ qua
            pass

    def _extract_test_operations(self, source):
        """Extract operations từ test source code"""
        lines = source.split('\n')

        for line in lines:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('"""'):
                continue

            # Extract variable assignments
            var_match = re.match(r'^(\w+)\s*=\s*(.+)$', line)
            if var_match:
                var_name, value = var_match.groups()
                if not var_name.startswith('_'):
                    self.logger.log_input(value.strip(), f"Thiết lập biến: {var_name}")

            # Extract assert statements
            if line.startswith('self.assert'):
                self._extract_assertion_info(line)

    def _extract_assertion_info(self, assert_line):
        """Extract thông tin từ assert statement"""
        # Simple extraction - có thể cải thiện
        if 'assertEqual' in assert_line:
            # self.assertEqual(result, expected)
            parts = assert_line.replace('self.assertEqual(', '').replace(')', '').split(',')
            if len(parts) >= 2:
                actual = parts[0].strip()
                expected = parts[1].strip()
                self.logger.log_assertion(f"Kiểm tra {actual} bằng {expected}", expected, actual)

        elif 'assertTrue' in assert_line:
            condition = assert_line.replace('self.assertTrue(', '').replace(')', '').strip()
            self.logger.log_assertion(f"Kiểm tra {condition} là True", "True", condition)

        elif 'assertGreater' in assert_line:
            parts = assert_line.replace('self.assertGreater(', '').replace(')', '').split(',')
            if len(parts) >= 2:
                first = parts[0].strip()
                second = parts[1].strip()
                self.logger.log_assertion(f"Kiểm tra {first} > {second}", f">{second}", first)

    def addSuccess(self, test):
        super().addSuccess(test)
        self.logger.log_test_end("passed")

    def addError(self, test, err):
        super().addError(test, err)
        error_msg = str(err[1])
        self.logger.log_test_end("error", error_msg)

    def addFailure(self, test, err):
        super().addFailure(test, err)
        error_msg = str(err[1])
        self.logger.log_test_end("failed", error_msg)

def run_tests_with_detailed_logging():
    """Chạy tất cả test với logging chi tiết"""

    # Thêm thư mục travel-agent vào Python path
    travel_agent_path = Path(__file__).parent
    sys.path.insert(0, str(travel_agent_path))

    print("DANG KHOI DONG TEST RUNNER VOI LOGGING CHI TIET...")
    print("Thu muc test: travel-agent/tests/")
    print("File log se duoc tao: test_results.log va TEST_RESULTS_*.txt")
    print()

    logger = DetailedTestLogger()

    try:
        # Discover tất cả test files
        test_loader = unittest.TestLoader()
        test_suite = unittest.TestSuite()

        # Load tests từ thư mục tests
        tests_dir = Path("travel-agent/tests")
        if not tests_dir.exists():
            tests_dir = Path("tests")
        if tests_dir.exists():
            for test_file in tests_dir.glob("test_*.py"):
                try:
                    # Import module
                    module_name = f"tests.{test_file.stem}"
                    module = __import__(module_name, fromlist=[test_file.stem])

                    # Load tests từ module
                    suite = test_loader.loadTestsFromModule(module)
                    test_suite.addTest(suite)

                except Exception as e:
                    print(f"WARNING: Khong the load test tu {test_file}: {e}")
                    continue
        else:
            print("ERROR: Thu muc travel-agent/tests khong ton tai!")
            return 1

        if test_suite.countTestCases() == 0:
            print("WARNING: Khong tim thay test nao!")
            return 1

        # Chạy tests với custom result class
        test_runner = unittest.TextTestRunner(
            resultclass=lambda stream, descriptions, verbosity: VerboseTestResult(stream, descriptions, verbosity, logger),
            verbosity=2,
            stream=sys.stdout
        )

        print(f"Da tim thay {test_suite.countTestCases()} test cases\n")

        # Chạy tests
        result = test_runner.run(test_suite)

        # Lưu logs
        logger.save_log()
        readable_log = logger.generate_human_readable_log()

        print("\n" + "="*80)
        print("HOAN THANH CHAY TEST")
        print("="*80)
        print(f"File log JSON: {logger.log_file}")
        print(f"File log de doc: {readable_log}")
        print()
        print("THONG KE:")
        print(f"   Tong so test: {len(logger.test_results)}")
        print(f"   Thanh cong: {len([t for t in logger.test_results if t['status'] == 'passed'])}")
        print(f"   That bai: {len([t for t in logger.test_results if t['status'] == 'failed'])}")
        print(f"   Loi: {len([t for t in logger.test_results if t['status'] == 'error'])}")

        # Trả về exit code
        if result.wasSuccessful():
            return 0
        else:
            return 1

    except Exception as e:
        print(f"LOI khi chay test: {e}")
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    exit_code = run_tests_with_detailed_logging()
    sys.exit(exit_code)
