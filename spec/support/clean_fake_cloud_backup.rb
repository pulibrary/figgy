RSpec.configure do |config|
  config.before(:each) do
    FileUtils.rm_rf(Figgy.config["disk_preservation_path"])
  end
end
