class Types::NoticeType < Types::BaseObject
  field :heading, String, null: false
  field :accept_label, String, null: false
  field :text_html, String, null: false
end
