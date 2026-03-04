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
        hits.each_with_index.map do |hit, idx|
          {
            "@id" => "#{parent_manifest_node.manifest_url}/canvas/#{hit.file_set.id}/annotation/#{idx}",
            "@type" => "oa:Annotation",
            "motivation" => "sc:painting",
            "on" => "#{parent_manifest_node.manifest_url}/canvas/#{hit.file_set.id}#xywh=#{hit.bbox[0]},#{hit.bbox[1]},#{hit.bbox[2]-hit.bbox[0]},#{hit.bbox[3]-hit.bbox[1]}",
            "resource" => {
              "@type" => "cnt:ContentAsText",
              "chars" => hit.text
            }
          }
        end
      end
  end

  private

  def parent_manifest_node
    ManifestBuilder::RootNode.for(resource)
  end

  # All file sets from the parent resource that has the given text in its OCR,
  # according to postgres.
  def matching_file_sets
    @matching_file_sets ||=
      begin
        ChangeSetPersister.default.query_service.custom_queries.full_text_search(id: resource.id, text: query)
      end
  end

  HocrToken = Struct.new(:text, :bbox, :idx, keyword_init: true)

  # Parse the hOCR to generate a walkable array of text and associated bounding boxes.
  # This gets used to find the bounding boxes given the highlight returns from
  # postgres.
  # @return [Array<HocrToken>]
  def bbox_array(file_set)
    @bbox_array ||= {}
    @bbox_array[file_set] ||=
      begin
        file_set.hocr_content.first.scan(/title='(bbox(?:\s\d+){4}).*?'>(.*?)<\/span>/).each_with_index.filter_map do |bbox_and_text, idx|
          bbox, text = bbox_and_text
          clean_text = CGI.unescapeHTML(text.gsub(/<(\/?)(.*?)>/, "")).strip
          bbox = bbox.gsub("bbox ", "").split(" ").map(&:to_i)
          HocrToken.new(text: clean_text, bbox: bbox, idx: idx) if clean_text.present?
        end
      end
  end

  Hit = Struct.new(:file_set, :text, :bbox, keyword_init: true)

  # Walks the OCR for each file set that has a match and for every
  # matching text string attempts to find where exactly in the hOCR that phrase
  # is, which allows us to get the bounding boxes for that match but still have
  # good full text phrase search against plain text.
  #
  # If we start using a Solr plugin like
  # https://dbmdz.github.io/solr-ocrhighlighting/latest/, that would be much
  # more efficient (as it associates bbox payloads with each token),
  # but we'd have to index FileSets and this is less implementation work.
  # @return [Array<Hit>]
  def hits
    @hits ||=
      begin
        matching_file_sets.flat_map do |file_set|
          word_iterator = bbox_array(file_set).to_enum
          file_set.highlights.map do |highlight|
            no_break_highlight = highlight.gsub("\n", "")
            clean_highlight = no_break_highlight.gsub(/<(\/?)(.*?)>/, "")
            test_highlight = clean_highlight
            highlights = []
            highlight_last = nil
            # Loop through the whole document, finding the phrases returned by
            # SQL in order. Uses an enum so that we only ever walk the hOCR
            # once, no matter how many highlights we're trying to match up.
            #
            # Postgres returns highlights like "<em>Dogs</em> are really
            # awesome" - we want to highlight Dogs in the search result, but use
            # the rest of that phrase to make sure we're highlighting the
            # correct 'Dogs'
            #
            # The algorithm is basically:
            #
            # 1. Go through every token in the hOCR, does the highlight start
            # with that word? If so, save it, remove that word from the
            # highlight.
            # 2. Does the next token match the next part of the highlight? If
            # so, store it. If not, reset the test to the original highlight and
            # keep traversing.
            # 3. If we consume the entire test highlight from postgres (so all tokens have
            # matched), then those tokens we've saved are the bounding boxes we
            # need. Use them to generate a bounding box.
            begin
              loop do
                # Don't consume the iterator, just get the next token.
                hocr_token = word_iterator.peek

                if highlights == []
                  if test_highlight.start_with?(hocr_token.text)
                    # We might be on the start of the phrase. Record it.
                    highlights << hocr_token
                    highlight_last = hocr_token.idx
                    test_highlight = test_highlight.delete_prefix(hocr_token.text).strip
                    word_iterator.next
                  else
                    word_iterator.next
                  end
                else
                  # If the next token is ALSO part of the phrase, record it and
                  # keep going.
                  if hocr_token.idx == (highlight_last + 1) && (test_highlight.start_with?(hocr_token.text) || hocr_token.text.start_with?(test_highlight))
                    highlights << hocr_token
                    highlight_last = hocr_token.idx
                    test_highlight = test_highlight.delete_prefix(hocr_token.text).strip
                    word_iterator.next

                    # We're done if we've found every token or if the last token
                    # contains all of the highlight. The last test is necessary
                    # because Postgres will remove puncutation in the highlight
                    # sometimes, but it'll be in the word token in the hOCR.
                    break if test_highlight.blank? || hocr_token.text.start_with?(test_highlight)
                  else
                    # This wasn't the phrase - reset and keep looking.
                    # Don't do "next" - that word might be part of the next
                    # phrase.
                    # This shouldn't happen often - this is often a good place
                    # for a breakpoint to debug hit highlighting not returning
                    # good phrase matches.
                    highlights = []
                    test_highlight = clean_highlight
                  end
                end
              end
            rescue StopIteration
            end
            # Now we have a list of tokens, get the ones that match to phrase
            # highlight.
            matches = highlight.scan(/<em>(.*?)<\/em>/).flatten.map do |match|
              highlights.find { |hocr_token| hocr_token.text.start_with?(match) }
            end
            # Fall back to 0,0,0,0 if we can't find a bbox.
            first_match_box = matches&.dig(0, :bbox) || [0, 0, 0, 0]
            last_match_box = matches&.dig(-1, :bbox) || [0, 0, 0, 0]
            combined_box = [
              [first_match_box[0], last_match_box[0]].min, # Minimum x1
              [first_match_box[1], last_match_box[1]].min, # Minimum y1
              [first_match_box[2], last_match_box[2]].max, # Maximum x2
              [first_match_box[3], last_match_box[3]].max  # Maximum y2
            ]
            Hit.new(file_set: file_set, text: highlight.gsub("\n", " "), bbox: combined_box)
          end
        end
      end
  end
end
