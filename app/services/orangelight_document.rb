# frozen_string_literal: true
class OrangelightDocument
  attr_reader :resource
  delegate :to_json, to: :document

  def initialize(resource)
    @resource = resource
  end

  private

    def document
      builder_klass.new(resource.decorate).build
    end

    def builder_klass
      "Orangelight#{resource.class}Builder".constantize
    rescue
      raise NotImplementedError, "Orangelight document builder for #{resource.class} not implemented."
    end
end
