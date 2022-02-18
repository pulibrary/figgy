# frozen_string_literal: true

require "rails_helper"

RSpec.describe OsdModalHelper do
  describe "#osd_modal_for" do
    context "when not given an ID" do
      it "yields" do
        output = helper.osd_modal_for(nil) do
          "bla"
        end
        expect(output).to eq "bla"
      end
    end
    context "when encountering an error retrieving the derivative" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      let(:manifest_helper_class) { class_double(ManifestBuilder::ManifestHelper).as_stubbed_const(transfer_nested_constants: true) }
      let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }
      before do
        allow(manifest_helper_class).to receive(:new).and_return(manifest_helper)
        allow(manifest_helper).to receive(:manifest_image_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end
      it "generates an empty <span>" do
        expect(helper.osd_modal_for(file_set.id)).to eq "<span></span>"
      end
    end
  end
end
