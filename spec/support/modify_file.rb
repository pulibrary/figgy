# frozen_string_literal: true

module ModifyFile
  # change the file on disk so it has a different checksum
  def modify_file(file_identifier)
    path = file_identifier.id.gsub("disk://", "")
    File.open(path, "w") do |f|
      f.write "p0wned"
    end
  end
end

RSpec.configure do |config|
  config.include ModifyFile
end
