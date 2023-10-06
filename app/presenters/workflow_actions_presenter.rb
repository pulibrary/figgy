# frozen_string_literal: true
class WorkflowActionsPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper

  def self.for(form)
    new(form: form).render
  end

  attr_reader :change_set, :form, :resource
  def initialize(form:)
    @form = form
    @change_set = form.object
    @resource = change_set.resource
  end

  def render
    form.input :state, as: :radio_buttons,
                       collection: state_collection,
                       required: change_set.required?(:state),
                       label_method: :label,
                       value_method: :value,
                       input_html: input_html,
                       label: false
  end

  private

    def enable_final_state?
      workflow.final_state? || !InProcessOrPending.for(resource)
    end

    def input_html
      if enable_final_state?
        {}
      else
        { class: "disable-final-state" }
      end
    end

    def state_collection
      if enable_final_state?
        collection
      else
        update_final_state_message
      end
    end

    # rubocop:disable Rails/OutputSafety
    def update_final_state_message
      index = collection.find_index { |s| s.value == final_state }
      return collection unless index
      term = collection[index]
      term.label = term.label.gsub(I18n.t("state.#{final_state}.desc"), in_process_message).html_safe
      collection[index] = term
      collection
    end
    # rubocop:enable Rails/OutputSafety

    def in_process_message
      "Resource can't be completed while derivatives are in-process"
    end

    def collection
      @collection ||= ControlledVocabulary.for(:"state_#{workflow_class.to_s.underscore}").all(change_set)
    end

    def workflow_class
      @workflow_class ||= change_set.workflow_class
    end

    def workflow
      @workflow ||= workflow_class.new(change_set.state)
    end

    def final_state
      workflow.final_state.to_s
    end
end
