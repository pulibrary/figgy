# frozen_string_literal: true
module OAI::Figgy
  class Provider < OAI::Provider::Base
    repository_name "Princeton University Library"
    repository_url ::ManifestBuilder::ManifestHelper.new.oai_url
    record_prefix "oai:figgy"
    admin_email "digital-library@princeton.libanswers.com"
    source_model ::OAI::Figgy::ValkyrieProviderModel.new
    sample_id "fb4ecf51-58c8-4481-8a91-12f05d4729aa"
    register_format(::OAI::Figgy::MARC21.instance)
  end
end
