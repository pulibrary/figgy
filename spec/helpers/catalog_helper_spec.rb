# frozen_string_literal: true

require "rails_helper"

describe CatalogHelper do
  describe "#render_visibility_label" do
    it "translates to display values" do
      expect(helper.render_visibility_label("open")).to eq("Open")
      expect(helper.render_visibility_label("authenticated")).to eq("Princeton")
      expect(helper.render_visibility_label("on_campus")).to eq("On Campus")
      expect(helper.render_visibility_label("reading_room")).to eq("Reading Room")
      expect(helper.render_visibility_label("restricted")).to eq("Private")
    end

    context "when given a bad visibility value" do
      before do
        allow(Honeybadger).to receive(:notify)
      end
      it "Passes it on, notifies Honeybadger" do
        expect(helper.render_visibility_label("not_a_visibility")).to eq("not_a_visibility")
        expect(Honeybadger).to have_received :notify
      end
    end
  end
end
