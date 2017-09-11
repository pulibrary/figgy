# frozen_string_literal: true
class PlumChangeSetPersister
  class CreateFiles
    PlumChangeSetPersister.register_handler(:before_save, self)
    attr_reader :change_set_persister, :change_set
    delegate :file_appender, :persister, :storage_adapter, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      appender = file_appender.new(storage_adapter: storage_adapter, persister: persister, files: files)
      change_set_persister.instance_variable_set(:@created_file_sets, appender.append_to(change_set.resource))
    end

    def files
      change_set.try(:files) || []
    end
  end
end
