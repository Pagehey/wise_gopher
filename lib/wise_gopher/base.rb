# frozen_string_literal: true

require "forwardable"

module WiseGopher
  # Main inteface of the gem. Class to be inherited by the query class
  class Base
    def self.inherited(child_class)
      parent_class = self
      child_class.extend ClassMethods
      child_class.set_defaults

      # if child_class is already a WiseGopher::Base
      child_class.ancestors.include?(Methods) && child_class.class_eval do
        @raw_params = parent_class.raw_params.deep_dup
        @params = parent_class.params.deep_dup
        @row_class = parent_class.row_class
      end

      child_class.include Methods
    end

    # class methods for WiseGopher::Base
    module ClassMethods
      attr_reader :row_class, :params, :raw_params

      def query(query)
        const_set "QUERY", query.freeze
      end

      def param(name, type, transform = nil)
        new_param = WiseGopher::Param.new(name, type, transform)

        ensure_param_name_is_available(new_param.name)

        params[new_param.name] = new_param
      end

      def raw_param(name, **kwargs)
        raw_param = WiseGopher::RawParam.new(name, **kwargs)

        ensure_param_name_is_available(raw_param.name)

        raw_params[raw_param.name] = raw_param
      end

      def row(base = nil, &block)
        @row_class ||= base || define_generic_row_class

        @row_class.include WiseGopher::Row unless @row_class.ancestors.include?(WiseGopher::Row)

        @row_class.class_eval(&block) if block_given?
      end

      def execute
        ensure_all_params_are_given

        new.execute
      end

      def execute_with(inputs)
        ensure_all_params_are_given(inputs)

        new(inputs).execute
      end

      def ensure_all_params_are_given(inputs = {})
        missing_params = required_params.keys - inputs.keys.map(&:to_s)

        raise WiseGopher::ArgumentError, required_params.slice(*missing_params) if missing_params.any?
      end

      def set_defaults
        @raw_params = {}
        @params = {}
      end

      private

      def define_generic_row_class
        @row_class = const_set "Row", Class.new
      end

      def ensure_param_name_is_available(name)
        return unless params[name] || raw_params[name]

        raise WiseGopher::ParamAlreadyDeclared, name
      end

      def required_params
        params.merge(raw_params.reject { |_name, raw_param| raw_param.optional? })
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

        self.class.ensure_all_params_are_given(inputs)

        prepare_query
      end

      def execute
        ensure_row_class_is_declared

        result = connection.exec_query(query.squish, query_class.to_s, @binds, prepare: true)

        ensure_all_columns_are_declared(result)

        result.entries.map { |entry| row_class.new(entry) }
      end

      def prepare_query
        return if @query_prepared

        prepare_raw_params

        prepare_params

        @query_prepared = true
      end

      private

      def prepare_params
        query_class.params.each do |name, param|
          name  = name.to_sym
          value = @inputs[name]

          bind_params(value, param)
        end
      end

      def query_class
        self.class
      end

      def query
        @query ||= query_class::QUERY.dup
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

        replace_placeholder(param.name, bindings.join(", "))

        values.each { |value| register_binding(value, param) }
      end

      def bind_single_param(value, param)
        replace_placeholder(param.name, use_bind_symbol)

        register_binding(value, param)
      end

      def replace_placeholder(name, value_to_insert)
        query.gsub!(/{{ ?#{name} ?}}/, value_to_insert)
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

      def prepare_raw_params
        query_class.raw_params.each do |name, param|
          name  = name.to_sym
          value = @inputs[name]

          replace_placeholder(name, param.to_s(value))
        end
      end
    end
  end
end
