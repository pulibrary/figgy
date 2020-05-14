# frozen_string_literal: true
require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe NumismaticImportJob do
  describe ".perform" do
    let(:db_path) { "spec/fixtures/numismatics/numismatics.sqlite3" }
    let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
    let(:file_root) { "spec/fixtures/numismatics" }
    let(:collection_id) { FactoryBot.create_for_repository(:collection).id.to_s }
    let(:depositor) { FactoryBot.create(:admin).uid }

    it "imports numismatic resources" do
      perform_enqueued_jobs do
        described_class.perform_later(file_root: file_root, collection_id: collection_id, depositor: depositor, db_path: db_path)
      end

      # places
      place = query_service.find_all_of_model(model: Numismatics::Place).first
      expect(place.city).to eq "city"
      expect(place.geo_state).to eq "state"
      expect(place.region).to eq "region name"
      expect(place.replaces).to eq ["1"]
      expect(place.depositor). to eq [depositor]

      # people
      person = query_service.custom_queries.find_by_property(property: :replaces, value: "person-1").select { |r| r.is_a? Numismatics::Person }.first
      expect(person.name1).to eq ["first name"]
      expect(person.name2).to eq ["family name"]
      expect(person.born).to eq ["born"]
      expect(person.died).to eq ["died"]
      expect(person.class_of).to eq ["class of"]
      expect(person.depositor).to eq [depositor]

      # rulers
      ruler = query_service.custom_queries.find_by_property(property: :replaces, value: "ruler-1").select { |r| r.is_a? Numismatics::Person }.first
      expect(ruler.name1).to eq ["ruler name 1"]
      expect(ruler.name2).to eq ["ruler name 2"]
      expect(ruler.epithet).to eq ["ruler epithet"]
      expect(ruler.family).to eq ["family name"]
      expect(ruler.years_active_start).to eq ["378"]
      expect(ruler.years_active_end).to eq ["395"]

      # child references
      child_reference = query_service.custom_queries.find_by_property(property: :replaces, value: "2").select { |r| r.is_a? Numismatics::Reference }.first
      expect(child_reference.part_of_parent).to eq ["part of parent"]
      expect(child_reference.pub_info).to eq ["pub info"]
      expect(child_reference.short_title).to eq ["child short title"]
      expect(child_reference.title).to eq ["child title"]
      expect(child_reference.year).to eq ["2001"]
      expect(child_reference.replaces).to eq ["2"]

      # parent references
      parent_reference = query_service.custom_queries.find_by_property(property: :replaces, value: "1").select { |r| r.is_a? Numismatics::Reference }.first
      expect(parent_reference.author_id).to eq [person.id]
      expect(parent_reference.pub_info).to eq ["pub info"]
      expect(parent_reference.short_title).to eq ["parent short title"]
      expect(parent_reference.title).to eq ["parent title"]
      expect(parent_reference.year).to eq ["2001"]
      expect(parent_reference.depositor). to eq [depositor]

      # firms
      firm = query_service.find_all_of_model(model: Numismatics::Firm).first
      expect(firm.city).to eq "firm city"
      expect(firm.name).to eq "firm name"
      expect(firm.replaces).to eq ["1"]
      expect(firm.depositor).to eq [depositor]

      # accessions
      accession = query_service.find_all_of_model(model: Numismatics::Accession).first
      accession_citation = accession.numismatic_citation.first
      expect(accession.accession_number).to eq "1"
      expect(accession.account).to eq ["1"]
      expect(accession.cost).to eq [811.49]
      expect(accession.date).to eq ["2004-12-01 00:00:00"]
      expect(accession.items_number).to eq 1
      expect(accession.note).to eq ["info"]
      expect(accession.private_note).to eq ["private info"]
      expect(accession.replaces).to eq ["1"]
      expect(accession.type).to eq ["type"]
      expect(accession.depositor). to eq [depositor]
      expect(accession_citation.numismatic_reference_id).to eq [parent_reference.id]
      expect(accession_citation.part).to eq ["part"]
      expect(accession_citation.number).to eq ["number"]

      # monograms
      monogram = query_service.find_all_of_model(model: Numismatics::Monogram).first
      expect(monogram.title).to eq ["description"]
      expect(monogram.replaces).to eq ["1"]
      expect(monogram.member_ids).not_to be_blank
      expect(monogram.depositor). to eq [depositor]

      # coins
      coin = query_service.find_all_of_model(model: Numismatics::Coin).first
      expect(coin.member_of_collection_ids.first.to_s).to eq collection_id
      expect(coin.numismatic_accession_id).to eq [accession.id]
      expect(coin.find_place_id).to eq [place.id]
      expect(coin.coin_number).to eq 1
      expect(coin.number_in_accession).to eq "1"
      expect(coin.counter_stamp).to eq ["counter stamp"]
      expect(coin.analysis).to eq ["analysis"]
      expect(coin.public_note).to eq ["other info"]
      expect(coin.private_note).to eq ["private info"]
      expect(coin.find_date).to eq ["6/15/1939"]
      expect(coin.find_feature).to eq ["find feature"]
      expect(coin.find_locus).to eq ["find locus"]
      expect(coin.find_description).to eq ["find description"]
      expect(coin.die_axis).to eq [6]
      expect(coin.size).to eq ["19"]
      expect(coin.technique).to eq ["technique"]
      expect(coin.weight).to eq [1.47]
      expect(coin.find_number).to eq ["find number"]
      expect(coin.numismatic_collection).to eq ["collection name"]
      expect(coin.member_ids.count).to eq 2
      expect(coin.depositor). to eq [depositor]

      # nested citation
      coin_citation = coin.numismatic_citation.first
      expect(coin_citation.part).to eq ["part"]
      expect(coin_citation.numismatic_reference_id).to eq [parent_reference.id]
      expect(coin_citation.number).to eq ["number"]

      # nested loan
      loan = coin.loan.first
      expect(loan.firm_id).to eq [firm.id]
      expect(loan.person_id).to eq [person.id]
      expect(loan.date_in).to eq ["2007-12-20 00:00:00"]
      expect(loan.date_out).to eq ["2006-12-20 00:00:00"]
      expect(loan.exhibit_name).to eq ["exhibit name"]
      expect(loan.note).to eq ["note"]
      expect(loan.type).to eq ["type"]

      # nested provenance
      provenance = coin.provenance.first
      expect(provenance.firm_id).to eq [firm.id]
      expect(provenance.person_id).to eq [person.id]
      expect(provenance.date).to eq ["dates"]
      expect(provenance.note).to eq ["note"]

      # issues
      issue = query_service.find_all_of_model(model: Numismatics::Issue).first
      expect(issue.member_of_collection_ids.first.to_s).to eq collection_id
      expect(issue.member_ids).to include coin.id
      expect(issue.member_ids).to include monogram.id
      expect(issue.numismatic_place_id).to eq [place.id]
      expect(issue.ruler_id).to eq [ruler.id]
      expect(issue.master_id).to eq [person.id]
      expect(issue.earliest_date).to eq ["100"]
      expect(issue.latest_date).to eq ["138"]
      expect(issue.color).to eq ["color"]
      expect(issue.denomination).to eq ["denomination name"]
      expect(issue.edge).to eq ["edge"]
      expect(issue.era).to eq ["era"]
      expect(issue.issue_number).to eq 1
      expect(issue.metal).to eq ["metal name"]
      expect(issue.object_date).to eq ["1/1/2019"]
      expect(issue.object_type).to eq ["object type"]
      expect(issue.obverse_figure).to eq ["figure name"]
      expect(issue.obverse_figure_description).to eq ["obv figure description"]
      expect(issue.obverse_figure_relationship).to eq ["obv figure relationship"]
      expect(issue.obverse_legend).to eq ["obv legend"]
      expect(issue.obverse_orientation).to eq ["orientation name"]
      expect(issue.obverse_part).to eq ["part name"]
      expect(issue.obverse_symbol).to eq ["symbol name"]
      expect(issue.reverse_figure).to eq ["figure name"]
      expect(issue.reverse_figure_description).to eq ["rev figure decsription"]
      expect(issue.reverse_figure_relationship).to eq ["rev figure relationship"]
      expect(issue.reverse_legend).to eq ["rev legend"]
      expect(issue.reverse_orientation).to eq ["orientation name"]
      expect(issue.reverse_part).to eq ["part name"]
      expect(issue.reverse_symbol).to eq ["symbol name"]
      expect(issue.series).to eq ["series"]
      expect(issue.shape).to eq ["shape"]
      expect(issue.workshop).to eq ["workshop"]
      expect(issue.depositor). to eq [depositor]

      # nested artist
      artist = issue.numismatic_artist.first
      expect(artist.person_id).to eq [person.id]
      expect(artist.signature).to eq ["signature"]
      expect(artist.role).to eq ["role"]
      expect(artist.side).to eq ["side"]

      # nested citation
      issue_citation = issue.numismatic_citation.first
      expect(issue_citation.part).to eq ["part"]
      expect(issue_citation.numismatic_reference_id).to eq [parent_reference.id]
      expect(issue_citation.number).to eq ["number"]

      # nested note
      note = issue.numismatic_note.first
      expect(note.note).to eq ["note"]
      expect(note.type).to eq ["note type"]

      # nested subject
      issue_subject = issue.numismatic_subject.first
      expect(issue_subject.type).to eq ["subject type"]
      expect(issue_subject.subject).to eq ["subject"]

      # nested obverse attribute
      obv_attr = issue.obverse_attribute.first
      expect(obv_attr.description).to eq ["description"]
      expect(obv_attr.name).to eq ["attribute name"]

      # nested reverse attribute
      rev_attr = issue.reverse_attribute.first
      expect(rev_attr.description).to eq ["description"]
      expect(rev_attr.name).to eq ["attribute name"]
    end
  end
end
