RSpec::Matchers.define :redirect_to_not_found do
  match do |actual|
    expect(actual).to redirect_to '/'
    expect(actual.flash["alert"]).to eq "The requested resource does not exist."
  end
end
