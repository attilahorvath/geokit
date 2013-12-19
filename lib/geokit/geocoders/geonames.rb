module Geokit
  module Geocoders
    # Another geocoding web service
    # http://www.geonames.org
    class GeonamesGeocoder < Geocoder

      private

      # Template method which does the geocode lookup.
      def self.do_geocode(address, options = {})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        # geonames need a space seperated search string
        address_str.gsub!(/,/, " ")
        params = "/postalCodeSearch?placename=#{Geokit::Inflector::url_escape(address_str)}&maxRows=10"

        url = if Geokit::Geocoders::geonames
          "http://ws.geonames.net#{params}&username=#{Geokit::Geocoders::geonames}"
        else
          "http://ws.geonames.org#{params}"
        end

        res = call_geocoder_service(url)

        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)

        xml=res.body
        logger.debug "Geonames geocoding. Address: #{address}. Result: #{xml}"
        parse :xml, xml
      end

      def self.parse_xml(doc)
        return GeoLoc.new unless doc.elements['//geonames/totalResultsCount'].text.to_i > 0
        loc=GeoLoc.new

        # only take the first result
        loc.lat=doc.elements['//code/lat'].text if doc.elements['//code/lat']
        loc.lng=doc.elements['//code/lng'].text if doc.elements['//code/lng']
        loc.country_code=doc.elements['//code/countryCode'].text if doc.elements['//code/countryCode']
        loc.provider='genomes'
        loc.city=doc.elements['//code/name'].text if doc.elements['//code/name']
        loc.state=doc.elements['//code/adminName1'].text if doc.elements['//code/adminName1']
        loc.zip=doc.elements['//code/postalcode'].text if doc.elements['//code/postalcode']
        loc.success=true
        loc
      end
    end
  end
end
