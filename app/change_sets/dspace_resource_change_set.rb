# frozen_string_literal: true
class DspaceResourceChangeSet < ScannedResourceChangeSet
  def apply_remote_metadata?
    false
  end
end
