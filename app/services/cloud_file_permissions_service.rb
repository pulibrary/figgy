# frozen_string_literal: true

# Updates an s3 object ACL based on resource visibilty
class CloudFilePermissionsService
  attr_reader :resource, :key, :region, :bucket
  def initialize(resource:, key:, region: Figgy.config["cloud_geo_region"], bucket: Figgy.config["cloud_geo_bucket"])
    @resource = resource
    @key = key
    @region = region
    @bucket = bucket
  end

  def run
    return if key.include?(":\/\/")
    client.put_object_acl({ acl: acl, bucket: bucket, key: key })
  end

  private

    def acl
      if resource.visibility == [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        "public-read"
      else
        "private"
      end
    end

    def client
      Aws::S3::Client.new({ region: region, credentials: credentials })
    end

    def credentials
      Aws::Credentials.new(Figgy.config["aws_access_key_id"], Figgy.config["aws_secret_access_key"])
    end
end
