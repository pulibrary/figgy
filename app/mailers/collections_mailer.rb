# frozen_string_literal: true

class CollectionsMailer < ApplicationMailer
  def owner_report
    collection = params[:collection]
    owners = collection.owners.map { |uid| User.find_by(uid: uid) }.compact.map(&:email)
    @collection_title = collection.decorate.title
    @resources = Wayfinder.for(collection).decorated_members.select do |member|
      !member.public_readable_state?
    end
    mail(to: owners, subject: "Weekly collection report for #{@collection_title}") unless @resources.empty? || owners.empty?
  end
end
