# frozen_string_literal: true
namespace :migrate do
  desc "Migrate users in group image_editor to group staff"
  task image_editor: :environment do
    staff = Role.where(name: "staff").first_or_create

    User.all.select { |u| u.roles.map(&:name).include?("image_editor") }.each do |u|
      u.roles = u.roles.select { |role| role.name != "image_editor" }
      u.roles << staff
      u.save
    end
  end
end
