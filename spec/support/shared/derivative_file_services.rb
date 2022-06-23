# frozen_string_literal: true
class LocalFileService
  def self.call(file_name, _options, &_block)
    yield File.open(file_name)
  end
end

class OutputFileService
  def self.call(content, directives)
    FileUtils.cp(content, directives.fetch(:url).path)
  end
end
