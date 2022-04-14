# frozen_string_literal: true
namespace :figgy do
  desc "updates rights statement to in_copyright for Map Resources with unknown copyright and campus-only access"
  task update_rights_statement: :environment do
    Migrations::MapCopyrightMigrator.call
  end
end
