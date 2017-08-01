# frozen_string_literal: true
module Figgy
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "config.yml"))).result, [], [], true)[Rails.env]
    end

    module_function :config, :config_yaml
end
