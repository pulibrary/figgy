# frozen_string_literal: true
require "rails_helper"

RSpec.describe "FileBrowser/Disk" do
  let(:user) { nil }
  before do
    sign_in(user) if user
  end
  describe "#index" do
    context "when not logged in" do
      it "returns forbidden" do
        get "/file_browser/disk.json"

        expect(response).to be_forbidden
      end
    end
    context "when logged in as staff" do
      let(:user) { FactoryBot.create(:staff) }
      it "returns" do
        get "/file_browser/disk.json"

        expect(response).to be_successful
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json).to eq(
          [
            {
              label: "music",
              path: "music",
              loadChildrenPath: "/file_browser/disk/music.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "numismatics",
              path: "numismatics",
              loadChildrenPath: "/file_browser/disk/numismatics.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "studio_new",
              path: "studio_new",
              loadChildrenPath: "/file_browser/disk/studio_new.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            }
          ]
        )
      end
    end
  end
  describe "#show" do
    context "when not logged in" do
      it "returns forbidden" do
        get "/file_browser/disk/music.json"

        expect(response).to be_forbidden
      end
    end
    context "when logged in as staff" do
      let(:user) { FactoryBot.create(:staff) }
      it "can return directories with spaces in it" do
        get "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/4609321/Vol 2')}.json"
        expect(response).to be_successful
      end
      it "returns" do
        get "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready')}.json"

        expect(response).to be_successful
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json).to eq(
          [
            {
              label: "123456",
              path: "studio_new/DPUL/Santa/ready/123456",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/123456')}.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "1791261",
              path: "studio_new/DPUL/Santa/ready/1791261",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/1791261')}.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "4609321",
              path: "studio_new/DPUL/Santa/ready/4609321",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/4609321')}.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            }
          ]
        )
      end
    end
  end
end
