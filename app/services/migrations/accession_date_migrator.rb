# frozen_string_literal: true

module Migrations
  class AccessionDateMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      resources.each do |resource|
        next if resource.date.nil?
        formatted_date = DateTime.parse(resource.date.first.to_s).strftime("%Y-%m-%d")
        change_set = ChangeSet.for(resource)
        change_set.validate(date: formatted_date)
        change_set_persister.save(change_set: change_set)
      rescue Date::Error
        change_set = ChangeSet.for(resource)
        change_set.validate(date: nil)
        change_set_persister.save(change_set: change_set)
      end
    end

    private

      def resources
        query_service.find_all_of_model(model: Numismatics::Accession)
      end

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
