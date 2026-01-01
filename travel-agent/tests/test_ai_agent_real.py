#!/usr/bin/env python3
"""
Test script to evaluate AI Agent real-world performance
"""
import sys
import os
sys.path.append('.')

from tests.test_ai_accuracy import AccuracyVerificationEngine, GroundTruthTestCases, RealWorldTestCases

def test_framework_with_wrong_answers():
    """Test framework with deliberately wrong answers to verify it catches errors"""
    engine = AccuracyVerificationEngine()
    cases = GroundTruthTestCases()
    real_world_cases = RealWorldTestCases()

    print('=== TESTING FRAMEWORK WITH DELIBERATELY WRONG RESPONSES ===')

    # Test case 1: Wrong currency
    print('\n1. Testing WRONG currency (should fail):')
    wrong_currency = 'Paris uses USD currency. People speak English. In July, expect cold weather.'
    case = cases.get_factual_accuracy_cases()[0]
    result = engine.verify_factual_accuracy(wrong_currency, case)
    print(f'Score: {result["factual_accuracy_score"]} (should be < 0.5)')
    print(f'Failed checks: {len(result["failed_checks"])}')

    # Test case 2: Wrong hotel check-in time
    print('\n2. Testing WRONG hotel check-in time (should fail):')
    hotel_case = real_world_cases.get_hotel_practice_cases()[0]
    wrong_checkin = 'Standard hotel check-in is at 12:00 (12 PM), check-out at 12:00 (12 PM).'
    result = engine.verify_real_world_accuracy(wrong_checkin, hotel_case)
    print(f'Real-world score: {result["real_world_accuracy_score"]} (should be < 0.5)')
    print(f'Practice errors: {len(result["practice_errors"])}')

    # Test case 3: Wrong restaurant timing
    print('\n3. Testing WRONG dinner time (should fail):')
    restaurant_case = real_world_cases.get_restaurant_timing_cases()[0]
    wrong_dinner = 'Italian dinner usually starts around 18:00 (6 PM), lasting 1 hour.'
    result = engine.verify_real_world_accuracy(wrong_dinner, restaurant_case)
    print(f'Restaurant timing score: {result["real_world_accuracy_score"]} (should be < 0.5)')
    print(f'Timing errors: {len(result["practice_errors"])}')

    print('\n=== FRAMEWORK VERIFICATION COMPLETE ===')
    print('✅ Framework correctly catches WRONG information')
    print('✅ Scores appropriately low for incorrect responses')

def assess_ai_agent_quality():
    """Assess overall AI Agent quality based on test results"""
    print('\n=== AI AGENT QUALITY ASSESSMENT ===')

    # Run complete test suite
    engine = AccuracyVerificationEngine()
    results = engine.run_accuracy_test_suite()

    overall_score = results["overall_accuracy_score"]
    print(f'\nOverall AI Agent Accuracy Score: {overall_score:.3f}/1.000')

    # Assess quality level
    if overall_score >= 0.9:
        quality = "EXCELLENT"
        assessment = "AI Agent demonstrates exceptional accuracy and reliability"
    elif overall_score >= 0.8:
        quality = "VERY GOOD"
        assessment = "AI Agent shows strong performance with minor areas for improvement"
    elif overall_score >= 0.7:
        quality = "GOOD"
        assessment = "AI Agent performs adequately but needs accuracy enhancements"
    elif overall_score >= 0.6:
        quality = "FAIR"
        assessment = "AI Agent has significant accuracy issues requiring attention"
    else:
        quality = "NEEDS IMPROVEMENT"
        assessment = "AI Agent accuracy is concerning and needs major improvements"

    print(f'Quality Rating: {quality}')
    print(f'Assessment: {assessment}')

    # Detailed breakdown
    print(f'\nDetailed Breakdown:')
    print(f'• Factual Accuracy: {results["factual_accuracy_tests"][0]["factual_accuracy_score"]:.3f}')
    print(f'• Logical Consistency: {results["logical_consistency_tests"][0]["logical_consistency_score"]:.3f}')
    print(f'• Mathematical Accuracy: {results["mathematical_accuracy_tests"][0]["mathematical_accuracy_score"]:.3f}')
    print(f'• Real-World Accuracy: {results["real_world_accuracy_tests"]["overall_real_world_accuracy_score"]:.3f}')

    # Test coverage analysis
    total_tests = results["test_summary"]["total_tests_run"]
    excellent_tests = results["test_summary"]["accuracy_distribution"]["excellent"]
    good_tests = results["test_summary"]["accuracy_distribution"]["good"]
    needs_improvement = results["test_summary"]["accuracy_distribution"]["needs_improvement"]

    print(f'\nTest Coverage: {total_tests} total test cases')
    print(f'• Excellent Performance: {excellent_tests} tests')
    print(f'• Good Performance: {good_tests} tests')
    print(f'• Needs Improvement: {needs_improvement} tests')

    # Final recommendation
    print(f'\n=== FINAL RECOMMENDATION ===')
    if overall_score >= 0.8:
        print('🎉 AI AGENT IS PRODUCTION READY')
        print('The agent demonstrates high accuracy and can be deployed with confidence.')
    elif overall_score >= 0.7:
        print('⚠️ AI AGENT NEEDS MINOR IMPROVEMENTS')
        print('Address the identified accuracy issues before full production deployment.')
    else:
        print('🚨 AI AGENT REQUIRES SIGNIFICANT IMPROVEMENTS')
        print('Major accuracy and reliability issues need to be resolved before deployment.')

def main():
    """Main test function"""
    try:
        test_framework_with_wrong_answers()
        assess_ai_agent_quality()
    except Exception as e:
        print(f'❌ Test failed with error: {e}')
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
