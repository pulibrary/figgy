# frozen_string_literal: true
namespace :figgy do
  namespace :import do
    desc "Re-run characterization for an object"
    task recharacterize: :environment do
      id = ENV["ID"]
      abort "usage: rake import:recharacterize ID=figgyid" unless id

      RecharacterizeJob.set(queue: :low).perform_later(id)
    end

    desc "Ingest a METS file."
    task mets: :environment do
      file = ENV["FILE"]
      user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
      user = User.all.find(&:admin?) unless user
      import_mods = ENV["IMPORT_MODS"]&.casecmp("TRUE")&.zero?

      abort "usage: rake import:mets FILE=/path/to/file.mets [USER=aperson] [IMPORT_MODS=TRUE]" unless file && File.file?(file)

      @logger = Logger.new(STDOUT)
      @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
      @logger.info "queuing job to ingest file: #{file}"

      IngestMETSJob.set(queue: :low).perform_later(file, user, import_mods)
    end

    desc "Ingest a JSON file."
    task json: :environment do
      file_path = ENV["FILE"]
      user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
      user = User.all.find(&:admin?) unless user

      abort "usage: rake import:json FILE=/path/to/file.json [USER=person]" unless file_path && File.file?(file_path)

      @logger = Logger.new(STDOUT)
      @logger.info "ingesting #{file_path} as: #{user.user_key} (override with USER=foo)"

      class_name = "ScannedResource"
      filters = [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]

      data = JSON.parse(File.read(file_path))
      logger.info "ingesting #{data['records'].length} records"
      data["records"].each do |record|
        attrs = record.map { |k, v| [k.to_sym, v] }.to_h
        dir = attrs.delete(:path)
        colls = Array(attrs.delete(:member_of_collection_ids))
        logger.info "ingesting #{attrs[:title]}"
        IngestFolderJob.perform_now(
          directory: dir,
          class_name: class_name,
          member_of_collection_ids: colls,
          file_filters: filters,
          **attrs
        )
        logger.info "done ingesting #{attrs[:title]}"
      end
    end
  end
end
