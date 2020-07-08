module CDL
  class EventLogging
    class << self
      def get_patron_group(netid:)
        return false unless netid
        begin
          patron_record = Faraday.get "#{CDL::EligibleItemService.bibdata_base}patron/#{netid}"
        rescue Faraday::Error::ConnectionFailed
          Rails.logger.info("Unable to connect to #{CDL::EligibleItemService.bibdata_base}")
          return false
        end

        if patron_record.status == 403
          Rails.logger.info('403 Not Authorized to Connect to Patron Data Service at '\
                      "#{CDL::EligibleItemService.bibdata_base}/patron/#{netid}")
          return false
        end
        if patron_record.status == 404
          Rails.logger.info("404 Patron #{netid} cannot be found in the Patron Data Service.")
          return false
        end
        if patron_record.status == 500
          Rails.logger.info('Error Patron Data Service.')
          return false
        end
        patron = JSON.parse(patron_record.body).with_indifferent_access
        patron["patron_group"]
      end

      # can I connect to google? return 200
      def google_figgy_base
        Faraday.new(url: "https://www.google-analytics.com/collect?v=1&tid=UA-15870237-29&ua=Figgy&t=event")
      end
      
      # track charge action
      def google_charge_event(resource_id, netid)
        self.google_figgy_base+"&#{cid: resource_id}ec=CDL-Charge&ea=charge&#{el: self.get_patron_group(netid: netid)}"
      end

      # track renewal action
      # def google_renew_event
      # end
    end
  end
end