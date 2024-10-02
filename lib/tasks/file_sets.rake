# frozen_string_literal: true
namespace :figgy do
  namespace :file_sets do
    desc "Delete all FileSets from a resource"
    task delete: :environment do
      resource_id = ENV["ID"]
      abort "usage: ID=id rake figgy:file_sets:delete" unless resource_id

      FileSetService.delete_all_from(resource_id)
    end
  end
end
