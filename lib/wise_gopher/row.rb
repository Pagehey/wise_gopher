# frozen_string_literal: true

module WiseGopher
  # This Module handles the declartion of row's columns of query result
  # and defines the getters for row objects
  module Row
    def self.included(base)
      base.class_eval do
        @columns         = {}
        @ignored_columns = []
      end

      base.extend(ClassMethods)
    end

    # Row class methods
    module ClassMethods
      attr_reader :columns, :ignored_columns

      def column(name, type, **kwargs)
        column = WiseGopher::Column.new(name, type, **kwargs)

        column.define_getter(self)

        columns[column.name] = column
      end

      def ignore(column_name)
        @ignored_columns << column_name.to_s.freeze
      end
    end

    def initialize(entry)
      self.class.columns.each do |name, column|
        variable_name = column.instance_variable_name.freeze

        instance_variable_set(variable_name, column.cast(entry[name]))
      end
    end
  end
end
