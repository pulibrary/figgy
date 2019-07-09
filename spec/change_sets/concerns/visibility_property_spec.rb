# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisibilityProperty do
  before do
    class DummyChangeSet < ChangeSet
      delegate :human_readable_type, to: :model

      include VisibilityProperty
      validates :visibility, presence: true
      property :read_groups, multiple: true, required: false
    end
  end

  after do
    Object.send(:remove_const, :DummyChangeSet)
  end

  describe "#visibility=" do
    it "sets public read group" do
      change_set = DummyChangeSet.new(FactoryBot.build(:pending_private_scanned_resource))
      expect { change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }.to change { change_set.read_groups }
        .to([Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC])
    end

    it "sets authenticated read group" do
      change_set = DummyChangeSet.new(FactoryBot.build(:scanned_resource))
      expect { change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }.to change { change_set.read_groups }
        .to([Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED])
    end

    it "sets private read group" do
      change_set = DummyChangeSet.new(FactoryBot.build(:scanned_resource))
      expect { change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }.to change { change_set.read_groups }
        .to([])
    end

    it "sets reading_room read group" do
      change_set = DummyChangeSet.new(FactoryBot.build(:scanned_resource))
      expect { change_set.visibility = ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_READING_ROOM }.to change { change_set.read_groups }
        .to([::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_READING_ROOM])
    end
  end
end
