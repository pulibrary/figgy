# frozen_string_literal: true
module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
    stub_aspace_repositories
  end

  def stub_aspace_repositories
    path = Rails.root.join("spec", "fixtures", "aspace", "repositories.json")
    cache_path(uri: "/repositories?page=1", path: path)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories?page=1")
      .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
  end

  def stub_create_digital_object
    response = {
      "status" => "Created",
      "id" => 56_588,
      "lock_version" => 0,
      "stale" => true,
      "uri" => "/repositories/3/digital_objects/56588",
      "warnings" => []
    }
    stub_request(:post, "https://aspace.test.org/staff/api/repositories/3/digital_objects")
      .to_return(status: 200, body: response.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_archival_object_update(archival_object_id:)
    stub_request(:post, "https://aspace.test.org/staff/api/repositories/3/archival_objects/#{archival_object_id}")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_find_digital_object(ref:)
    _, _, repository_id, _, digital_object_id = ref.split("/")
    path = Rails.root.join("spec", "fixtures", "aspace", "repositories", repository_id.to_s, "digital_object_#{digital_object_id}.json")
    cache_path(uri: ref, path: path)
    stub_request(:get, "https://aspace.test.org/staff/api#{ref}")
      .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
  end

  def stub_find_archival_object(component_id:)
    Aspace::Client.new.repositories.each do |repository|
      repository_id = repository["uri"].split("/").last
      path = Rails.root.join("spec", "fixtures", "aspace", "repositories", repository_id.to_s, "find_archival_object_#{component_id}.json")
      uri = "#{repository['uri']}/find_by_id/archival_objects?ref_id%5B%5D=#{component_id}"
      cache_path(uri: uri, path: path)
      json = JSON.parse(File.read(path))
      # Auto stub any finds - this'll always get called, so may as well not
      # force another stub.
      if json["archival_objects"]&.first.present?
        stub_archival_object(ref: json["archival_objects"][0]["ref"])
      end
      stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
        .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
    end
  end

  def stub_archival_object(ref:)
    _, _, repository_id, _, archival_object_id = ref.split("/")
    path = Rails.root.join("spec", "fixtures", "aspace", "repositories", repository_id.to_s, "archival_object_#{archival_object_id}.json")
    cache_path(uri: ref, path: path)
    stub_request(:get, "https://aspace.test.org/staff/api#{ref}")
      .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
  end

  # It took too long to manually create the mocks for navigating the whole tree,
  # so this shortcut function grabs it from the real API if necessary. Kind of
  # like on-demand VCR.
  def cache_path(uri:, path:)
    return if File.exist?(path)

    WebMock.disable!
    development_config = Figgy.all_environment_config["development"]
    client = ArchivesSpace::Client.new(
      ArchivesSpace::Configuration.new(
        base_uri: development_config["archivespace_url"],
        username: development_config["archivespace_user"],
        password: development_config["archivespace_password"]
      )
    )
    client.login
    result = client.get(uri)
    FileUtils.mkdir_p(Pathname.new(path).dirname)
    File.open(path, "w") do |f|
      f.write(result.body)
    end
    WebMock.enable!
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
