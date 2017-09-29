# frozen_string_literal: true
namespace :lae do
  desc "Ingest one or more LAE folders"
  task ingest: :environment do
    folder_dir = ARGV[1]
    project = ENV['PROJECT']

    abort "usage: PROJECT=projectlabel rake lae:ingest /path/to/lae/folder" unless Dir.exist?(folder_dir) && project.present?
    IngestEphemeraJob.perform_later(folder_dir, project)
  end
end
