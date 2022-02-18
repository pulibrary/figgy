# frozen_string_literal: true

module LinkedData
  class LinkedEphemeraFolder < LinkedResource
    delegate(
      :alternative_title,
      :creator,
      :contributor,
      :publisher,
      :barcode,
      :local_identifier,
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
      :date_created,
      :transliterated_title,
      :keywords,
      to: :decorated_resource
    )

    def geo_subject
      decorated_resource.geo_subject.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def genre
      Array.wrap(LinkedEphemeraTerm.new(resource: decorated_resource.genre).without_context)
    end

    def geographic_origin
      Array.wrap(LinkedEphemeraTerm.new(resource: decorated_resource.geographic_origin).without_context)
    end

    def language
      decorated_resource.language.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def subject
      decorated_resource.subject.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def categories
      decorated_resource.categories.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def source
      return if decorated_resource.source_url.nil?
      decorated_resource.source_url.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def related_url
      return if decorated_resource.dspace_url.nil?
      decorated_resource.dspace_url.map { |r| LinkedEphemeraTerm.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def page_count
      Array.wrap(decorated_resource.page_count).first
    end

    def barcode
      Array.wrap(ephemera_box.try(:barcode)).first
    end

    def box_number
      Array.wrap(ephemera_box.try(:box_number)).first
    end

    def date_range
      Array.wrap(decorated_resource.date_range).map { |r| LinkedDateRange.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def title
      [Array.wrap(decorated_resource.title).first] +
        Array.wrap(try(:transliterated_title))
    end

    def series
      Array.wrap(decorated_resource.series).first
    end

    def provenance
      Array.wrap(decorated_resource.provenance).first
    end

    def collections
      super + [ephemera_project]
    end

    private

      def linked_collections
        value = collections.map { |collection| LinkedCollection.new(resource: collection).as_jsonld }
        if ephemera_box
          value.push(
            '@id': helper.solr_document_url(id: ephemera_box.id),
            '@type': "pcdm:Collection",
            barcode: barcode,
            label: ephemera_box.try(:first_title),
            box_number: box_number
          )
        end
        value
      end

      def properties
        {
          '@type': "pcdm:Object",
          title: try(:title),
          alternative: try(:alternative_title),
          creator: try(:creator),
          contributor: try(:contributor),
          publisher: try(:publisher),
          barcode: try(:barcode),
          local_identifier: try(:local_identifier),
          label: "Folder #{folder_number}",
          is_part_of: ephemera_project.try(:title),
          coverage: try(:geo_subject),
          format: try(:genre),
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
          folder_number: try(:folder_number),
          date_range: try(:date_range),
          date_created: try(:date_created),
          series: try(:series),
          provenance: try(:provenance),
          transliterated_title: try(:transliterated_title),
          keywords: try(:keywords)
        }
      end
  end
end
