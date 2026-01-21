module Numismatics
  class Firm < Resource
    include Valkyrie::Resource::AccessControls

    attribute :city, Valkyrie::Types::String
    attribute :name, Valkyrie::Types::String
    attribute :replaces
    attribute :depositor
  end
end
