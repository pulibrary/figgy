# frozen_string_literal: true
class EventGenerator
  class GeoserverEventGenerator
    attr_reader :rabbit_exchange

    def initialize(rabbit_exchange)
      @rabbit_exchange = rabbit_exchange
    end

    def derivatives_created(record); end

    def derivatives_deleted(record); end

    def record_created(record); end

    def record_deleted(record); end

    def record_updated(record); end

    def record_member_updated(record); end

    def valid?(_)
      false
    end
  end
end
