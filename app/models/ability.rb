# frozen_string_literal: true
class Ability
  include Valhalla::Ability
  # Define any customized permissions here.
  def custom_permissions
    return unless current_user.admin?
    can :manage, Valkyrie::Resource if current_user.admin?
    can :manage, Role
  end
end
