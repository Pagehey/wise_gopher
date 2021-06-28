# frozen_string_literal: true

module WiseGopher
  # Cast query columns and transform value
  class Column
    attr_reader :name, :type, :alias

    def initialize(name, type_symbol, after_cast: nil, as: nil)
      @alias       = as&.to_s || name.to_s
      @name        = name.to_s
      @type        = ActiveRecord::Type.lookup type_symbol
      @after_cast  = after_cast&.to_proc
    end

    def cast(value)
      casted_value = @type.deserialize(value)

      @after_cast ? transform_value(casted_value) : casted_value
    end

    def define_getter(row_class)
      column = self

      row_class.define_method(@alias) do
        instance_variable_get(column.instance_variable_name)
      end
    end

    def instance_variable_name
      @instance_variable_name ||= "@#{@alias.tr("?!", "")}".freeze
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
