# frozen_string_literal: true

# Errors for honeybadger to ignore.
# https://docs.honeybadger.io/ruby/getting-started/ignoring-errors.html#ignore-programmatically
Honeybadger.configure do |config|
  config.exceptions.ignore += ["MosaicJob::JobRunning"]
  config.before_notify do |notice|
    # Ignore Shapefile encoding errors.
    if /ogr2ogr -q -nln/.match?(notice.error_message)
      notice.halt!
    end
  end
end
