module Weather
  class CacheService
    CACHE_EXPIRY = 30.minutes # Controls how often fresh data is fetched

    def self.fetch_weather(zip, lat, lon)
      cache_key = "weather_forecast_#{zip}" # Keyed by zip code for simplicity
      cached_data = Rails.cache.read(cache_key)

      # Return cached data if found, along with a flag to indicate it was from cache
      return [cached_data, true] if cached_data.present?

      weather_data = fetch_weather_from_api(lat, lon)

      # Only cache if the API call was successful (OpenWeather returns code 200 on success)
      if weather_data && weather_data["cod"] == 200
        Rails.cache.write(cache_key, weather_data, expires_in: CACHE_EXPIRY)
      end

      # Return the fetched data with `from_cache = false`
      [weather_data, false]
    end

    def self.fetch_weather_from_api(lat, lon)
      api_key = ENV['OPENWEATHER_API_KEY'] # API key stored in env for security    
      
      # Build the API URL with provided lat/lon, requesting metric units
      url = "https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&units=metric&appid=#{api_key}"

      response = HTTParty.get(url)

      # If the request fails (e.g., timeout, invalid key), log the issue for devs
      unless response.success?
        Rails.logger.error("Weather API Error: #{response.code} - #{response.body}")
        return nil
      end

      # Return the parsed JSON response body
      response.parsed_response
    end
  end
end
