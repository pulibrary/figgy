class IIIFSearchResults
  attr_reader :resource, :query, :request
  def initialize(resource:, query:, request:)
    @resource = resource
    @query = query
    @request = request
  end

  def as_json(*_args)
    {
      "@context"=>
      [
        "http://iiif.io/api/presentation/2/context.json",
        "http://iiif.io/api/search/1/context.json"
      ],
      "@id"=> request.original_url,
      "@type"=>"sc:AnnotationList",
      "within"=>
      {
        "@type"=>"sc:Layer",
        "total"=> resources.length
      },
      "resources" => resources
    }
  end

  def resources
    @resources ||=
      begin
        hits.flat_map do |file_set_hits|
          file_set_hits[:hits].each_with_index.map do |hit, idx|
            {
              "@id" => "#{parent_manifest_node.manifest_url}/canvas/#{file_set_hits[:file_set].id}/annotation/#{idx}",
              "@type" => "oa:Annotation",
              "motivation" => "sc:painting",
              "on" => "#{parent_manifest_node.manifest_url}/canvas/#{file_set_hits[:file_set].id}#xywh=#{hit[:bbox][0]},#{hit[:bbox][1]},#{hit[:bbox][2]-hit[:bbox][0]},#{hit[:bbox][3]-hit[:bbox][1]}",
              "resource" => {
                "@type" => "cnt:ContentAsText",
                "chars" => hit[:text]
              }
            }
          end
        end.flatten
      end
  end

  private

  def parent_manifest_node
    ManifestBuilder::RootNode.for(resource)
  end

  def matching_file_sets
    @matching_file_sets ||=
      begin
        ChangeSetPersister.default.query_service.custom_queries.full_text_search(id: resource.id, text: query)
      end
  end

  # Convert the hOCR into a text -> bbox lookup table.
  def text_lookup(file_set)
    @text_lookup ||= {}
    @text_lookup[file_set] ||=
      begin
        lookup = {}
        file_set.hocr_content.first.scan(/title='(bbox(?:\s\d+){4}).*?'>(.*?)<\/span>/).each do |bbox, text|
          clean_text = text.gsub(/<(\/?)(.*?)>/, "")
          bbox = bbox.gsub("bbox ", "").split(" ").map(&:to_i)
          lookup[clean_text] ||= []
          lookup[clean_text].push(bbox)
        end
        lookup
      end
  end

  def hits
    @hits ||=
      begin
        matching_file_sets.map do |file_set|
          # Highlights are returned surrounded by <em> - find those words in the
          # hOCR to get their bounding boxes. If one highlight has multiple
          # <em>, we should find the first word and the last one, then combine
          # their bounding boxes.
          hits = file_set.highlights.each_with_index.map do |highlight, idx|
            matches = highlight.scan(/<em>(.*?)<\/em>/).flatten
            # Find the box for the first hit.
            first_match_box = text_lookup(file_set).dig(matches.first, idx) || [0, 0, 0, 0]
            # Find the box for the last hit.
            last_match_box = text_lookup(file_set).dig(matches.last, idx) || [0, 0, 0, 0]
            # Combine the boxes into a phrase box!
            combined_box = [
              [first_match_box[0], last_match_box[0]].min, # Minimum x1
              [first_match_box[1], last_match_box[1]].min, # Minimum y1
              [first_match_box[2], last_match_box[2]].max, # Maximum x2
              [first_match_box[3], last_match_box[3]].max  # Maximum y2
            ]
            { text: highlight, bbox: combined_box }
          end
          { file_set: file_set, hits: hits }
        end
      end
  end
end
