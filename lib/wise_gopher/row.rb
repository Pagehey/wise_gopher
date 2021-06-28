# frozen_string_literal: true

module WiseGopher
  # This Module handles the declartion of row's columns of query result
  # and defines the getters for row objects
  module Row
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def column(name, type, **kwargs)
        column = WiseGopher::Column.new(name, type, **kwargs)

        column.define_getter(self)

        columns[column.name] = WiseGopher::Column.new(name, type, **kwargs)
      end

      def columns
        @columns ||= {}
      end
    end

    def initialize(entry)
      self.class.columns.each do |name, column|
        variable_name = column.instance_variable_name

        instance_variable_set(variable_name, column.cast(entry[name]))
      end
    end
  end
end
