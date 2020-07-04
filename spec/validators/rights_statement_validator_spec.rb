# frozen_string_literal: true
require "rails_helper"

RSpec.describe RightsStatementValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    context "when rights_statement is valid" do
      it "does not add errors" do
        rights_statement = RightsStatements.no_known_copyright
        resource = FactoryBot.build(:scanned_resource)
        change_set = ChangeSet.for(resource, rights_statement: rights_statement)

        validator.validate(change_set)
        expect(change_set.errors).to be_blank
      end
    end

    context "when rights_statement is invalid" do
      it "adds an error" do
        rights_statement = RDF::URI.new("http://rightsstatements.org/vocab/BAD/1.0/")
        resource = FactoryBot.build(:scanned_resource)
        change_set = ChangeSet.for(resource, rights_statement: rights_statement)

        validator.validate(change_set)
        expect(change_set.errors[:rights_statement]).to eq ["#{rights_statement} is not a valid rights_statement"]
      end
    end

    context "when rights_statement is nil" do
      it "adds an error" do
        resource = FactoryBot.build(:scanned_resource)
        change_set = ChangeSet.for(resource, rights_statement: nil)

        validator.validate(change_set)
        expect(change_set.errors[:rights_statement]).to eq [" is not a valid rights_statement"]
      end
    end

    context "when rights_statement is blank" do
      it "adds an error" do
        resource = FactoryBot.build(:scanned_resource)
        change_set = ChangeSet.for(resource, rights_statement: "")

        validator.validate(change_set)
        expect(change_set.errors[:rights_statement]).to eq [" is not a valid rights_statement"]
      end
    end
  end
end
