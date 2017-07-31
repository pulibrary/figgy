module Features
  # Provides methods for login and logout within Feature Tests
  module SessionHelpers
    # Use this in feature tests
    def sign_in(who = :user)
      user = if who.instance_of?(User)
               who.uid
             else
               FactoryGirl.create(:user).uid
             end
      OmniAuth.config.add_mock(:cas, uid: user)
      visit user_cas_omniauth_authorize_path
    end
  end
end
RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
end
