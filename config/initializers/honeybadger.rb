# frozen_string_literal: true

# Errors for honeybadger to ignore.
# https://docs.honeybadger.io/ruby/getting-started/ignoring-errors.html#ignore-programmatically
Honeybadger.exception_filter do |notice|
  notice[:error_message] =~ /ogr2ogr -q -nln/ # Shapefile encoding errors.
end
