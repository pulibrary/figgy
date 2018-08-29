# frozen_string_literal: true
namespace :import do
  desc "Re-run characterization for an object"
  task recharacterize: :environment do
    id = ENV["ID"]
    abort "usage: rake import:recharacterize ID=plumid" unless id

    RecharacterizeJob.set(queue: :low).perform_later(id)
  end

  desc "Ingest a METS file."
  task mets: :environment do
    file = ENV["FILE"]
    user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
    user = User.all.select(&:admin?).first unless user
<<<<<<< HEAD
    import_mods = ENV["IMPORT_MODS"] && ENV["IMPORT_MODS"].casecmp("TRUE").zero?

    abort "usage: rake import:mets FILE=/path/to/file.mets [USER=aperson] [IMPORT_MODS=TRUE]" unless file && File.file?(file)
=======

    abort "usage: rake import:mets FILE=/path/to/file.mets [USER=aperson]" unless file && File.file?(file)
>>>>>>> d8616123... adds lux order manager to figgy

    @logger = Logger.new(STDOUT)
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    @logger.info "queuing job to ingest file: #{file}"

<<<<<<< HEAD
    IngestMETSJob.set(queue: :low).perform_later(file, user, import_mods)
=======
    IngestMETSJob.set(queue: :low).perform_later(file, user)
>>>>>>> d8616123... adds lux order manager to figgy
  end
end
