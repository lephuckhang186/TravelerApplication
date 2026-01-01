from langchain.tools import tool

class Calculator:
    """
    Simple calculator for basic arithmetic operations.

    This tool is provided to the agent to perform deterministic mathematical calculations,
    ensuring accuracy in budget and itinerary planning.
    """
    @staticmethod
    @tool
    def add(a: int, b: int) -> int:
        """
        Adds two integers.

        Args:
            a (int): The first integer.
            b (int): The second integer.

        Returns:
            int: The sum of a and b.
        """
        return a + b

    @staticmethod
    @tool
    def multiply(a: int, b: int) -> int:
        """
        Multiplies two integers.

        Args:
            a (int): The first integer.
            b (int): The second integer.

        Returns:
            int: The product of a and b.
        """
        return a * b

    @staticmethod
    @tool
    def divide(a: int, b: int) -> float:
        """
        Divides two integers.

        Args:
            a (int): The numerator.
            b (int): The denominator (must not be 0).

        Returns:
            float: The result of division.

        Raises:
            ValueError: If the denominator is zero.
        """
        if b == 0:
            raise ValueError("Denominator cannot be zero.")
        return a / b

    @staticmethod
    @tool
    def subtract(a: int, b: int) -> int:
        """
        Subtracts two integers.

        Args:
            a (int): The first integer.
            b (int): The second integer.

        Returns:
            int: The subtraction of b from a.
        """
        return a - b