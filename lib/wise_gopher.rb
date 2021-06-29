# frozen_string_literal: true

require_relative "wise_gopher/version"
require_relative "wise_gopher/base"
require_relative "wise_gopher/column"
require_relative "wise_gopher/param"
require_relative "wise_gopher/row"
require_relative "wise_gopher/errors"

require "active_record"

# base module
module WiseGopher
  def self.postgresql?
    ActiveRecord::Base.connection.adapter_name.casecmp? "PostgreSQL"
  end
end
