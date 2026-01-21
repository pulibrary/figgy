namespace :figgy do
  namespace :file_sets do
    desc "Delete all FileSets from a resource"
    task delete: :environment do
      resource_id = ENV["ID"]
      abort "usage: ID=id rake figgy:file_sets:delete" unless resource_id

      FileSetService.delete_all_from(resource_id)
    end

    desc "Delete all FileSets from all folders in the box"
    task delete_from_box: :environment do
      box_id = ENV["BOX_ID"]
      abort "usage: BOX_ID=id rake figgy:file_sets:delete_from_box" unless box_id

      query_service = Valkyrie.config.metadata_adapter.query_service
      box = query_service.find_by(id: box_id)
      box.decorate.member_ids.each do |folder_id|
        FileSetService.delete_all_from(folder_id)
      end
    end
  end
end
