require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe EphemeraProject do
  subject(:project) { described_class.new(title: "test name") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(project.title).to include "test name"
  end
  it "has ordered member_ids" do
    project.member_ids = [1, 2, 3, 3]
    expect(project.member_ids).to eq [1, 2, 3, 3]
  end
  it "has property top_language" do
    expect(project.top_language).to eq []
  end
  it "has a list of contributor_uids" do
    project.contributor_uids = ["tpend"]
    expect(project.contributor_uids).to eq ["tpend"]
  end
  it "has a banner_image_url" do
    project.banner_image_url = "https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/full/!200,150/0/default.jpg"
    expect(project.banner_image_url).to start_with "https"
  end
end
