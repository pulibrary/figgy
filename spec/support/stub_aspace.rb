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

  def stub_find_archival_object(component_id:)
    Aspace::Client.new.repositories.each do |repository|
      repository_id = repository["uri"].split("/").last
      path = Rails.root.join("spec", "fixtures", "aspace", "repositories", repository_id.to_s, "find_archival_object_#{component_id}.json")
      uri = "#{repository["uri"]}/find_by_id/archival_objects?ref_id%5B%5D=#{component_id}"
      cache_path(uri: uri, path: path)
      stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
        .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
    end
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
