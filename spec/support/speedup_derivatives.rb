RSpec.configure do |config|
  config.before(:each) do |ex|
    unless ex.metadata[:run_real_derivatives]
      example_file = Rails.root.join("spec", "fixtures", "files", "example.tif")
      allow(Hydra::Derivatives::Jpeg2kImageDerivatives).to receive(:create) do |*args|
        url = args[1][:outputs][0][:url].to_s.gsub("file:", "")
        FileUtils.link(example_file, url, force: true)
      end
    end
  end
end
