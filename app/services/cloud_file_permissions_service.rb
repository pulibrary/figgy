# frozen_string_literal: true

# Updates an s3 object ACL based on resource visibilty
class CloudFilePermissionsService
  attr_reader :resource, :key, :region, :bucket, :public_acl
  def initialize(resource:, key:, region: Figgy.config["cloud_geo_region"], bucket: Figgy.config["cloud_geo_bucket"], public_acl: false)
    @resource = resource
    @key = key
    @region = region
    @bucket = bucket
    @public_acl = public_acl
  end

  def run
    return if key.include?(":\/\/")
    client.put_object_acl({ acl: acl, bucket: bucket, key: key })
  end

  private

    def acl
      if public_acl || public_resource?
        "public-read"
      else
        "private"
      end
    end

    def public_resource?
      resource.visibility == [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
    end

    def client
      Aws::S3::Client.new({ region: region, credentials: credentials })
    end

    def credentials
      Aws::Credentials.new(Figgy.config["aws_access_key_id"], Figgy.config["aws_secret_access_key"])
    end
end
