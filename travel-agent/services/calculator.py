from langchain.tools import tool

class Calculator:
    """
    Simple calculator for basic arithmetic operations.
    """
    @staticmethod
    @tool
    def add(a: int, b: int) -> int:
        """
        Add two integers.

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
        Multiply two integers.

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
        Divide two integers.

        Args:
            a (int): The numerator.
            b (int): The denominator (must not be 0).

        Returns:
            float: The result of division.
        """
        if b == 0:
            raise ValueError("Denominator cannot be zero.")
        return a / b

    @staticmethod
    @tool
    def subtract(a: int, b: int) -> int:
        """
        Subtract two integers.

        Args:
            a (int): The first integer.
            b (int): The second integer.

        Returns:
            int: The subtraction of a and b.
        """
        return a - b