# frozen_string_literal: true
namespace :import do
  desc "Imports a resource from Plum"
  task plum: :environment do
    id = ENV['ID']
    abort "usage: rake import:plum ID=plumid" unless id

    PlumImporterJob.perform_later(id)
  end

  desc "Ingest a METS file."
  task mets: :environment do
    file = ENV['FILE']
    user = User.find_by_user_key(ENV['USER']) if ENV['USER']
    user = User.all.select(&:admin?).first unless user

    abort "usage: rake import:mets FILE=/path/to/file.mets [USER=aperson]" unless file && File.file?(file)

    @logger = Logger.new(STDOUT)
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    @logger.info "queuing job to ingest file: #{file}"

    IngestMETSJob.perform_later(file, user)
  end
end
