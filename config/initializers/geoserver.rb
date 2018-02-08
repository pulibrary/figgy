# frozen_string_literal: true
module GeoServer
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  private

    def config_yaml
      file = Rails.root.join('config', 'geoserver.yml')
      YAML.safe_load(ERB.new(File.read(file)).result)['geoserver']
    end

    module_function :config, :config_yaml
end
