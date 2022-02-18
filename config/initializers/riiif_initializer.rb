# frozen_string_literal: true

require "mini_magick"
Riiif::Image.file_resolver = RiiifResolver.new
Riiif::Image.file_resolver.base_path = Figgy.config["derivative_path"]
