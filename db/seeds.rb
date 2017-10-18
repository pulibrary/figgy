# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with development data.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

# First, run rails server and sign in via CAS
# The first user will be promoted to an admin and used as the owner of all objects

unless User.count < 1
  seeder = DataSeeder.new
  seeder.wipe_metadata!
  seeder.wipe_files!
  UserUtils.promote_user_to_admin(user: User.first)
  seeder.generate_dev_data(many_members: 2, many_files: 3)
  seeder.generate_ephemera_project
end
