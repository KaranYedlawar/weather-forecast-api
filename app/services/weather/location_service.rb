module Weather
  class LocationService
    # Simple value object to carry zip, latitude, and longitude together
    Location = Struct.new(:zip, :lat, :lon)

    def self.resolve(address)
      # Perform address lookup using Geocoder; returns an array of results
      location = Geocoder.search(address)&.first
      return nil if location.nil?

      # Dig into the raw API response to find postal code
      zip = location.data.dig("address", "postcode")
      lat = location.latitude
      lon = location.longitude

      return nil if zip.blank? || lat.blank? || lon.blank?
      
      # Return a strongly-typed Location object
      Location.new(zip, lat, lon)
    end
  end
end
