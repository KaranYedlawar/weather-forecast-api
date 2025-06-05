require 'rails_helper'

RSpec.describe "Weather Forecasts API", type: :request do
  describe "POST /weather/forecasts" do
    let(:address) { "Madhapur, Hyderabad, Telangana, India" }

    before do
      # Stub geocoder response to simulate a real location lookup
      geocoder_result = double("Location",
        data: { "address" => { "postcode" => "500081" } },
        latitude: 17.4401,
        longitude: 78.3489
      )
      allow(Geocoder).to receive(:search).with(address).and_return([geocoder_result])

      # Stub weather API to simulate a successful weather data fetch (bypasses real API)
      fake_weather = {
        "cod" => 200,
        "main" => {
          "temp" => 32.5,
          "temp_max" => 35.0,
          "temp_min" => 29.0
        },
        "weather" => [
          { "description" => "clear sky" }
        ]
      }
      allow(Weather::CacheService).to receive(:fetch_weather)
        .with("500081", 17.4401, 78.3489)
        .and_return([fake_weather, false])
    end

    it "returns weather data from cache" do
      cached_weather = {
        "cod" => 200,
        "main" => {
          "temp" => 30.0,
          "temp_max" => 33.0,
          "temp_min" => 27.0
        },
        "weather" => [{ "description" => "haze" }]
      }

      allow(Weather::CacheService).to receive(:fetch_weather)
        .with("500081", 17.4401, 78.3489)
        .and_return([cached_weather, true])

      post "/weather/forecasts", params: { address: address }

      json = JSON.parse(response.body)

      expect(json["from_cache"]).to eq(true)
      expect(json["description"]).to eq("Haze")
    end

    it "returns weather data for valid address" do
      post "/weather/forecasts", params: { address: address }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["message"]).to eq("Weather data retrieved successfully")
      expect(json["zip"]).to eq("500081")
      expect(json["from_cache"]).to eq(false)
      expect(json["temperature"]).to eq(32.5)
      expect(json["high"]).to eq(35.0)
      expect(json["low"]).to eq(29.0)
      expect(json["description"]).to eq("Clear sky")
    end

    it "returns error for missing address" do
      post "/weather/forecasts", params: { address: "" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to eq("Please enter a valid address")
    end
  end
end
