# frozen_string_literal: true

class Shrine
  # Null S3 verifier. Implemented so that every file uploaded isn't immediately
  # re-downloaded. This saves on data transfer.
  class NullVerifier
    def self.verify_checksum(_file, _result)
      true
    end
  end
end
