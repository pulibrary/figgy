# frozen_string_literal: true
namespace :figgy do
  namespace :geniza do
    desc "Consolidate a Geniza item into a mvw"
    task consolidate_to_mvws: :environment do
      csvfile = ENV["CSV"]

      abort "usage: CSV=csvfile rake geniza:consolidate_to_mvws" unless csvfile

      geniza_colid = "d878ac93-2237-4731-a815-79ff46450e32"
      db = Valkyrie::MetadataAdapter.find(:indexing_persister)
      files = Valkyrie.config.storage_adapter
      csp = ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files)

      # read the csv into hash keyed by item
      items = Hash.new { |hsh, key| hsh[key] = [] }
      CSV.foreach(csvfile, headers: true, header_converters: :symbol) do |row|
        items[row[:item]] << row
      end

      items.each do |_item, rows|
        leaves = rows.sort_by { |row| row[:leaf].to_i }
        title = "#{leaves.first[:lib]} #{leaves.first[:item]}"
        member_ids = []
        leaves.each do |l|
          obj = db.query_service.find_by(id: l[:id])
          member_ids << obj.id
          cs = ChangeSet.for(obj)
          cs.validate(member_of_collection_ids: [])
          csp.save(change_set: cs)
        end
        cs = ChangeSet.for(ScannedResource.new(title: title,
                                               member_of_collection_ids: [geniza_colid]))
        cs.validate(member_ids: member_ids)
        csp.save(change_set: cs)
      end
    end

    desc "fix ids"
    task fix_ids: :environment do
      geniza_colid = "d878ac93-2237-4731-a815-79ff46450e32"
      db = Valkyrie::MetadataAdapter.find(:indexing_persister)
      files = Valkyrie.config.storage_adapter
      csp = ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files)

      to_be_changed = db.query_service.custom_queries.find_by_property(property: :member_of_collection_ids, value: geniza_colid)
      to_be_changed.each do |obj|
        puts "changing #{obj.title.first}"
        cs = ChangeSet.for(obj)
        cs.validate(member_of_collection_ids: Array(Valkyrie::ID.new(geniza_colid)))
        csp.save(change_set: cs)
        puts "changed #{obj.title.first}"
      end
    end

    desc "add id"
    task add_id: :environment do
      geniza_colid = "d878ac93-2237-4731-a815-79ff46450e32"
      ena_shelfmarkid = "538ec700-268e-4a9a-adde-32c90ca76cfe"
      db = Valkyrie::MetadataAdapter.find(:indexing_persister)
      files = Valkyrie.config.storage_adapter
      csp = ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files)

      geniza = db.query_service.find_by(id: geniza_colid)
      geniza.decorate.members.each do |obj|
        shelfmark = obj.title.first
        next unless shelfmark.start_with?("ENA ")
        cs = ChangeSet.for(obj)
        cs.member_of_collection_ids << Valkyrie::ID.new(ena_shelfmarkid)
        csp.save(change_set: cs)
        puts "added #{obj.title.first} to ENA shelfmark collection"
      end
    end
  end
end
