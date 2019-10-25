# frozen_string_literal: true
module Postgres
  class Repository < Blacklight::AbstractRepository
    def search(params = {})
      offset = (params.page - 1) * params.rows
      relation = query_service.resources.exclude(internal_resource: [EphemeraTerm, FileSet, EphemeraVocabulary, EphemeraProject, EphemeraField].map(&:to_s)).where(Sequel.pg_jsonb_op(:metadata).contains({state: ["complete"], read_groups: ["public"]}))

      if params.query["q"].present?
        relation = relation.full_text_search(Sequel.function(:to_tsvector, Sequel[:metadata]), params.query["q"], plain: true, tsvector: true, language: 'english')
       end
      rows = relation.limit(params.rows).offset(offset).to_a.map do |resource|
        metadata_adapter.resource_factory.to_resource(object: resource)
      end
      count = relation.count
      Response.new(
        rows,
        blacklight_config,
        params,
        count
      )
    end

    def query_service
      metadata_adapter.query_service
    end

    def query
      <<-SQL
        select * from orm_resources WHERE to_tsvector(metadata) @@ plainto_tsquery(?) AND internal_resource NOT IN ('EphemeraTerm', 'FileSet', 'EphemeraVocabulary', 'EphemeraProject', 'EphemeraField') AND metadata @> '{"read_groups": ["public"], "state": ["complete"]}' LIMIT ?
      SQL
    end

    def count_query
      <<-SQL
        select COUNT(*) from orm_resources WHERE to_tsvector(metadata) @@ plainto_tsquery(?) AND internal_resource NOT IN ('EphemeraTerm', 'FileSet', 'EphemeraVocabulary', 'EphemeraProject', 'EphemeraField') AND metadata @> '{"read_groups": ["public"], "state": ["complete"]}'
      SQL
    end

    def find(id, params = {})
      Response.new(
        [
          metadata_adapter.query_service.find_by(id: id)
        ],
        blacklight_config,
        params,
        1
      )
    end

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
  end

  class Response
    attr_reader :rows_returned, :blacklight_config, :params, :count
    def initialize(rows_returned, blacklight_config, params, count)
      @rows_returned = rows_returned.to_a
      @blacklight_config = blacklight_config
      @params = params
      @count = count
    end

    def rows
      params.rows
    end

    def grouped?
      false
    end

    def documents
      @documents ||=
        begin
          rows_returned.to_a.map do |row|
            blacklight_config.document_model.new(row_to_solr_document(row))
          end
        end
    end

    def row_to_solr_document(row)
      row.attributes.each_with_object({}) do |(k, v), hsh|
        hsh["#{k}_tesim"] = v
        hsh["#{k}_ssim"] = v
        hsh["figgy_title_ssim"] = Array.wrap(row.try(:title)).first
        hsh["id"] = row.id.to_s
      end
    end

    def aggregations
      {}
    end

    def total
      count
    end

    delegate :page, :start, to: :params

    def limit_value
      params.rows
    end

    def total_count
      total
    end

    def offset_value
      (page - 1) * limit_value
    end

    def current_page
      params.page
    end

    def total_pages
      (total / limit_value.to_f).ceil
    end

    delegate :empty?, to: :documents

    def sort; end

    def spelling
      OpenStruct.new(words: [])
    end
  end
end
