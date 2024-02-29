# frozen_string_literal: true

# Class to short-circuit characterization if desired
class NullCharacterizationService
  attr_reader :file_set, :persister
  def initialize(file_set:, persister:)
    @file_set = file_set
    @persister = persister
  end

  # This is a no-op, as this class serves to short-circuit the characterization chain
  # The save param is provided for consistency with other charcterization services
  # @param save [Boolean] not used
  # @return [FileNode]
  def characterize(save: false)
    GenerateChecksumJob.perform_later(file_set.id.to_s)
    @file_set
  end

  def valid?
    (target_file.mime_type & valid_mime_types).present?
  end

  def target_file
    @file_set.primary_file
  end

  def valid_mime_types
    ["application/xml; schema=mets", "application/xml; schema=pbcore", "text/vtt"]
  end
end
