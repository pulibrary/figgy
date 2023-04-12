# frozen_string_literal: true

class ReadOnlyError < StandardError; end

class ReadOnlyAdapter < SimpleDelegator
  def persister
    @persister ||= ReadOnlyPersister.new(super)
  end

  class ReadOnlyPersister < SimpleDelegator
    def save(*_args)
      raise ReadOnlyError
    end

    def save_all(*_args)
      raise ReadOnlyError
    end

    def delete(*_args)
      raise ReadOnlyError
    end
  end
end
