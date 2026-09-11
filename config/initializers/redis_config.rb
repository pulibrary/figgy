require "redis"
module RedisConfig
  def config
    @config ||= config_yaml
  end

  def url
    @url ||= "redis://#{config[:host]}:#{config[:port]}/#{config[:db]}"
  end

  # Added for testing, to unset variables.
  def reset!
    @config = nil
    @url = nil
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result, aliases: true, symbolize_names: true)[Rails.env.to_sym]
    end

    module_function :config, :url, :config_yaml, :reset!
end

RedisConfig.url
