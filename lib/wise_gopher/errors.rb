# frozen_string_literal: true

module WiseGopher
  # Base exception class
  class Error < StandardError; end

  # raised when `execute` is called whereas query needs params
  # or `execute_with` did not provide all params
  class ParamsRequired < Error
    # TODO: list required params with their types
  end

  # raised when result contains more columns than declared
  class UndeclaredColumns < Error
    # TODO: list unceclared columns found in result
  end

  # raised when row is not declared or not given
  class RowClassIsMissing < Error
  end
end
