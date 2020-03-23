# frozen_string_literal: true
module PostGis
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def database
    @database ||= PostGis.config["database"]
  end

  def host
    @host ||= PostGis.config["host"]
  end

  def password
    @password ||= PostGis.config["password"]
  end

  def username
    @username ||= PostGis.config["username"]
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "postgis.yml"))).result, [], [], true)[Rails.env]
    end

    module_function :config, :config_yaml, :database, :host, :password, :username
end
