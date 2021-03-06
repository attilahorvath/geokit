module Geokit
  module Geocoders
    # MapQuest geocoder implementation.  Requires the Geokit::Geocoders::mapquest variable to
    # contain a MapQuest API key.  Conforms to the interface set by the Geocoder class.
    class MapQuestGeocoder < Geocoder

      private

      # Template method which does the reverse-geocode lookup.
      def self.do_reverse_geocode(latlng)
        latlng=LatLng.normalize(latlng)
        url = "http://www.mapquestapi.com/geocoding/v1/reverse?key=#{Geokit::Geocoders::mapquest}&location=#{latlng.lat},#{latlng.lng}"
        res = call_geocoder_service(url)
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        json = res.body
        logger.debug "MapQuest reverse-geocoding. LL: #{latlng}. Result: #{json}"
        parse :json, json, latlng
      end

      # Template method which does the geocode lookup.
      def self.do_geocode(address, options = {})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url = "http://www.mapquestapi.com/geocoding/v1/address?key=#{Geokit::Geocoders::mapquest}&location=#{Geokit::Inflector::url_escape(address_str)}"
        res = call_geocoder_service(url)
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        json = res.body
        logger.debug "Mapquest geocoding. Address: #{address}. Result: #{json}"
        parse :json, json
      end

      def self.parse_json(results)
        return GeoLoc.new unless results['info']['statuscode'] == 0
        loc = nil
        results['results'].each do |result|
          result['locations'].each do |location|
            extracted_geoloc = extract_geoloc(location)
            if loc.nil?
              loc = extracted_geoloc
            else
              loc.all.push(extracted_geoloc)
            end
          end
        end          
        loc
      end

      def self.extract_geoloc(result_json)
        loc = GeoLoc.new
        loc.lat            = result_json['latLng']['lat']
        loc.lng            = result_json['latLng']['lng']
        loc.provider       = 'mapquest'
        set_address_components(result_json, loc)
        set_precision(result_json, loc)
        loc.success = true
        loc
      end

      def self.set_address_components(result_json, loc)
        loc.country_code   = result_json['adminArea1']
        loc.street_address = result_json['street'].to_s.empty? ? nil : result_json['street']
        loc.city           = result_json['adminArea5']
        loc.state          = result_json['adminArea3']
        loc.zip            = result_json['postalCode']
      end

      def self.set_precision(result_json, loc)
        loc.precision = result_json['geocodeQuality']
        loc.accuracy = %w{unknown country state state city zip zip+4 street address building}.index(loc.precision)
      end
    end
  end
end
