# frozen_string_literal: true

# A reference work that contains information about coins and issues, such as reference works, auction
# catalogs, etc.
module Numismatics
  class Reference < Resource
    include Valkyrie::Resource::AccessControls

    # resources linked by ID
    attribute :author_id
    attribute :member_ids, Valkyrie::Types::Array

    # descriptive metadata
    attribute :part_of_parent
    attribute :pub_info
    attribute :short_title
    attribute :title
    attribute :year
    attribute :replaces
    attribute :depositor
  end
end
