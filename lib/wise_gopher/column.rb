# frozen_string_literal: true

module WiseGopher
  # Cast query columns and transform value
  class Column
    attr_reader :name, :type, :alias

    def initialize(name, type_symbol, transform: nil, as: nil)
      @alias     = as&.to_s.freeze || name.to_s.freeze
      @name      = name.to_s.freeze
      @type      = ActiveRecord::Type.lookup type_symbol
      @transform = transform&.to_proc
    end

    def cast(value)
      casted_value = @type.deserialize(value)

      @transform ? transform_value(casted_value) : casted_value
    end

    def define_getter(row_class)
      column = self

      row_class.define_method(@alias) do
        instance_variable_get(column.instance_variable_name)
      end
    end

    def instance_variable_name
      @instance_variable_name ||= "@#{@alias.tr("?!", "")}"
    end

    private

    def transform_value(value)
      case @transform.arity
      when 0 then value.instance_exec(&@transform)
      else
        value.instance_eval(&@transform)
      end
    end
  end
end
