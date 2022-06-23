# frozen_string_literal: true
def test_derivative_url(destination_name, format)
  path = File.join(Pathname.new(Dir.pwd), "tmp", "#{destination_name}.#{format}")
  URI("file://#{path}")
end
