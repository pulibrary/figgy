# frozen_string_literal: true
class METSDocument
  class Factory
    attr_reader :mets
    def initialize(mets)
      @mets = METSDocument.new(mets)
    end

    def new
      mets
    end
  end
end
