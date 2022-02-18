# frozen_string_literal: true

module Figgy
  def read_only_mode
    @read_only_mode ||= ENV.fetch("FIGGY_READ_ONLY_MODE", false) == "true"
  end

  module_function :read_only_mode
end
