# frozen_string_literal: true
namespace :import do
  desc "Imports an ID from Plum"
  task plum: :environment do
    id = ENV['ID']
    abort "usage: rake import:plum ID=plumid" unless id

    PlumImporterJob.perform_later(id)
  end
end
