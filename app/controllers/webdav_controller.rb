# Read-only WebDAV view of Figgy, mounted at /dav. Lets people mount Figgy as a
# network drive (Finder "Connect to Server", Windows "Map network drive",
# Cyberduck, `rclone mount`, ...) and browse Figgy's public resources by
# title, with child works as folders and files as files. See Webdav::Resolver
# for the layout.
#
# Anonymous only: no authentication, and credentials are ignored if sent.
# Every request is checked as a logged-out user with no IP-based access
# (campus, reading room), so only public, published content shows up.
class WebdavController < ActionController::API
  before_action :set_dav_headers

  ALLOWED_METHODS = "OPTIONS, GET, HEAD, PROPFIND"

  def options
    head :ok
  end

  def propfind
    return head :not_found unless node
    # "infinity" would mean walking the whole repository, so treat anything
    # other than 0 as 1. RFC 4918 allows servers to refuse infinite depth.
    entries = [[base_segments, node.entry]]
    entries += node.children.map { |child| [base_segments + [child.name], child] } if node.collection? && request.headers["Depth"] != "0"
    render body: Webdav::Multistatus.new(entries, root: dav_root).to_xml, status: :multi_status, content_type: "application/xml; charset=utf-8"
  end

  def show
    return head :not_found unless node
    node.collection? ? render_index : send_entry
  end

  # PUT, DELETE, MKCOL, LOCK, etc. We don't advertise LOCK support, so clients
  # mount the share read-only and mostly don't send these.
  def read_only
    head :method_not_allowed
  end

  private

    def ability
      @ability ||= Ability.new(nil)
    end

    def set_dav_headers
      response.headers["DAV"] = "1"
      response.headers["Allow"] = ALLOWED_METHODS
      response.headers["MS-Author-Via"] = "DAV"
    end

    def node
      return @node if defined?(@node)
      @node = Webdav::Resolver.new(ability: ability).resolve(base_segments)
    end

    def base_segments
      @base_segments ||= params[:path].to_s.split("/").reject(&:empty?)
    end

    def dav_root
      "#{request.script_name}/dav"
    end

    def render_index
      render html: Webdav::HtmlIndex.new(base_segments, node.children, root: dav_root).to_html
    end

    def send_entry
      entry = node.entry
      # Image derivatives come straight from the IIIF image server, so no
      # Figgy worker is tied up streaming them.
      return redirect_to(entry.derivative_url, allow_other_host: true, status: :found) if entry.derivative_url
      file_set = Webdav.downloadable_file_set(file_set_id: entry.file_set_id, parent: node.parent, ability: ability)
      return head :forbidden unless file_set
      # Listings are cached, so the file may have been replaced since.
      file_metadata = file_set.file_metadata.find { |fm| fm.id.to_s == entry.file_id }
      return head :not_found unless file_metadata
      # Primary files always live in the disk-backed repository storage.
      binary = Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifiers.first)
      response.headers["ETag"] = entry.etag
      response.headers["Last-Modified"] = entry.mtime.httpdate
      send_disk_file(binary.disk_path.to_s, entry)
    rescue Valkyrie::StorageAdapter::FileNotFound
      head :not_found
    end

    # In production nginx serves the file via X-Accel-Redirect, which also
    # handles Range requests. Elsewhere Rack::Files does the same job,
    # including Range, which mounted filesystems rely on for partial reads.
    def send_disk_file(path, entry)
      if Rails.application.config.action_dispatch.x_sendfile_header.present?
        # See DownloadsController#send_content.
        request.env["HTTP_X_ACCEL_MAPPING"] = "/opt/repository/=/restricted_repository/"
        send_file path, type: entry.content_type, disposition: :inline, filename: entry.name
      else
        status, headers, body = Rack::Files.new(nil).serving(request, path)
        self.status = status
        response.headers.merge!(headers)
        response.headers["Content-Type"] = entry.content_type if status.to_i < 300
        self.response_body = body
      end
    end
end
