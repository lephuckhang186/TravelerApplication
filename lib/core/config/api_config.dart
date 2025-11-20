class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Expense endpoints
  static const String expensesEndpoint = '/expenses';
  static const String createTripEndpoint = '/expenses/trip/create';
  static const String createBudgetEndpoint = '/expenses/budget/create';
  static const String budgetStatusEndpoint = '/expenses/budget/status';
  static const String categoryStatusEndpoint = '/expenses/categories/status';
  static const String spendingTrendsEndpoint = '/expenses/analytics/trends';
  static const String expenseSummaryEndpoint = '/expenses/analytics/summary';
  static const String exportDataEndpoint = '/expenses/export';
  
  // Request headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Get headers with authorization token
  static Map<String, String> getAuthHeaders(String? token) => {
    ...defaultHeaders,
    if (token != null) 'Authorization': 'Bearer $token',
  };
}