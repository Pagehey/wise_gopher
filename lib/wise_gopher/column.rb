# frozen_string_literal: true

module WiseGopher
  # Cast query columns and transform value
  class Column
    attr_reader :name, :type, :column_name

    def initialize(column_name, type_symbol, after_cast: nil, as: nil)
      @name        = as&.to_s || column_name.to_s
      @column_name = column_name.to_s
      @type        = ActiveRecord::Type.lookup type_symbol
      @alias       = as
      @after_cast  = after_cast&.to_proc
    end

    def cast(value)
      casted_value = @type.deserialize(value)

      @after_cast ? transform_value(casted_value) : casted_value
    end

    private

    def transform_value(value)
      case @after_cast.arity
      when 0 then value.instance_exec(&@after_cast)
      else
        value.instance_eval(&@after_cast)
      end
    end
  end
end
