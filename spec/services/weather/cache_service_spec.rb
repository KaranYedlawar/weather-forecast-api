require 'rails_helper'
require 'httparty'

RSpec.describe Weather::CacheService, type: :service do
  let(:zip) { "12345" }
  let(:lat) { 12.34 }
  let(:lon) { 56.78 }

  let(:weather_response) do
    {
      "cod" => 200,
      "main" => { "temp" => 26.79, "temp_max" => 26.79, "temp_min" => 26.79 },
      "weather" => [{ "description" => "broken clouds" }],
      "clouds" => { "all" => 57 },
      "wind" => { "speed" => 9.94, "deg" => 218 }
    }
  end
  
  describe ".fetch_weather" do    
    context "when cached data exists" do
      it "returns cached data with from_cache true" do
        # Simulate existing cache by stubbing Rails.cache.read to return weather_response
        allow(Rails.cache).to receive(:read).with("weather_forecast_#{zip}").and_return(weather_response)

        data, from_cache = described_class.fetch_weather(zip, lat, lon)
        expect(data).to eq(weather_response)
        expect(from_cache).to be true
      end
    end

    context "when cache is missing" do
      before do
        allow(Rails.cache).to receive(:read).with("weather_forecast_#{zip}").and_return(nil)
        allow(described_class).to receive(:fetch_weather_from_api).with(lat, lon).and_return(weather_response)
        allow(Rails.cache).to receive(:write)
      end

      it "calls fetch_weather_from_api and caches the result" do
        expect(described_class).to receive(:fetch_weather_from_api).with(lat, lon).and_return(weather_response)
        expect(Rails.cache).to receive(:write).with("weather_forecast_#{zip}", weather_response, expires_in: 30.minutes)

        data, from_cache = described_class.fetch_weather(zip, lat, lon)

        expect(data).to eq(weather_response)
        expect(from_cache).to be false
      end
    end

    context "when API returns error or nil" do
      before do
        allow(Rails.cache).to receive(:read).with("weather_forecast_#{zip}").and_return(nil)
        allow(described_class).to receive(:fetch_weather_from_api).with(lat, lon).and_return(nil)
      end

      it "returns nil and from_cache false" do
        data, from_cache = described_class.fetch_weather(zip, lat, lon)
        expect(data).to be_nil
        expect(from_cache).to be false
      end
    end
  end

  describe ".fetch_weather_from_api" do
    let(:api_key) { "dummy_api_key" }
    let(:url) { "https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&units=metric&appid=#{api_key}" }

    before do
      allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(api_key)
    end

    context "when the API call is successful" do
      let(:response_body) do
        {
          "cod" => 200,
          "main" => { "temp" => 26.5, "temp_max" => 28.0, "temp_min" => 25.0 },
          "weather" => [{ "description" => "clear sky" }]
        }.to_json
      end

      let(:http_response) { instance_double(HTTParty::Response, success?: true, parsed_response: JSON.parse(response_body)) }

      it "returns parsed weather data" do
        expect(HTTParty).to receive(:get).with(url).and_return(http_response)

        result = described_class.fetch_weather_from_api(lat, lon)
        expect(result).to eq(JSON.parse(response_body))
      end
    end

    context "when the API call fails" do
      let(:http_response) { instance_double(HTTParty::Response, success?: false, code: 500, body: "Internal Server Error") }

      it "logs error and returns nil" do
        expect(HTTParty).to receive(:get).with(url).and_return(http_response)
        expect(Rails.logger).to receive(:error).with("Weather API Error: 500 - Internal Server Error")

        result = described_class.fetch_weather_from_api(lat, lon)
        expect(result).to be_nil
      end
    end
  end
end
