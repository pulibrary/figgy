# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraProjectDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_project, top_language: [term.id]) }
  let(:term) { FactoryBot.create_for_repository(:ephemera_term) }

  describe "decoration" do
    it "decorates an EphemeraProject" do
      expect(resource.decorate).to be_a described_class
    end
  end

  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end

  it "does not order files" do
    expect(decorator.orderable_files?).to be false
  end

  it "does not manage structures" do
    expect(decorator.manageable_structure?).to be false
  end

  describe "#slug" do
    it "generates a slug" do
      expect(decorator.slug).to eq "test_project-1234"
    end
  end

  describe "#iiif_manifest_attributes" do
    it 'includes the "exhibit" property in the IIIF Manifest metadata' do
      expect(decorator.iiif_manifest_attributes).to include(exhibit: "test_project-1234")
    end
  end

  describe "#top_language" do
    it "returns an array of terms" do
      expect(decorator.top_language.size).to eq 1
      expect(decorator.top_language.first.id).to eq term.id
    end
  end

  context "when there are folders and boxes attached" do
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id]) }

    it "provides access to folders" do
      expect(decorator.folders.map(&:id)).to eq([folder.id])
    end

    it "provides access to boxes" do
      expect(decorator.boxes.map(&:id)).to eq([box.id])
    end
  end

  describe "#members" do
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id]) }
    it "returns all members undecorated" do
      expect(decorator.members.map(&:id)).to eq [box.id, folder.id]
      expect(decorator.members.map(&:class)).to eq [EphemeraBox, EphemeraFolder]
    end
  end

  describe "#boxes" do
    it "returns all box members, decorated" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id])

      decorator = project.decorate

      expect(decorator.boxes.map(&:id)).to eq [box.id]
      expect(decorator.boxes.map(&:class)).to eq [EphemeraBoxDecorator]
    end
  end

  describe "#folders" do
    it "returns all folder members, decorated" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id])

      decorator = project.decorate

      expect(decorator.folders.map(&:id)).to eq [folder.id]
      expect(decorator.folders.map(&:class)).to eq [EphemeraFolderDecorator]
    end
  end

  describe "#fields" do
    it "returns all EphemeraField members, decorated" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      field = FactoryBot.create_for_repository(:ephemera_field)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id, field.id])

      decorator = project.decorate

      expect(decorator.fields.map(&:id)).to eq [field.id]
      expect(decorator.fields.map(&:class)).to eq [EphemeraFieldDecorator]
    end
  end

  describe "#templates" do
    it "returns all templates, decorated" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      template = FactoryBot.create_for_repository(:template, parent_id: project.id)

      decorator = project.decorate

      expect(decorator.templates.map(&:id)).to eq [template.id]
      expect(decorator.templates.map(&:class)).to eq [TemplateDecorator]
    end
  end

  describe "#folders_count" do
    it "returns the count of folder members" do
      project = FactoryBot.create_for_repository(
        :ephemera_project,
        member_ids: [
          FactoryBot.create_for_repository(:ephemera_folder).id,
          FactoryBot.create_for_repository(:ephemera_folder).id
        ]
      )

      decorator = project.decorate

      expect(decorator.folders_count).to eq 2
    end
  end
end
