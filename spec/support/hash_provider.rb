# BrowseEverything::Provider which is powered off a simple hash. Useful for
# testing cloud functionality without hitting the cloud.
class HashProvider
  attr_reader :hsh, :file
  def initialize(hsh, file:)
    @hsh = hsh
    @file = file
  end

  def auth_token; end

  def find_bytestream(id:); end

  def find_container(id:)
    all_containers.find { |container| container.id == id }
  end

  def all_containers
    @all_containers ||=
      begin
        containers = hsh.map do |id, _vals|
          build_container(hsh: hsh[id], id: id, parent_id: nil)
        end
        containers.flat_map { |x| deep_containers(x) }
      end
  end

  def deep_containers(container)
    return [container] unless container.containers.present?
    [container] + container.containers.flat_map { |x| deep_containers(x) }
  end

  def build_container(hsh:, id:, parent_id: nil)
    containers = []
    if hsh[:children].present?
      containers = hsh[:children].map do |child_id, _vals|
        build_container(hsh: hsh[:children][child_id], id: child_id, parent_id: id)
      end
    end
    bytestreams = []
    if hsh[:files].present?
      bytestreams = hsh[:files].map do |file_uri|
        WebMock.stub_request(:get, file_uri).to_return(
          status: 200,
          body: file
        )
        BrowseEverything::Bytestream.new(
          id: file_uri,
          location: "",
          name: File.basename(file_uri),
          size: 0,
          mtime: "",
          media_type: "image/tiff",
          uri: file_uri
        )
      end
    end
    BrowseEverything::Container.new(
      id: id,
      parent_id: parent_id,
      bytestreams: bytestreams,
      containers: containers,
      name: File.basename(id),
      location: "",
      mtime: ""
    )
  end
end
