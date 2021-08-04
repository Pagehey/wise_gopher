# frozen_string_literal: true

module WiseGopher
  # Register query's raw_params and interpolate string in query
  class RawParam
    attr_reader :name, :optional, :default, :prefix, :suffix

    def initialize(name, optional: false, default: nil, prefix: nil, suffix: nil)
      @name     = name.to_s.freeze
      @optional = optional
      @default  = default
      @prefix   = prefix.to_s.freeze
      @suffix   = suffix.to_s.freeze
    end

    def to_s(string = nil)
      raise ::ArgumentError, "value required" unless string || optional?

      content = string || default

      return "#{prefix}#{content}#{suffix}" if content

      ""
    end

    def optional?
      optional || !!default
    end
  end
end
