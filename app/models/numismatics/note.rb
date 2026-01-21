module Numismatics
  class Note < Resource
    include Valkyrie::Resource::AccessControls
    attribute :note
    attribute :type
  end
end
