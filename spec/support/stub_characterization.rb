RSpec.configure do |config|
  config.before(:each) do |ex|
    unless ex.metadata[:run_real_characterization]
      allow_any_instance_of(Vips::Image).to receive(:width).and_return(200)
      allow_any_instance_of(Vips::Image).to receive(:height).and_return(287)
      allow_any_instance_of(ImagemagickCharacterizationService).to receive(:mime_type).and_return("image/tiff")
      allow_any_instance_of(ImagemagickCharacterizationService).to receive(:file_size).and_return("196882")
    end
  end
end
