# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediaResourceDecorator do
  describe "#file_sets" do
    it "returns all file set members" do
      file_set = FactoryBot.create_for_repository(:file_set)
      media_resource = FactoryBot.create_for_repository(:media_resource, member_ids: [file_set.id])

      decorator = described_class.new(media_resource)

      expect(decorator.file_sets.map(&:id)).to eq [file_set.id]
      expect(decorator.file_sets.map(&:class)).to eq [FileSetDecorator]
    end
  end
end
