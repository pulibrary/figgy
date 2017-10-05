# frozen_string_literal: true
class HumanReadableTypeIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless decorated_resource.try(:human_readable_type)
    {
      human_readable_type_ssim: decorated_resource.human_readable_type
    }
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end
end
