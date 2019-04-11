# frozen_string_literal: true

class CoinsService
  def self.clean
    clean_issues
    clean_coins
    clean_places
    clean_people
  end

  def self.clean_coins
    query_service.find_all_of_model(model: Coin).each do |coin|
      logger.info "Deleting Coin: #{coin.id}"
      delete(coin)
    end
  end

  def self.clean_issues
    query_service.find_all_of_model(model: NumismaticIssue).each do |issue|
      logger.info "Deleting NumismaticIssue: #{issue.id}"
      delete(issue)
    end
  end

  def self.clean_places
    query_service.find_all_of_model(model: NumismaticPlace).each do |place|
      logger.info "Deleting NumismaticPlace: #{place.id}"
      delete(place)
    end
  end

  def self.clean_people
    query_service.find_all_of_model(model: NumismaticPerson).each do |person|
      logger.info "Deleting NumismaticPerson: #{person.id}"
      delete(person)
    end
  end

  def self.delete(resource)
    change_set_class = DynamicChangeSet
    change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
    change_set = change_set_class.new(resource)
    change_set_persister.buffer_into_index do |persist|
      persist.delete(change_set: change_set)
    end
  end

  def self.logger
    Logger.new(STDOUT)
  end

  def self.query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
