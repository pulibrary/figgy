RSpec.configure do |config|
  config.before(:each) do
    stub_request(:get, "https://bibdata.princeton.edu/locations/digital_locations.json").
      to_return(
        status: 200,
        body: File.read(Rails.root.join("spec", "fixtures", "files", "holding_locations.json")),
        headers: {"Content-Type" => "application/json" }
    )
  end
end
