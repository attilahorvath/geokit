module Geokit
  module Geocoders
    class FCCGeocoder < Geocoder

      private
      # Template method which does the reverse-geocode lookup.
      def self.do_reverse_geocode(latlng)
        latlng=LatLng.normalize(latlng)
        url = "http://data.fcc.gov/api/block/find?format=json&latitude=#{Geokit::Inflector::url_escape(latlng.lat.to_s)}&longitude=#{Geokit::Inflector::url_escape(latlng.lng.to_s)}"
        res = call_geocoder_service(url)
        return GeoLoc.new unless (res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPOK))
        json = res.body
        logger.debug "FCC reverse-geocoding. LL: #{latlng}. Result: #{json}"
        parse :json, json
      end

      # Template method which does the geocode lookup.
      #
      # ==== EXAMPLES
      # ll=Geokit::LatLng.new(40, -85)
      # Geokit::Geocoders::FCCGeocoder.geocode(ll) #

      # JSON result looks like this
      # => {"County"=>{"name"=>"Wayne", "FIPS"=>"18177"},
      # "Block"=>{"FIPS"=>"181770103002004"},
      # "executionTime"=>"0.099",
      # "State"=>{"name"=>"Indiana", "code"=>"IN", "FIPS"=>"18"},
      # "status"=>"OK"}

      def self.parse_json(results)
        if results.has_key?('Err') && results['Err']["msg"] == 'There are no results for this location'
          return GeoLoc.new
        end
        # this should probably be smarter.
        if !results['status'] == 'OK'
          raise Geokit::Geocoders::GeocodeError
        end

        loc = GeoLoc.new
        loc.provider      = 'fcc'
        loc.success       = true
        loc.precision     = 'block'
        loc.country_code  = 'US'
        loc.district      = results['County']['name']
        loc.district_fips = results['County']['FIPS']
        loc.state         = results['State']['code']
        loc.state_fips    = results['State']['FIPS']
        loc.block_fips    = results['Block']['FIPS']
        loc
      end
    end

  end
end
