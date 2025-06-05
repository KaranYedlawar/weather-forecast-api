# Weather Forecast API

A Ruby on Rails API service that accepts a user-provided address and returns the current weather forecast using OpenWeatherMap. It uses **Redis** for caching and **Geocoder** for resolving location details.

## Features

- Accepts user-friendly addresses (e.g., `"Madhapur, Hyderabad"`)
- Resolves to ZIP code, latitude, and longitude
- Fetches real-time weather data from **OpenWeatherMap**
- Caches weather data per ZIP code for 30 minutes using **Redis**
- Provides clean JSON responses with temperature and description
- Gracefully handles invalid input or external API failure
- Fully tested using **RSpec** with **SimpleCov** test coverage

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/KaranYedlawar/weather-forecast-api.git
cd weather-forecast-api
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Set Environment Variables

Create a `.env` file and add:

```
OPENWEATHER_API_KEY=your_openweathermap_api_key
```

You can get your API key from [OpenWeatherMap](https://openweathermap.org/api)

### 4. Run Redis

Ensure Redis is installed and running locally.

For macOS:

```bash
brew install redis
redis-server
```

### 5. Start the Rails Server

```bash
rails server
```

## API Usage

### POST `/weather/forecasts`

#### Request Body (JSON):

```json
{
  "address": "Madhapur, Hyderabad, Telangana, India"
}
```

#### Sample Response:

```json
{
  "message": "Weather data retrieved successfully",
  "zip": "500081",
  "from_cache": false,
  "temperature": 32.5,
  "high": 35.0,
  "low": 29.0,
  "description": "Clear sky"
}
```

## Running Tests

Run the RSpec test suite:

```bash
bundle exec rspec
```

To check test coverage with SimpleCov:

```bash
open coverage/index.html
```

## Project Structure

```
app/
├── controllers/
│   └── weather/
│       └── forecasts_controller.rb
├── services/
│   └── weather/
│       ├── cache_service.rb
│       └── location_service.rb
```

## Dependencies Used

| Gem            | Purpose                             |
|----------------|-------------------------------------|
| `byebug`       | Debugging during development        |
| `dotenv-rails` | Environment variable management     |
| `simplecov`    | Code coverage for tests             |
| `httparty`     | HTTP client for API requests        |
| `redis`        | In-memory caching store             |
| `geocoder`     | Address to coordinates and ZIP code |
| `rspec-rails`  | Testing framework for Rails         |


## Notes

- Caching is handled using `Rails.cache`, backed by Redis.
- Weather data is cached **per ZIP code** for 30 minutes.
- `skip_before_action :verify_authenticity_token` is used in the controller since this is a JSON API and CSRF protection is not needed for API clients.

## Author
Karan Yedlawar
