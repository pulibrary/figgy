# frozen_string_literal: true
class Types::DirectoryInfo < Types::BaseObject
  field :children, [::Types::DirectoryInfo], null: false
  field :label, String, null: false
  field :path, String, null: false
  field :expanded, Boolean, null: false
  field :selected, Boolean, null: false
  field :selectable, Boolean, null: false
  field :loaded, Boolean, null: false

  def self.from(directory:)
    {

    }
  end
end
