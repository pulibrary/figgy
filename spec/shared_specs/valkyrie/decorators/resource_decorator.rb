# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a Valkyrie::ResourceDecorator" do
  before do
    raise "resource must be set with `let(:resource)`" unless
      defined? resource
    raise "resource_klass must be set with `let(:resource_klass)`" unless
      defined? resource_klass
  end
  let(:factory_name) { ActiveModel::Naming.param_key(resource_klass) }

  describe "#rendered_rights_statement" do
    it "returns an HTML rights statement" do
      term = ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first)
      expect(decorator.rendered_rights_statement.length).to eq 1
      expect(decorator.rendered_rights_statement.first).to include term.definition
      expect(decorator.rendered_rights_statement.first).to include I18n.t("works.show.attributes.rights_statement.boilerplate")
      expect(decorator.rendered_rights_statement.first).to include "<a href=\"#{RightsStatements.no_known_copyright}\">No Known Copyright</a>"
    end
  end
  describe "#created" do
    let(:resource) do
      FactoryBot.build(factory_name,
        title: "test title",
        created: "01/01/1970")
    end
    it "exposes a formatted string for the created date" do
      expect(decorator.created).to eq ["January 1, 1970"]
    end
  end
  context "within a collection" do
    let(:collection) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:collection)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(factory_name, member_of_collection_ids: [collection.id]) }
    it "retrieves the title of parents" do
      expect(resource.decorate.member_of_collections).not_to be_empty
      expect(resource.decorate.member_of_collections.first).to be_a CollectionDecorator
      expect(resource.decorate.member_of_collections.first.title).to eq "Title"
    end
  end

  describe "#iiif_metadata" do
    context "when viewing a new Scanned Resource" do
      let(:resource) do
        FactoryBot.create_for_repository(factory_name,
          title: ["test title"],
          pdf_type: ["Gray"],
          identifier: ["http://arks.princeton.edu/ark:/88435/5m60qr98h"],
          created: ["01/01/1970"])
      end
      let(:metadata) { resource.decorate.iiif_metadata }

      it "returns iiif attributes in label/value key/val hash pairs" do
        expect(metadata).to be_an Array
        expect(metadata).to include("label" => "Title", "value" => ["test title"])
        expect(metadata).to include("label" => "Identifier", "value" => \
          ["<a href='http://arks.princeton.edu/ark:/88435/5m60qr98h' alt='Identifier'>http://arks.princeton.edu/ark:/88435/5m60qr98h</a>"])
      end
    end
  end

  describe "#first_title" do
    let(:resource) { FactoryBot.create_for_repository(factory_name, title: ["There and back again", "A hobbit's tale"]) }

    it "returns the first title" do
      expect(resource.decorate.first_title).to eq "There and back again"
    end
  end

  describe "#merged_titles" do
    let(:resource) { FactoryBot.create_for_repository(factory_name, title: ["There and back again", "A hobbit's tale"]) }

    it "returns a one-line title string" do
      expect(resource.decorate.merged_titles).to eq "There and back again; A hobbit's tale"
    end
  end

  describe "#titles" do
    let(:resource) { FactoryBot.create_for_repository(factory_name, title: ["There and back again", "A hobbit's tale"]) }

    it "returns the title array" do
      expect(resource.decorate.titles).to eq ["There and back again", "A hobbit's tale"]
    end
  end

  describe "#member_of_collections_value" do
    let(:collection) { FactoryBot.create_for_repository(:collection, title: "My Nietzsche Collection") }
    let(:resource) do
      FactoryBot.create_for_repository(
        factory_name,
        title: ["Menschliches, Allzumenschliches", "Ein Buch für freie Geister"],
        member_of_collection_ids: collection.id
      )
    end

    it "returns the titles of collections" do
      expect(resource.decorate.iiif_metadata).to include("label" => "Member Of Collections", "value" => ["My Nietzsche Collection"])
    end
  end

  describe "#members" do
    let(:child_resource) { FactoryBot.create_for_repository(factory_name) }
    let(:resource) { FactoryBot.create_for_repository(factory_name, member_ids: [child_resource.id]) }

    it "retrieves all member resources" do
      expect(decorator.members.to_a).not_to be_empty
    end
  end
end
