# frozen_string_literal: true
module Figgy
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def messaging_client
    @messaging_client ||= MessagingClient.new(Figgy.config["events"]["server"])
  end

  def geoblacklight_messaging_client
    @geoblacklight_messaging_client ||= GeoblacklightMessagingClient.new(Figgy.config["events"]["server"])
  end

  def geoserver_messaging_client
    @geoserver_messaging_client ||= GeoserverMessagingClient.new(Figgy.config["events"]["server"])
  end

  def orangelight_messaging_client
    @orangelight_messaging_client ||= OrangelightMessagingClient.new(Figgy.config["events"]["server"])
  end

  def default_url_options
    @default_url_options ||= ActionMailer::Base.default_url_options
  end

  def campus_ip_ranges
    @campus_ip_ranges ||= config[:access_control][:campus_ip_ranges].map { |str| IPAddr.new(str) }
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "config.yml"))).result, [], [], true)[Rails.env]
    end

    module_function :config, :config_yaml, :messaging_client, :geoblacklight_messaging_client, :geoserver_messaging_client, :orangelight_messaging_client, :default_url_options, :campus_ip_ranges
end
