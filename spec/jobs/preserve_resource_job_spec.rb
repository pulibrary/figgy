# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreserveResourceJob do
  it "does not error when given a non-existent ID" do
    expect { described_class.perform_now(id: "none") }.not_to raise_error
  end

  context "when passing in serialized lock tokens" do
    before do
      allow(Preserver).to receive(:for).and_return(Preserver::NullPreserver)
    end

    context "with a FileSet and the tokens are valid" do
      it "preserves the resource" do
        fs = FactoryBot.create_for_repository(:file_set)
        valid_tokens = fs[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        valid_tokens.map!(&:serialize)

        described_class.perform_now(id: fs.id, lock_tokens: valid_tokens)
        expect(Preserver).to have_received(:for)
      end
    end

    context "with a FileSet and the tokens are invalid" do
      it "exits early" do
        fs = FactoryBot.create_for_repository(:file_set)
        invalid_tokens = ["lock_token:token:99"]

        described_class.perform_now(id: fs.id, lock_tokens: invalid_tokens)
        expect(Preserver).not_to have_received(:for)
      end
    end

    context "when the force preservation parameter is set to true" do
      it "calls the preserver with the force_preservation parameter" do
        fs = FactoryBot.create_for_repository(:file_set)
        valid_tokens = fs[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        valid_tokens.map!(&:serialize)

        described_class.perform_now(id: fs.id, lock_tokens: valid_tokens, force_preservation: true)
        expect(Preserver).to have_received(:for).with(hash_including(force_preservation: true))
      end
    end
  end
end
