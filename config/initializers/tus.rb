# frozen_string_literal: true
require "tus/storage/filesystem"

Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new("#{Figgy.config['ingest_folder_path']}/ingest_scratch/local_uploads")
