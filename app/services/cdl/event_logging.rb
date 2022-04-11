# frozen_string_literal: true

module CDL
  class EventLogging
    class << self
      def get_patron_group(netid:)
        return false unless netid
        patron_record = Faraday.get "#{CDL::EligibleItemService.bibdata_base}patron/#{netid}"
        if patron_record.status == 200
          patron = JSON.parse(patron_record.body).with_indifferent_access
          patron["patron_group"]
        end
      rescue
        nil
      end

      def google_charge_event(source_metadata_identifier:, netid:)
        google_event(action: "charge", netid: netid, source_metadata_identifier: source_metadata_identifier)
      end

      def google_hold_event(source_metadata_identifier:, netid:, hold_queue_size:)
        google_event(action: "hold", netid: netid, source_metadata_identifier: source_metadata_identifier, value: hold_queue_size)
      end

      def google_hold_charged_event(source_metadata_identifier:, netid:)
        google_event(action: "hold-charged", netid: netid, source_metadata_identifier: source_metadata_identifier)
      end

      def google_hold_expired_event(source_metadata_identifier:, netid:)
        google_event(action: "hold-expired", netid: netid, source_metadata_identifier: source_metadata_identifier)
      end

      def google_event(action:, netid:, source_metadata_identifier:, value: nil)
        params = {
          v: "1",
          tid: "UA-15870237-29",
          ua: "Figgy",
          t: "event",
          cid: SecureRandom.uuid,
          ec: "CDL-#{get_patron_group(netid: netid)}",
          ea: action,
          el: source_metadata_identifier,
          ev: value
        }.compact
        Faraday.post("https://www.google-analytics.com/collect?", params)
      end
    end
  end
end
