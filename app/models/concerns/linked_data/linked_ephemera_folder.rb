# frozen_string_literal: true
module LinkedData
  class LinkedEphemeraFolder < LinkedResource
    delegate(
      :collections,
      :alternative_title,
      :creator,
      :contributor,
      :publisher,
      :barcode,
      :folder_number,
      :ephemera_project,
      :description,
      :height,
      :width,
      :sort_title,
      :page_count,
      :created_at,
      :updated_at,
      :folder_number,
      :ephemera_box,
      to: :decorated_resource
    )

    def geo_subject
      decorated_resource.geo_subject.map { |r| LinkedNode.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def genre
      LinkedNode.new(resource: decorated_resource.genre).without_context
    end

    def geographic_origin
      LinkedNode.new(resource: decorated_resource.geographic_origin).without_context
    end

    def language
      decorated_resource.language.map { |r| LinkedResourceFactory.new(resource: r).new.without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def subject
      decorated_resource.subject.map { |r| LinkedResourceFactory.new(resource: r).new.without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def categories
      decorated_resource.categories.map { |r| LinkedNode.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def source
      return if decorated_resource.source_url.nil?
      decorated_resource.source_url.map { |r| LinkedNode.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def related_url
      return if decorated_resource.dspace_url.nil?
      decorated_resource.dspace_url.map { |r| LinkedNode.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def page_count
      Array.wrap(decorated_resource.page_count).first
    end

    def local_fields
      super.tap do |fields|
        fields.merge!(attributes).reject { |_, v| v.nil? || v.try(:empty?) }
      end
    end

    def barcode
      Array.wrap(ephemera_box.try(:barcode)).first
    end

    def box_number
      Array.wrap(ephemera_box.try(:box_number)).first
    end

    def collection_objects
      super.push(
        '@id': helper.solr_document_url(id: "id-#{ephemera_box.id}"),
        '@type': 'pcdm:Collection',
        barcode: barcode,
        label: ephemera_box.try(:header),
        box_number: box_number
      )
    end

    private

      def attributes
        {
          '@type': 'pcdm:Object',
          alternative: try(:alternative_title),
          creator: try(:creator),
          contributor: try(:contributor),
          publisher: try(:publisher),
          barcode: try(:barcode),
          label: "Folder #{folder_number}",
          is_part_of: ephemera_project.title,
          coverage: try(:geo_subject),
          dcterms_type: try(:genre),
          origin_place: try(:geographic_origin),
          language: try(:language),
          subject: try(:subject),
          category: try(:categories),
          description: try(:description),
          source: try(:source),
          related_url: try(:related_url),
          height: try(:height),
          width: try(:width),
          sort_title: try(:sort_title),
          page_count: try(:page_count),
          created: try(:created_at),
          modified: try(:updated_at),
          folder_number: try(:folder_number)
        }
      end
  end
end
