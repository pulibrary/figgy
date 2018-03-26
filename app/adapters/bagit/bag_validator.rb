# frozen_string_literal: true
module Bagit
  class BagValidator
    # @param bag_path [Pathname] root directory of the bag
    # @return [bool]
    def self.validate(bag_path:)
      cmd = "bagit.py --validate #{bag_path}"
      _, status = Open3.capture2e(cmd)
      status.success?
    end
  end
end
