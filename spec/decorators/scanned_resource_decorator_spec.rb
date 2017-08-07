# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:scanned_resource) }
  describe "#rendered_rights_statement" do
    it "returns an HTML rights statement" do
      term = ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first)
      expect(decorator.rendered_rights_statement.length).to eq 1
      expect(decorator.rendered_rights_statement.first).to include term.definition
      expect(decorator.rendered_rights_statement.first).to include I18n.t("valhalla.works.show.attributes.rights_statement.boilerplate")
      expect(decorator.rendered_rights_statement.first).to include '<a href="http://rightsstatements.org/vocab/NKC/1.0/">No Known Copyright</a>'
    end
  end
end
