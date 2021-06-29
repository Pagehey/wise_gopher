# frozen_string_literal: true

require "forwardable"

module WiseGopher
  # Main inteface of the gem. Class to be inherited by the query class
  class Base
    def self.inherited(base)
      base.class_eval do
        @params = {}
      end
      base.include Methods
      base.extend  ClassMethods
    end

    # class methods for WiseGopher::Base
    module ClassMethods
      attr_reader :row_class, :params

      def query(query)
        const_set "QUERY", query.freeze
      end

      def param(name, type, before_cast = nil)
        param = WiseGopher::Param.new(name, type, before_cast)

        params[param.name] = param
      end

      def row(base = nil, &block)
        @row_class ||= base || define_generic_row_class

        @row_class.include WiseGopher::Row

        @row_class.instance_exec(&block) if block_given?
      end

      def execute
        new.execute
      end

      def execute_with(inputs)
        ensure_all_params_are_given(inputs)

        new(inputs).execute
      end

      private

      def define_generic_row_class
        @row_class = const_set "Row", Class.new
      end

      def ensure_all_params_are_given(inputs)
        missing_params = params.keys - inputs.keys.map(&:to_s)

        raise WiseGopher::ArgumentError, params.slice(*missing_params) if missing_params.any?
      end
    end

    # instance methods for WiseGopher::Base
    module Methods
      extend ::Forwardable

      def_delegator :query_class, :row_class

      def initialize(inputs = {})
        @inputs         = inputs
        @binds          = []
        @bind_symbol    = WiseGopher.postgresql? ? +"$1" : "?"
        @query_prepared = false

        prepare_query
      end

      def execute
        ensure_row_class_is_declared

        result = connection.exec_query(@query.squish, query_class.to_s, @binds)

        ensure_all_columns_are_declared(result)

        result.entries.map { |entry| row_class.new(entry) }
      end

      def prepare_query
        return if @query_prepared

        @query = query_class::QUERY.dup

        query_class.params.each do |name, param|
          name  = name.to_sym
          value = @inputs[name]

          bind_params(value, param)
        end

        @query_prepared = true
      end

      private

      def query_class
        self.class
      end

      def bind_params(value, param)
        if value.is_a? Array
          bind_collection_param(value, param)
        else
          bind_single_param(value, param)
        end
      end

      def bind_collection_param(values, param)
        bindings = values.map { use_bind_symbol }

        replace_binding_placeholder(param.name, bindings.join(", "))

        values.each { |value| register_binding(value, param) }
      end

      def bind_single_param(value, param)
        replace_binding_placeholder(param.name, use_bind_symbol)

        register_binding(value, param)
      end

      def replace_binding_placeholder(name, binding_symbol)
        @query.gsub!(/{{ ?#{name} ?}}/, binding_symbol)
      end

      def register_binding(value, param)
        @binds << param.build_bind(value)
      end

      def use_bind_symbol
        if WiseGopher.postgresql?
          symbol = @bind_symbol.dup

          @bind_symbol.next!

          symbol
        else
          @bind_symbol
        end
      end

      def ensure_row_class_is_declared
        raise RowClassIsMissing unless row_class
      end

      def ensure_all_columns_are_declared(result)
        undeclared_columns = result.columns - row_class.columns.keys - row_class.ignored_columns

        raise UndeclaredColumns, undeclared_columns if undeclared_columns.any?
      end

      def connection
        ActiveRecord::Base.connection
      end
    end
  end
end
