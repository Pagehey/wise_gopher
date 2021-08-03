# frozen_string_literal: true

module WiseGopher
  # Base exception class
  class Error < StandardError; end

  # raised when `execute` is called whereas query needs params
  # or `execute_with` did not provide all params
  class ArgumentError < Error
    attr_reader :params

    def initialize(params)
      @params = params.map do |name, param|
        param_type = param.respond_to?(:type) ? param.type.type : :raw_param
        "- \"#{name}\" (#{param_type})"
      end.join("\n")
    end

    def message
      <<~STR
        \n
        The following params are required but were not provided:
        #{params}
      STR
    end
  end

  # raised when result contains more columns than declared
  class UndeclaredColumns < Error
    attr_reader :column_names

    def initialize(column_names)
      @column_names = column_names.map do |name|
        "- \"#{name}\""
      end.join("\n")
    end

    def message
      <<~STR
        \n
        The following columns where found in result but were not declared:
        #{column_names}

        If you need them during query execution but not in result,
        you should ignore them, like this:

        class Query < WiseGopher::Base
          query "SELECT title, rating FROM articles"

          row do
            column :title, :string
            ignore :rating
          end
        end
      STR
    end
  end

  # raised when row is not declared or not given
  class RowClassIsMissing < Error
  end

  # raised when custom row class is given but doesn't include WiseGopher::Row
  class RowClassNeedsRowModule < Error
  end

  # raised when param are raw_param are declared with the same name
  class ParamAlreadyDeclared < Error
    attr_reader :param_name

    def initialize(param_name)
      @param_name = param_name
    end

    def message
      "'#{param_name}' is already declared either as 'raw_param' or standard 'param'."
    end
  end
end
