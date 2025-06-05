module Weather
  class ForecastsController < ApplicationController
    skip_before_action :verify_authenticity_token
    # Skip CSRF token check for API-style usage (e.g., tools, scripts, or mobile apps)

    def create
      address = params[:address]
      return render_error("Please enter a valid address", :bad_request) if address.blank?

      # Convert address to geographic info (lat/lon/zip) using custom service
      location = LocationService.resolve(address)
      return render_error("Could not find location for the address", :unprocessable_entity) if location.nil?

      # Try to retrieve weather info from cache, fallback to API on cache miss
      weather_data, from_cache = CacheService.fetch_weather(location.zip, location.lat, location.lon)
      return render_error("Unable to fetch weather data", :service_unavailable) if weather_data.nil?

      # Extract and send only the relevant parts of the API response
      render json: {
        zip: location.zip,
        from_cache: from_cache, # Helps identify if response was served fast via cache
        temperature: weather_data["main"]["temp"],
        high: weather_data["main"]["temp_max"],
        low: weather_data["main"]["temp_min"],
        description: weather_data["weather"].first["description"].capitalize
      }
    end

    private
    
    # Unified JSON error response format
    def render_error(message, status)
      render json: { error: message }, status: status
    end
  end
end
