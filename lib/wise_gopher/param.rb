# frozen_string_literal: true

module WiseGopher
  # Register query's params and build query's bind variables
  class Param
    attr_reader :name, :type

    def initialize(name, type_symbol, transform = nil)
      @name      = name.to_s.freeze
      @type      = ActiveRecord::Type.lookup type_symbol
      @transform = transform&.to_proc
    end

    def build_bind(value)
      prepared_value = @transform ? transform_value(value) : value

      ActiveRecord::Relation::QueryAttribute.new(name, prepared_value, type)
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
