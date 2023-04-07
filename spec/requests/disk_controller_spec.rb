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
        expect(json).to include(
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
        get "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/9946093213506421/Vol 2')}.json"
        expect(response).to be_successful
      end
      it "can return directories with periods in it" do
        get "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/test.1')}.json"
        expect(response).to be_successful
      end
      it "returns" do
        get "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready')}.json"

        expect(response).to be_successful
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json).to eq(
          [
            {
              label: "991234563506421",
              path: "studio_new/DPUL/Santa/ready/991234563506421",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/991234563506421')}.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "9917912613506421",
              path: "studio_new/DPUL/Santa/ready/9917912613506421",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/9917912613506421')}.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "9946093213506421",
              path: "studio_new/DPUL/Santa/ready/9946093213506421",
              loadChildrenPath: "/file_browser/disk/#{CGI.escape('studio_new/DPUL/Santa/ready/9946093213506421')}.json",
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
