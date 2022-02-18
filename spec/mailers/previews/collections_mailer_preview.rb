# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/collections_mailer
class CollectionsMailerPreview < ActionMailer::Preview
  def owner_report
    collection = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Collection).first
    CollectionsMailer.with(collection: collection).owner_report
  end
end
