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

    desc "Ingest a DSpace collection."
    task dspace_collection: :environment do
      # Ingestion for DataSpace Collections with Items mapped to Figgy ScannedResources
      # Example: https://dataspace.princeton.edu/handle/88435/dsp016q182k16g
      # Example: https://dataspace.princeton.edu/handle/88435/dsp01bg257f09p
      #
      # @param HANDLE [String] the DSpace handle of the collection to ingest.
      #   Example: 88435/dsp016q182k16g.
      handle = ENV["HANDLE"]
      # @param DSPACE_API_TOKEN [String] the DSpace API token for authentication against the REST API
      dspace_api_token = ENV["DSPACE_API_TOKEN"]
      # @param COLLECTION [String] the collection ID in Figgy to which the DSpace collection will be ingested
      collection = ENV["COLLECTION"]

      # Optional arguments
      # @param DELETE_PREEXISTING [Boolean] whether to delete preexisting items in the collection before ingesting
      delete_preexisting = false
      if "DELETE_PREEXISTING" in ENV
        delete_preexisting = ENV["DELETE_PREEXISTING"].casecmp("true").zero?
      end

      abort "usage: rake import:dspace_collection HANDLE=88435/dsp013t945q852 COLLECTION=COLLECTION DSPACE_API_TOKEN=secret" unless handle && collection
      collections = [collection]

      @logger = Logger.new(STDOUT)
      @logger.info("Preparing to ingest Collection #{handle} from DSpace...")

      IngestDspaceAssetJob.perform_later(
        handle: handle,
        dspace_api_token: dspace_api_token,
        member_of_collection_ids: collections,
        delete_preexisting: delete_preexisting,
        ingest_service_klass: DspaceCollectionIngester
      )
    end

    desc "Ingest a YAML list of DSpace collections as multi-volume works."
    task dspace_mvw_collections: :environment do
      # Ingestion for DataSpace Collections with Items mapped to Figgy Multivolume Work ScannedResources
      # Example: https://dataspace.princeton.edu/handle/88435/dsp01kh04dp74g
      # Example: https://dataspace.princeton.edu/handle/88435/dsp01r781wg06f
      #
      # @param CONFIG_FILE [String] the path to the YAML file containing the list of DSpace collection URIs
      # Example: config/dataspace_serials_public.yml
      # Example: config/dataspace_serials_restricted.yml
      config_file = ENV["CONFIG_FILE"]
      # @param DSPACE_API_TOKEN [String] the DSpace API token for authentication against the REST API
      dspace_api_token = ENV["DSPACE_API_TOKEN"]
      # @param COLLECTION [String] the collection ID in Figgy to which the DSpace collection will be ingested
      collection = ENV["COLLECTION"]

      # Optional arguments
      # @param DELETE_PREEXISTING [Boolean] whether to delete preexisting items in the collection before ingesting
      delete_preexisting = false
      if ENV.key?("DELETE_PREEXISTING")
        delete_preexisting = ENV["DELETE_PREEXISTING"].casecmp("true").zero?
      end

      abort "usage: rake import:dspace_mvw_collection CONFIG_FILE=config/dataspace_mvws.yml COLLECTION=COLLECTION DSPACE_API_TOKEN=secret" unless config_file && collection

      uris = YAML.load_file(config_file)
      collections = [collection]
      @logger = Logger.new(STDOUT)

      uris.each do |uri|
        handle = uri.gsub("https://dataspace.princeton.edu/handle/", "")

        @logger.info("Enqueuing the job to ingest Collection #{handle} from DSpace...")

        IngestDspaceAssetJob.perform_later(
          handle: handle,
          dspace_api_token: dspace_api_token,
          member_of_collection_ids: collections,
          delete_preexisting: delete_preexisting,
          ingest_service_klass: DspaceMultivolumeIngester
        )
      end
    end
  end
end
