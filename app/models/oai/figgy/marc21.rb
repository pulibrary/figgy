# frozen_string_literal: true

module OAI::Figgy
  class MARC21 < OAI::Provider::Metadata::Format
    def initialize
      @prefix = "marc21"
      @schema = "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
      @namespace = "http://www.loc.gov/MARC21/slim"
      @element_namespace = "marc21"
      @fields = []
    end
  end
end
