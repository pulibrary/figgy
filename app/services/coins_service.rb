# frozen_string_literal: true

class CoinsService
  def self.clean(background: false)
    clean_issues(background: background)
    clean_coins(background: background)
    clean_accessions(background: background)
    clean_firms(background: background)
    clean_monograms(background: background)
    clean_places(background: background)
    clean_people(background: background)
    clean_references(background: background)
  end

  def self.clean_accessions(background: false)
    query_service.find_all_of_model(model: NumismaticAccession).each do |accession|
      logger.info "Deleting NumismaticAccession: #{accession.id}"
      delete(id: accession.id, background: background)
    end
  end

  def self.clean_coins(background: false)
    query_service.find_all_of_model(model: Coin).each do |coin|
      logger.info "Deleting Coin: #{coin.id}"
      delete(id: coin.id, background: background)
    end
  end

  def self.clean_firms(background: false)
    query_service.find_all_of_model(model: NumismaticFirm).each do |firm|
      logger.info "Deleting NumismaticFirm: #{firm.id}"
      delete(id: firm.id, background: background)
    end
  end

  def self.clean_monograms(background: false)
    query_service.find_all_of_model(model: NumismaticMonogram).each do |monogram|
      logger.info "Deleting NumismaticMonogram: #{monogram.id}"
      delete(id: monogram.id, background: background)
    end
  end

  def self.clean_issues(background: false)
    query_service.find_all_of_model(model: NumismaticIssue).each do |issue|
      logger.info "Deleting NumismaticIssue: #{issue.id}"
      delete(id: issue.id, background: background)
    end
  end

  def self.clean_places(background: false)
    query_service.find_all_of_model(model: NumismaticPlace).each do |place|
      logger.info "Deleting NumismaticPlace: #{place.id}"
      delete(id: place.id, background: background)
    end
  end

  def self.clean_people(background: false)
    query_service.find_all_of_model(model: NumismaticPerson).each do |person|
      logger.info "Deleting NumismaticPerson: #{person.id}"
      delete(id: person.id, background: background)
    end
  end

  def self.clean_references(background: false)
    query_service.find_all_of_model(model: NumismaticReference).each do |reference|
      logger.info "Deleting NumismaticReference: #{reference.id}"
      delete(id: reference.id, background: background)
    end
  end

  def self.delete(id:, background:)
    if background
      DeleteMemberJob.perform_later(id.to_s)
    else
      DeleteMemberJob.perform_now(id.to_s)
    end
  end

  def self.logger
    Logger.new(STDOUT)
  end

  def self.query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
