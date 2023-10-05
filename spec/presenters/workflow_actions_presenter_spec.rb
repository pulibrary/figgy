# frozen_string_literal: true
require "rails_helper"

RSpec.describe WorkflowActionsPresenter do
  include ActionView::TestCase::Behavior
  include ActionView::Helpers::FormHelper
  include SimpleForm::ActionViewExtensions::FormHelper

  let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set, processing_status: "in process") }

  describe "#render" do
    context "with a resource that has file sets that are in process" do
      it "renders a final state radio button with updated label text" do
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: file_set.id)
        change_set = ChangeSet.for(resource)
        simple_form_for(change_set) do |f|
          html = described_class.for(f)
          expect(html).to include "Resource can't be completed while derivatives are in-process"
        end
      end
    end

    context "with a complete resource" do
      it "renders a final state radio button with an unaltered label text" do
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: file_set.id)
        change_set = ChangeSet.for(resource)
        simple_form_for(change_set) do |f|
          html = described_class.for(f)
          expect(html).to include I18n.t("state.complete.desc")
        end
      end
    end

    context "with a resource that has file sets that are not in process" do
      let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set, processing_status: "processed") }

      it "renders a final state radio button with an unaltered label text" do
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: file_set.id)
        change_set = ChangeSet.for(resource)
        simple_form_for(change_set) do |f|
          html = described_class.for(f)
          expect(html).to include I18n.t("state.complete.desc")
        end
      end
    end
  end
end
