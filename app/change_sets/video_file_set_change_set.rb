# frozen_string_literal: true
class VideoFileSetChangeSet < FileSetChangeSet
  property :captions_required, required: false, type: Dry::Types["params.bool"], default: true

  def primary_terms
    [
      :title,
      :service_targets,
      :captions_required
    ]
  end
end
