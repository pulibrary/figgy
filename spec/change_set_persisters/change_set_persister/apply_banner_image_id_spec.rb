require "rails_helper"

RSpec.describe ChangeSetPersister::ApplyBannerImageId do
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:collection) { FactoryBot.build(:collection) }
  let(:change_set) { ChangeSet.for(collection) }

  context "with a banner_image_url that points to a real file in figgy" do
    with_queue_adapter :inline
    it "sets banner_image_id to the id of the parent resource" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      file_set = Wayfinder.for(resource).file_sets.first
      iiif_image_path = ManifestBuilder::PyramidalHelper.new.base_url(file_set)

      change_set.validate(banner_image_url: "#{iiif_image_path}/642,2316,3854,2569/full/0/default.jpg")
      output = change_set_persister.save(change_set: change_set)
      expect(output.banner_image_id).to eq resource.id.to_s
    end
  end

  context "with a banner_image_url that points to a file that is no longer in figgy" do
    it "sets banner_image_id to nil" do
      output = change_set_persister.save(change_set: change_set)
      expect(output.banner_image_id).to be_nil
    end
  end

  context "with a banner_image_url that points to a resource outside figgy" do
    it "sets banner_image_id to nil" do
      change_set.validate(banner_image_url: "https://example.com/iiif/testitem/642,2316,3854,2569/full/0/default.jpg")
      output = change_set_persister.save(change_set: change_set)
      expect(output.banner_image_id).to be_nil
    end
  end

  context "with an empty banner_image_url" do
    it "sets banner_image_id to nil" do
      change_set.validate(banner_image_url: nil)
      output = change_set_persister.save(change_set: change_set)
      expect(output.banner_image_id).to be_nil
    end
  end
end
