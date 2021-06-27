# frozen_string_literal: true

module WiseGopher
  # Register query's params and build query's bind variables
  class Param
    attr_reader :name, :type

    def initialize(name, type_symbol, before_cast = nil)
      @name        = name.to_s
      @type        = ActiveRecord::Type.lookup type_symbol
      @before_cast = before_cast&.to_proc
    end

    def build_bind(value)
      prepared_value = @before_cast ? transform_value(value) : value

      ActiveRecord::Relation::QueryAttribute.new(name, prepared_value, type)
    end

    private

    def transform_value(value)
      case @before_cast.arity
      when 0 then value.instance_exec(&@before_cast)
      else
        value.instance_eval(&@before_cast)
      end
    end
  end
end
