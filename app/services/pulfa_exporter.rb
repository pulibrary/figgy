# frozen_string_literal: true
# Export Figgy content to PULFA, inserting DAOs into the EAD XML files linking to the Figgy manifest URLs
class PulfaExporter
  attr_reader :since_date, :svn_client, :logger
  def initialize(since_date:, logger: Rails.logger, svn_client: nil)
    @logger = logger
    @since_date = since_date
    @svn_client = svn_client || SvnClient.new
    @updated_eads = []
  end

  def export
    svn_client.update
    export_daos
  end

  def export_pdf(colid)
    col = Valkyrie.config.metadata_adapter.query_service.find_by(id: colid)
    ead = ead_for(col.source_metadata_identifier.first)
    update_ead(ead, col.decorate.members, pdf: true)
  end

  private

    # all objects linked to finding aids that have been updated recently
    def updated_objects
      logger.info "Listing objects updated since #{since_date}"
      @updated_objects ||= Valkyrie.config.metadata_adapter.query_service.custom_queries.updated_archival_resources(since_date: since_date)
    end

    # updated objects, grouped by collection
    def grouped_objects
      @grouped_objects ||= updated_objects.group_by(&:archival_collection_code)
    end

    # export daos to PULFA SVN
    def export_daos
      logger.info "Exporting DAOs to PULFA SVN"
      grouped_objects.keys.each do |collection_code|
        file = ead_for(collection_code)
        if file
          update_ead(file, grouped_objects[collection_code])
        else
          Honeybadger.notify("Unable to find EAD for collection #{collection_code}")
        end
      end
      svn_client.commit
      notify
    end

    # find the EAD file for a collection code
    def ead_for(collection_code)
      all_eads.select { |fn| fn.include?("/#{collection_code}.EAD.xml") }.first
    end

    # list all EAD/XML files
    def all_eads
      @all_eads ||= Dir["#{svn_client.svn_dir}/eads/**/*.EAD.xml"]
    end

    # update the DAO links in an EAD/XML file
    def update_ead(filename, resources, pdf: false)
      logger.info "Updating DAO URLs in #{filename}"
      ead = Nokogiri::XML(File.open(filename))

      resources.each do |r|
        cid = r.source_metadata_identifier&.first
        component = ead.at_xpath("//ead:c[@id=\'#{cid}\']", namespaces_for_xpath)
        next unless component
        if pdf
          create_or_update_pdf_dao(ead, component, r)
        else
          create_or_update_dao(ead, component, r)
        end
      end

      File.open(filename, "w") { |f| f.puts(ead.to_xml) }
      @updated_eads << filename
    end

    # find a dao attached to this element, creating it if it doesn't exist
    def create_or_update_dao(ead, component, r)
      dao = component.at_xpath(".//ead:dao", namespaces_for_xpath) || create_dao_element(ead, component)
      if zip_file?(r)
        file_set = Wayfinder.for(r).file_sets.first
        update_dao(dao, Rails.application.routes.url_helpers.download_url(file_set.id, file_set.primary_file.id))
      else
        update_dao(dao, Rails.application.routes.url_helpers.manifest_scanned_resource_url(r), "xlink:role" => "https://iiif.io/api/presentation/2.1/")
      end
    end

    def create_or_update_pdf_dao(ead, component, r)
      if !r.decorate.volumes.empty?
        create_or_update_volume_daos(ead, component, r)
      else
        dao = component.at_xpath(".//ead:dao", namespaces_for_xpath) || create_dao_element(ead, component)
        update_dao(dao, "pdf/#{r.source_metadata_identifier.first.gsub(/.*_/, '')}.pdf")
      end
    end

    def zip_file?(resource)
      Wayfinder.for(resource).file_sets.first&.mime_type&.include?("application/zip")
    end

    def create_or_update_volume_daos(ead, component, r)
      r.decorate.volumes.each_with_index do |_vol, index|
        href = "pdf/#{r.source_metadata_identifier.first.gsub(/.*_/, '')}_#{index}.pdf"
        dao = component.at_xpath(".//ead:dao[xlink:href='" + href + "']", namespaces_for_xpath) || create_dao_element(ead, component)
        update_dao(dao, href)
      end
    end

    def update_dao(dao, href, attrs = {})
      return if dao.get_attribute("xlink:href") == href
      dao.attribute_nodes.each(&:remove)
      dao.set_attribute("xlink:href", href)
      dao.set_attribute("xlink:type", "simple")
      attrs.each do |key, value|
        dao.set_attribute(key, value)
      end
    end

    # create and attach a new dao element
    def create_dao_element(ead, component)
      did = component.at_xpath("./ead:did", namespaces_for_xpath)
      new_dao = Nokogiri::XML::Element.new("dao", ead)
      did.add_child(new_dao)
    end

    # namespaces used in xpath queries
    def namespaces_for_xpath
      { xlink: "http://www.w3.org/1999/xlink", ead: "urn:isbn:1-931666-22-9" }
    end

    # send email to configured address about branch being ready to review
    def notify
      PulfaMailer.with(updated: @updated_eads.sort).branch_notification.deliver_now
    rescue StandardError => e
      Honeybadger.notify(e, error_message: "Error sending Pulfa export notification email")
    end
end
