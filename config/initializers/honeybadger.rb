# frozen_string_literal: true

# Errors for honeybadger to ignore.
# https://docs.honeybadger.io/ruby/getting-started/ignoring-errors.html#ignore-programmatically
Honeybadger.configure do |config|
  config.before_notify do |notice|
    # Ignore Shapefile encoding errors.
    if notice.error_message =~ /ogr2ogr -q -nln/
      notice.halt!
    end
  end
end
