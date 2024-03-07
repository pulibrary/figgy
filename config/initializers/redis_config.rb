# frozen_string_literal: true
module RedisConfig
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def url
    @url ||= "redis://#{config[:host]}:#{config[:port]}/#{config[:db]}"
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result, aliases: true)[Rails.env]
    end

    module_function :config, :url, :config_yaml
end

RedisConfig.url
