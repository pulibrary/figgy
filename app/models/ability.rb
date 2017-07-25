# frozen_string_literal: true
class Ability
  include Valhalla::Ability
  # Define any customized permissions here.
  def custom_permissions
    can :manage, Valkyrie::Resource if current_user.admin?
  end
end
