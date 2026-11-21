require "rails_helper"

RSpec.describe "WebDAV", type: :request do
  with_queue_adapter :inline

  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

  before do
    stub_ezid
    # Derivative sizes come from the image server.
    stub_request(:head, %r{/image-service/}).to_return(headers: { "Content-Length" => "4321" })
  end

  # Factories save to Postgres; browse listings come from Solr.
  def create(*args, **kwargs)
    resource = FactoryBot.create_for_repository(*args, **kwargs)
    resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)
    Valkyrie::MetadataAdapter.find(:index_solr).persister.save(resource: resource)
    resource
  end

  def propfind(path, headers: {}, depth: "1")
    process :propfind, path, headers: headers.merge("HTTP_DEPTH" => depth)
    expect(response).to have_http_status(:multi_status)
    Nokogiri::XML(response.body).remove_namespaces!
  end

  # Child names in a PROPFIND response, excluding the requested directory itself.
  def listing(path, headers: {})
    propfind(path, headers: headers).xpath("//response")[1..].map { |r| r.at_xpath("propstat/prop/displayname").text }
  end

  def dir_name(resource, position: nil)
    Webdav::Naming.resource_dir_name(title: resource.title.first, id: resource.id, position: position)
  end

  def path_for(*segments)
    "/dav/" + segments.map { |s| ERB::Util.url_encode(s) }.join("/")
  end

  describe "access" do
    it "needs no credentials" do
      process :propfind, "/dav/"
      expect(response).to have_http_status(:multi_status)
      expect(response.headers["WWW-Authenticate"]).to be_nil
    end

    it "ignores credentials, even an admin token" do
      private_resource = create(:complete_private_scanned_resource, title: "Private book")
      token = AuthToken.create!(label: "Admin", group: ["admin"]).token
      admin = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("user", token) }

      expect(listing("/dav/titles/", headers: admin)).to eq []
      process :propfind, path_for("titles", dir_name(private_resource)), headers: admin
      expect(response).to have_http_status(:not_found)
    end

    it "doesn't grant campus IP access" do
      allow(Figgy).to receive(:campus_ip_ranges).and_return([IPAddr.new("127.0.0.0/8")])
      campus = create(:complete_on_campus_scanned_resource, title: "Campus book")
      on_campus = { "REMOTE_ADDR" => "127.0.0.1" }
      expect(Ability.new(nil, ip_address: "127.0.0.1").can?(:read, campus)).to be true

      expect(listing("/dav/titles/", headers: on_campus)).to eq []
      process :propfind, path_for("titles", dir_name(campus)), headers: on_campus
      expect(response).to have_http_status(:not_found)
    end
  end

  it "advertises read-only DAV on OPTIONS" do
    process :options, "/dav/"
    expect(response).to have_http_status(:ok)
    expect(response.headers["DAV"]).to eq "1"
    expect(response.headers["Allow"]).to eq "OPTIONS, GET, HEAD, PROPFIND"
  end

  it "rejects writes" do
    process :put, "/dav/titles/foo.txt", params: "hi"
    expect(response).to have_http_status(:method_not_allowed)
    process :mkcol, "/dav/titles/new"
    expect(response).to have_http_status(:method_not_allowed)
  end

  it "404s desktop junk files without looking anything up" do
    process :propfind, "/dav/titles/.DS_Store"
    expect(response).to have_http_status(:not_found)
  end

  it "lists the browse roots" do
    doc = propfind("/dav/")
    expect(doc.xpath("//response/href").map(&:text)).to eq ["/dav/", "/dav/titles/", "/dav/collections/", "/dav/recent/"]
    expect(doc.xpath("//response/propstat/prop/resourcetype/collection").size).to eq 4
  end

  it "only returns the directory itself for Depth: 0" do
    doc = propfind("/dav/titles/", depth: "0")
    expect(doc.xpath("//response").size).to eq 1
  end

  describe "titles" do
    it "lists public, published resources and hides the rest" do
      open = create(:complete_open_scanned_resource, title: "Open book")
      create(:complete_private_scanned_resource, title: "Private book")
      create(:pending_scanned_resource, title: "Unpublished book")
      create(:collection)

      expect(listing("/dav/titles/")).to eq [dir_name(open)]
    end

    it "splits large result sets into title range folders" do
      stub_const("Webdav::Index::LEAF_SIZE", 2)
      apple = create(:complete_open_scanned_resource, title: "Apple")
      apricot = create(:complete_open_scanned_resource, title: "Apricot")
      avocado = create(:complete_open_scanned_resource, title: "Avocado")
      banana = create(:complete_open_scanned_resource, title: "Banana")

      expect(listing("/dav/titles/")).to eq ["a", "b"]
      # "a" has three, so it splits again - and "ap" is listed directly since
      # it's small enough.
      expect(listing("/dav/titles/a/")).to eq ["ap", "av"]
      expect(listing("/dav/titles/a/ap/")).to eq [dir_name(apple), dir_name(apricot)]
      expect(listing("/dav/titles/a/av/")).to eq [dir_name(avocado)]
      expect(listing("/dav/titles/b/")).to eq [dir_name(banana)]
      # Resources resolve from inside any range folder.
      expect(listing(path_for("titles", "a", "ap", dir_name(apple)))).to eq []
    end

    it "skips range folders that would only contain one sub-range" do
      stub_const("Webdav::Index::LEAF_SIZE", 2)
      create(:complete_open_scanned_resource, title: "Apple")
      create(:complete_open_scanned_resource, title: "Apricot")
      create(:complete_open_scanned_resource, title: "Apex")

      # Everything is under "a", then "ap" - so go straight to what's under "ap".
      expect(listing("/dav/titles/")).to eq ["ape", "app", "apr"]
    end

    it "404s range folders that don't parse" do
      process :propfind, path_for("titles", "a–")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a resource" do
    let(:fixture_size) { File.size(Rails.root.join("spec", "fixtures", "files", "example.tif")) }

    it "lists child works as folders, and images as IIIF derivatives" do
      child = create(:complete_open_scanned_resource, title: "Volume 1", files: [file])
      parent = create(:complete_open_scanned_resource, title: "Multi-volume", member_ids: [child.id])

      # No files directly on the parent, so no originals folder either.
      expect(listing(path_for("titles", dir_name(parent)))).to eq [dir_name(child, position: "0001")]

      child_path = path_for("titles", dir_name(parent), dir_name(child, position: "0001"))
      doc = propfind(child_path)
      expect(doc.xpath("//response/propstat/prop/displayname").map(&:text).drop(1)).to eq ["0001 - example.jpg", "originals"]
      jpg = doc.xpath("//response")[1]
      expect(jpg.at_xpath("href").text).to eq "#{child_path}/0001%20-%20example.jpg"
      expect(jpg.at_xpath("propstat/prop/getcontenttype").text).to eq "image/jpeg"
      expect(jpg.at_xpath("propstat/prop/resourcetype").children).to be_empty
      expect(jpg.at_xpath("propstat/prop/getcontentlength").text).to eq "4321"

      get "#{child_path}/0001%20-%20example.jpg"
      file_set = Wayfinder.for(child).members.first
      expect(response).to redirect_to(%r{/image-service/#{file_set.id}/full/!2000,2000/0/default\.jpg\z})
    end

    it "leaves out derivative sizes the image server doesn't report" do
      stub_request(:head, %r{/image-service/}).to_return(status: 500)
      resource = create(:complete_open_scanned_resource, title: "Unsized", files: [file])
      doc = propfind(path_for("titles", dir_name(resource)))
      expect(doc.xpath("//response")[1].at_xpath("propstat/prop/getcontentlength")).to be_nil
      get path_for("titles", dir_name(resource))
      expect(response.body).to include("0001 - example.jpg</a>")
    end

    it "puts the original files in an originals folder, with Range support" do
      resource = create(:complete_open_scanned_resource, title: "Book", files: [file])
      originals = path_for("titles", dir_name(resource), "originals")

      doc = propfind(originals)
      tif = doc.xpath("//response")[1]
      expect(tif.at_xpath("propstat/prop/displayname").text).to eq "0001 - example.tif"
      expect(tif.at_xpath("propstat/prop/getcontentlength").text.to_i).to eq fixture_size
      expect(tif.at_xpath("propstat/prop/getcontenttype").text).to eq "image/tiff"

      get "#{originals}/0001%20-%20example.tif"
      expect(response).to have_http_status(:ok)
      expect(response.body.bytesize).to eq fixture_size
      expect(response.headers["Content-Type"]).to eq "image/tiff"

      get "#{originals}/0001%20-%20example.tif", headers: { "HTTP_RANGE" => "bytes=0-9" }
      expect(response).to have_http_status(:partial_content)
      expect(response.body.bytesize).to eq 10

      # The derivative's name doesn't resolve inside originals, nor vice versa.
      get "#{originals}/0001%20-%20example.jpg"
      expect(response).to have_http_status(:not_found)
      get path_for("titles", dir_name(resource), "0001 - example.tif")
      expect(response).to have_http_status(:not_found)
    end

    it "lists non-image files as originals, with no originals folder" do
      audio = fixture_file_upload("files/audio_file.wav", "audio/x-wav")
      resource = create(:complete_open_scanned_resource, title: "Recording", files: [audio])
      path = path_for("titles", dir_name(resource))

      expect(listing(path)).to eq ["0001 - audio_file.wav"]
      process :propfind, path_for("titles", dir_name(resource), "originals")
      expect(response).to have_http_status(:not_found)
      get path_for("titles", dir_name(resource), "0001 - audio_file.wav")
      expect(response).to have_http_status(:ok)
    end

    it "lists images without a pyramidal derivative as originals" do
      allow_any_instance_of(ManifestBuilder::ManifestHelper).to receive(:manifest_image_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      resource = create(:complete_open_scanned_resource, title: "Unprocessed", files: [file])
      expect(listing(path_for("titles", dir_name(resource)))).to eq ["0001 - example.tif"]
    end

    it "hands originals to nginx via X-Accel-Redirect in production" do
      allow(Rails.application.config.action_dispatch).to receive(:x_sendfile_header).and_return("X-Accel-Redirect")
      resource = create(:complete_open_scanned_resource, title: "Sendfile", files: [file])
      get path_for("titles", dir_name(resource), "originals", "0001 - example.tif")
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to eq "image/tiff"
      expect(response.body.bytesize).to eq fixture_size
    end

    it "404s when an original has gone missing from storage" do
      resource = create(:complete_open_scanned_resource, title: "Missing", files: [file])
      allow(Valkyrie::StorageAdapter).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)
      get path_for("titles", dir_name(resource), "originals", "0001 - example.tif")
      expect(response).to have_http_status(:not_found)
    end

    it "404s resources that don't exist" do
      process :propfind, path_for("titles", "Gone [#{SecureRandom.uuid}]")
      expect(response).to have_http_status(:not_found)
    end

    it "404s paths nested too deep" do
      resource = create(:complete_open_scanned_resource, title: "Shallow", files: [file])
      process :propfind, path_for("titles", dir_name(resource), "originals", "0001 - example.tif", "deeper")
      expect(response).to have_http_status(:not_found)
    end

    it "renders an HTML index for browsers" do
      resource = create(:complete_open_scanned_resource, title: "Browsable", files: [file])
      get path_for("titles", dir_name(resource))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("0001 - example.jpg (4.22 KB)", "originals/")
      get path_for("titles", dir_name(resource), "originals")
      expect(response.body).to include("0001 - example.tif (")
    end

    it "shows derivatives but not originals when downloads are turned off" do
      resource = create(:complete_open_scanned_resource, title: "No downloads", downloadable: ["none"], files: [file])
      path = path_for("titles", dir_name(resource))

      expect(listing(path)).to eq ["0001 - example.jpg"]
      process :propfind, path_for("titles", dir_name(resource), "originals")
      expect(response).to have_http_status(:not_found)
      get path_for("titles", dir_name(resource), "originals", "0001 - example.tif")
      expect(response).to have_http_status(:not_found)
    end

    it "404s private resources" do
      resource = create(:complete_private_scanned_resource)
      process :propfind, path_for("titles", dir_name(resource))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "collections" do
    it "lists collections, then their members" do
      collection = create(:collection, title: "Maps")
      member = create(:complete_open_scanned_resource, title: "Map of Princeton", member_of_collection_ids: [collection.id])
      create(:complete_open_scanned_resource, title: "Not in it")

      expect(listing("/dav/collections/")).to eq [dir_name(collection)]
      expect(listing(path_for("collections", dir_name(collection)))).to eq [dir_name(member)]
    end
  end

  describe "recent" do
    it "lists the most recently updated resources first" do
      older = create(:complete_open_scanned_resource, title: "Older")
      newer = create(:complete_open_scanned_resource, title: "Newer")
      expect(listing("/dav/recent/")).to eq [dir_name(newer), dir_name(older)]
    end
  end
end
