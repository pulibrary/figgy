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
        false
      end

      def google_charge_event(source_metadata_identifier:, netid:)
        Faraday.post(
          "https://www.google-analytics.com/collect?",
          v: "1",
          tid: "UA-15870237-29",
          ua: "Figgy",
          t: "event",
          cid: SecureRandom.uuid,
          ec: "CDL-#{get_patron_group(netid: netid)}",
          ea: "charge",
          el: source_metadata_identifier
        )
      end
    end
  end
end
