# frozen_string_literal: true

class RightsLabelIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless decorated_resource.try(:rights_statement)
    {
      rights_ssim: label_for(Array.wrap(decorated_resource.rights_statement).first)
    }
  end

  private

    def decorated_resource
      @decorated_resource ||= resource.decorate
    end

    def label_for(uri)
      ControlledVocabulary.for(:rights_statement).all.find { |term| term.value == uri.to_s }&.label
    end
end
