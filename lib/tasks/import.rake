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

      abort "usage: rake import:json FILE=/path/to/file.json" unless file_path && File.file?(file_path)

      @logger = Logger.new(STDOUT)
      @logger.info "ingesting #{file_path}"

      ingester = JsonIngester.new(json_path: file_path, logger: @logger)
      ingester.ingest!
    end

    desc "Ingest a DSpace asset."
    task dspace: :environment do
      handle = ENV["HANDLE"]
      dspace_api_token = ENV["DSPACE_API_TOKEN"]

      abort "usage: rake import:dspace HANDLE=88435/dsp013t945q852 DSPACE_API_TOKEN=secret" unless handle

      @logger = Logger.new(STDOUT)
      @logger.info("Preparing to ingest Item #{handle} from DSpace...")

      ingester = DspaceIngester.new(handle: handle, logger: @logger, dspace_api_token: dspace_api_token)
      ingester.ingest!
    end

    desc "Ingest a DSpace collection."
    task dspace_collection: :environment do
      handle = ENV["HANDLE"]
      dspace_api_token = ENV["DSPACE_API_TOKEN"]

      abort "usage: rake import:dspace_collection HANDLE=88435/dsp013t945q852 DSPACE_API_TOKEN=secret" unless handle

      @logger = Logger.new(STDOUT)
      @logger.info("Preparing to ingest Collection #{handle} from DSpace...")

      ingester = DspaceCollectionIngester.new(handle: handle, logger: @logger, dspace_api_token: dspace_api_token)
      ingester.ingest!
    end

    desc "Ingest a DSpace community."
    task dspace_community: :environment do
      handle = ENV["HANDLE"]
      dspace_api_token = ENV["DSPACE_API_TOKEN"]

      abort "usage: rake import:dspace_community HANDLE=88435/dsp013t945q852 DSPACE_API_TOKEN=secret" unless handle

      @logger = Logger.new(STDOUT)
      @logger.info("Preparing to ingest Community #{handle} from DSpace...")

      ingester = DspaceCommunityIngester.new(handle: handle, logger: @logger, dspace_api_token: dspace_api_token)
      ingester.ingest!
    end
  end
end
