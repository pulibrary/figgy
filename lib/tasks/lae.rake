# frozen_string_literal: true
namespace :figgy do
  namespace :lae do
    desc "Ingest one or more LAE folders"
    task ingest: :environment do
      folder_dir = ARGV[1]
      project = ENV["PROJECT"]
      state = ENV["STATE"]

      abort "usage: PROJECT=projectlabel STATE=state rake lae:ingest /path/to/lae/folder" unless Dir.exist?(folder_dir) && project.present?
      IngestEphemeraJob.set(queue: :low).perform_later(folder_dir, state, project)
    end

    desc "Ingest LAE folders"
    task ingest_disk_files: :environment do
      folder_dir = ARGV[1]
      abort "usage: rake lae:ingest_disk_files /path/to/lae/folder" unless folder_dir
      abort "Error: No such file or directory: #{folder_dir}" unless Dir.exist?(folder_dir)
      IngestLaeFolderJob.set(queue: :low).perform_later(folder_dir)
    end

    desc "Ingest LAE poster"
    task ingest_posters: :environment do
      file = ARGV[1]
      project_label = ENV["PROJECT"]

      abort "usage: PROJECT=projectlabel rake lae:ingest_posters /path/to/lae.json" unless File.exist?(file) && project_label.present?
      PosterIngesterJob.perform_later(file, project_label)
    end
  end
end
