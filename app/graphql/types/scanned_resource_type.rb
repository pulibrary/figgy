class Types::ScannedResourceType < Types::BaseObject
  field :title, [String], null: true
  field :viewing_hint, String, null: true

  def viewing_hint
    Array.wrap(super).first
  end
end
