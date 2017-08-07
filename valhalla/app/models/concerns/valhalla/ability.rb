# frozen_string_literal: true
module Valhalla
  module Ability
    extend ActiveSupport::Concern
    included do
      include Hydra::Ability

      def read_permissions
        super
        can :read, Valkyrie::Resource do |obj|
          valkyrie_test_read(obj) || valkyrie_test_edit(obj)
        end
      end

      def edit_permissions
        super
        can [:edit, :update, :destroy], Valkyrie::Resource do |obj|
          valkyrie_test_edit(obj)
        end
      end

      def valkyrie_test_read(obj)
        group_readable?(obj) || user_readable?(obj)
      end

      def group_readable?(obj)
        (user_groups & obj.read_groups).any?
      end

      def user_readable?(obj)
        obj.read_users.include?(current_user.user_key)
      end

      def valkyrie_test_edit(obj)
        group_editable?(obj) || user_editable?(obj)
      end

      def group_editable?(obj)
        (user_groups & obj.edit_groups).any?
      end

      def user_editable?(obj)
        obj.edit_users.include?(current_user.user_key)
      end
    end
  end
end
