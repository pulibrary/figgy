class FullTextSearch
  def self.queries
    [:full_text_search]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  def initialize(query_service:)
    @query_service = query_service
  end

  def full_text_search(id:, text:)
    connection[full_text_search_query, id: id.to_s, text: text].map do |result|
      resource = resource_factory.to_resource(object: result)
      resource.highlights = result[:highlights].to_s.split("|||")
      resource
    end
  end

  def full_text_search_query
    <<-SQL
    WITH pages AS (
        SELECT
            member.*,
            member.metadata->'ocr_content'->>0 AS ocr_text
        FROM
            orm_resources a,
            jsonb_array_elements(a.metadata->'member_ids') AS b(member),
            orm_resources member
        WHERE
            a.id = :id
            AND (b.member->>'id')::UUID = member.id
    ),
    matching AS (
        SELECT
            pages.*,
            to_tsvector('english', ocr_text) AS tsv
        FROM pages
        WHERE to_tsvector('english', ocr_text)
            @@ websearch_to_tsquery('english', :text)
    )
    SELECT
        matching.*,
        ts_headline(
            'english',
            ocr_text,
            websearch_to_tsquery('english', :text),
            'StartSel=<em>, StopSel=</em>, MaxFragments=10, MaxWords=5, MinWords=1, FragmentDelimiter=|||'
        ) AS highlights
    FROM matching;
    SQL
  end
end
