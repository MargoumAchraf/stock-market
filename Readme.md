# Stock Market App

A Flutter-based stock market application with user authentication, market browsing, portfolio tracking, and interactive historical charts. The project includes a mobile frontend in `stock_market/` and a lightweight Flask data service in `resource/` that provides sample stock market data.

## Overview

This project lets users:

- Sign up and log in to a personal account
- View a list of live market symbols and prices
- Open a stock detail screen with price history and timeframe filters
- Buy or sell shares with a confirmation dialog
- Track owned holdings in a portfolio dashboard
- Persist user and portfolio data locally with SQLite

## Project Structure

- `stock_market/` — Flutter application
- `stock_market/lib/` — app logic, models, controllers, screens, and services
- `resource/app.py` — Flask API for stock data
- `resource/requirements.txt` — Python dependencies for the backend
- `resource/sample-stocks/` — sample stock CSV data used by the API
- `Readme.md` — project documentation

## Tech Stack

- Flutter / Dart
- SQLite for local persistence
- SharedPreferences for session management
- Flask + Pandas for stock data API
- Docker support for running the backend in a container

## Prerequisites

Before running the app, make sure you have:

- Flutter SDK installed and configured on your machine
- Android Studio / Xcode / an emulator or simulator available
- Python 3.10+ for the backend service
- Docker (optional, for the backend container)

## Running the Backend

1. Open a terminal in the `resource/` directory:

   ```bash
   cd resource
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   python app.py
   ```

2. The Flask service starts on port `5001` by default.

### Alternative: Docker

```bash
cd resource
make run
```

This builds and starts the stock server in a container.

## Running the Flutter App

1. Open a terminal in the `stock_market/` directory:

   ```bash
   cd stock_market
   flutter pub get
   flutter run
   ```

2. Choose a connected device or emulator.

### API Configuration Note

The app currently points to a remote backend URL in `stock_market/lib/controller/Home_controller.dart`.
If you are running the local Flask service, update the `baseUrl` to:

```dart
static const String baseUrl = "http://localhost:5001";
```

## Backend API

The Flask API exposes the following endpoints:

- `GET /stocks_list` — returns the available stock symbols
- `GET /exchange_rate/<symbol>` — returns the latest simulated exchange rate
- `GET /hist/<symbol>?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` — returns historical values for a symbol

Example:

```bash
curl http://localhost:5001/stocks_list
curl http://localhost:5001/exchange_rate/AAPL
curl "http://localhost:5001/hist/AAPL?start_date=2024-01-01&end_date=2024-01-31"
```

## Features in Detail

### Authentication

The app includes login and registration screens and stores the session locally using `SharedPreferences`.

### Market Dashboard

The home screen displays a list of stock symbols with pricing, a portfolio balance summary, and a refresh action to update values.

### Portfolio Management

Users can buy and sell shares through the historical chart screen, and the portfolio page summarizes total invested capital, share count, and per-stock positions.

### Historical Charts

The app includes an interactive chart with day/week/month timeframe selection and a trading panel for executing transactions.

## Development Notes

- Database setup is managed during app startup with `DatabaseHelper.instance.database`.
- Local user and holding persistence is handled via SQLite models and repositories.
- The sample market data is generated from CSV files in `resource/sample-stocks/`.

## License

This project is currently for educational/demo purposes. Add an explicit license file if you plan to distribute or publish it.

## Contributing

Contributions are welcome. For local development, keep the backend and Flutter app in sync by verifying the API base URL and updating the sample data or UI logic as needed.
