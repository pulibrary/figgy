# frozen_string_literal: true
require 'redis'
config = YAML.safe_load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result, [], [], true)[Rails.env].with_indifferent_access
Redis.current = Redis.new(config.merge(thread_safe: true))
