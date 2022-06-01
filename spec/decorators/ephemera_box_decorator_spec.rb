# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraBoxDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:ephemera_box) }
  describe "decoration" do
    it "decorates an EphemeraBox" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it "has a title" do
    expect(decorator.title).to eq("Box 1")
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
  it "can attach folders" do
    expect(resource.decorate.attachable_objects).to include EphemeraFolder
  end
  it "displays a state badge" do
    expect(decorator.rendered_state).to eq("<span class=\"badge badge-default\">New</span>")
  end
  it "exposes a single barcode" do
    expect(decorator.barcode).to eq("00000000000000")
  end
  it "permits public downloads" do
    expect(decorator.downloadable?).to be true
  end
  context "with folders" do
    let(:folder) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:ephemera_folder)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id]) }
    it "retrieves folders" do
      expect(resource.decorate.folders.to_a).not_to be_empty
      expect(resource.decorate.folders.to_a.first).to be_a EphemeraFolder
    end
  end

  describe "#grant_access_state?" do
    context "in state: new" do
      let(:resource) { FactoryBot.build(:ephemera_box, state: "new") }
      it "doesn't grant access" do
        expect(resource.decorate.grant_access_state?).to be false
      end
    end
    context "in state: all_in_production" do
      let(:resource) { FactoryBot.build(:ephemera_box, state: "all_in_production") }
      it "does grant access" do
        expect(resource.decorate.grant_access_state?).to be true
      end
    end
  end

  describe "#members" do
    it "returns a all undecorated members" do
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
      decorator = box.decorate

      expect(decorator.members.map(&:id)).to eq [folder.id]
      expect(decorator.members.map(&:class).uniq).to eq [EphemeraFolder]
    end
  end

  describe "#folders" do
    it "returns all folder members decorated" do
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      resource = FactoryBot.create_for_repository(:scanned_resource)
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id, resource.id])
      decorator = box.decorate

      expect(decorator.folders.map(&:id)).to eq [folder.id]
      expect(decorator.folders.map(&:class).uniq).to eq [EphemeraFolderDecorator]
    end
  end

  describe "#folders_count" do
    it "returns the count of folders" do
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      resource = FactoryBot.create_for_repository(:scanned_resource)
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id, resource.id])
      decorator = box.decorate

      expect(decorator.folders_count).to eq 1
    end
  end

  describe "#ephemera_projects" do
    it "returns all the parent ephemera projects decorated" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id])
      decorator = box.decorate

      expect(decorator.ephemera_projects.map(&:id)).to eq [project.id]
      expect(decorator.ephemera_projects.map(&:class).uniq).to eq [EphemeraProjectDecorator]
    end
  end

  describe "#ephemera_project" do
    context "when a member of a project" do
      it "returns it" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id])
        decorator = box.decorate

        expect(decorator.ephemera_project.id).to eq project.id
        expect(decorator.ephemera_project.class).to eq EphemeraProjectDecorator
      end
    end
    context "when not a member of a project" do
      it "returns a NullProject" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        decorator = box.decorate

        expect(decorator.ephemera_project).to be_a EphemeraBoxDecorator::NullProject
      end
    end
  end
end
