# frozen_string_literal: true

module CDL
  class CompleteMailer < ApplicationMailer
    def resources_completed
      @resources = params[:resource_ids].map do |resource_id|
        query_service.find_by(id: resource_id)
      end
      return if collection.blank?
      @users = collection.owners.map do |owner|
        User.where(uid: owner).first
      end
      mail(
        to: ["reserve@princeton.edu"] + @users.map(&:email),
        subject: "#{@resources.size} CDL Item(s) Completed"
      )
    end

    def collection
      query_service.custom_queries.find_by_property(property: :slug, value: "cdl", model: Collection).first
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
