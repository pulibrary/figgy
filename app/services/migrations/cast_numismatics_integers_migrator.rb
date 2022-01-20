# frozen_string_literal: true

module Migrations
  class CastNumismaticsIntegersMigrator
    def self.run(logger: Rails.logger)
      csp = ChangeSetPersister.default
      [Numismatics::Accession, Numismatics::Issue, Numismatics::Coin].each do |klass|
        csp.query_service.find_all_of_model(model: klass).each do |resource|
          csp.save(change_set: ChangeSet.for(resource))
        end
        logger.info("migrated #{klass} objects")
      end
    end
  end
end
