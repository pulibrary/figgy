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
  seeder.generate_dev_data(mvw_volumes: 4, many_files: 3, sammel_files: 2, sammel_vols: 2)
  seeder.generate_ephemera_project
  seeder.generate_ephemera_project(project: EphemeraProject.new(title: "Boxless Ephemera Project", slug: "boxless-project"), n_boxes: 0)
  seeder.generate_collection
end
