# frozen_string_literal: true
class OaiProvider < OAI::Provider::Base
  repository_name "OaiProvider" # This value is strange, but if it's not constantizable then the gem throws an error
  repository_url ManifestBuilder::ManifestHelper.new.oai_url
  record_prefix "oai:figgy"
  admin_email ""
  source_model ValkyrieProviderModel.new
  sample_id "1"
  register_format(MARC21.instance)
end
