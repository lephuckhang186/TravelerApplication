import requests
from typing import Dict, Any
from langchain.tools import tool

class CurrencyConverter:
  """
  A tool to convert currencies using public APIs with fallback.
  """

  @staticmethod
  @tool
  def convert(amount: float, from_currency: str, to_currency: str) -> Dict[str, Any]:
    """
    Converts a given amount from one currency to another using a public API.

    Args:
      amount (float): The amount of money to convert.
      from_currency (str): The currency code to convert from (e.g., 'USD').
      to_currency (str): The currency code to convert to (e.g., 'EUR').

    Returns:
      Dict[str, Any]: Dictionary with converted amount, rate, from, to, and amount.

    Raises:
      ValueError: If conversion fails or API is unavailable.
    """
    try:
      url = f"https://api.exchangerate-api.com/v4/latest/{from_currency.upper()}"
      resp = requests.get(url, timeout=10)
      resp.raise_for_status()
      data = resp.json()
      rates = data.get("rates", {})
      if to_currency.upper() not in rates:
        raise ValueError(f"Currency {to_currency} not supported")
      rate = rates[to_currency.upper()]
      converted_amount = amount * rate
      return {
        "converted_amount": round(converted_amount, 2),
        "rate": rate,
        "from": from_currency.upper(),
        "to": to_currency.upper(),
        "amount": amount
      }
    except Exception as e:
      # Fallback to another public API
      try:
        url = f"https://open.er-api.com/v6/latest/{from_currency.upper()}"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        rates = data.get("rates", {})
        if to_currency.upper() not in rates:
          raise ValueError(f"Currency {to_currency} not supported (fallback)")
        rate = rates[to_currency.upper()]
        converted_amount = amount * rate
        return {
          "converted_amount": round(converted_amount, 2),
          "rate": rate,
          "from": from_currency.upper(),
          "to": to_currency.upper(),
          "amount": amount
        }
      except Exception as e2:
        raise ValueError(f"Currency conversion failed: {str(e2)}")