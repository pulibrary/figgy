RSpec.configure do |config|
  config.before(:each) do |ex|
    if ex.metadata[:skip_fixity]
      allow_any_instance_of(LocalFixityJob).to receive(:perform).and_return(true)
    end
  end
end

