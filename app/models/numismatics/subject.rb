module Numismatics
  class Subject < Resource
    include Valkyrie::Resource::AccessControls
    attribute :type
    attribute :subject
  end
end
