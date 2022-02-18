# frozen_string_literal: true

class TimePeriod
  attr_accessor :doc, :initial_value
  def initialize(initial_value, doc)
    @initial_value = initial_value || []
    @doc = doc
  end

  def value
    append_caldate
    append_begdate
    initial_value.uniq!
    initial_value
  end

  private

    def append_caldate
      doc.at_xpath("//idinfo/timeperd/timeinfo/mdattim/sngdate/caldate | //idinfo/timeperd/timeinfo/sngdate/caldate").tap do |node|
        initial_value << node.text[0..3] unless node.nil? # extract year only
      end
    end

    def append_begdate
      doc.at_xpath("//idinfo/timeperd/timeinfo/rngdates/begdate").tap do |node|
        initial_value << node.text[0..3] unless node.nil? # extract year only
      end
    end
end
