# FLAME App

FLAME is a Flutter-based industrial monitoring app for tracking gun health, live process values, weld counts, alerts, and daily min/max statistics. It connects to a Node.js PLC API server over HTTP and WebSocket, supports cached/offline fallback, and provides a mobile dashboard for production monitoring.

## Overview

- **Primary use case:** monitor industrial guns from a mobile dashboard
- **Frontend:** Flutter app
- **Backend:** Node.js API/WebSocket server (`enhanced_plc_server.js`)
- **Data sources:** PLC/desktop pipeline, REST APIs, WebSocket events, local cache
- **Primary target:** Android, with Flutter cross-platform compatibility

## Core Features

- Hardcoded login allowlist with exactly 3 supported users
- Optional **Remember Me** using `flutter_secure_storage`
- Drawer-based dashboard navigation
- Real-time gun monitoring
- Historical performance trends with charts
- Daily min/max tracking per gun
- Gun inching / weld count monitoring
- Emergency alerts with optional local notifications
- Configurable server, thresholds, intervals, and connectivity behavior
- Offline fallback using cached data

## App Flow

1. User opens the app and lands on `LoginPage`
2. Credentials are validated against the hardcoded allowlist in `AuthService`
3. If **Remember Me** is enabled, credentials are stored securely on-device
4. User enters `HomePage`
5. From the drawer, user can open:
   - Gun Overview
   - Performance Trends
   - Daily Min/Max
   - Gun Inching
   - Emergency Alerts
   - Settings
6. `ApiService` loads cached data first, starts HTTP polling, and attempts WebSocket live updates
7. Pages render live data, or cached data if connectivity/server access fails

## Authentication

Authentication is intentionally limited to a fixed allowlist in `lib/services/auth_service.dart`.

- Login is **local app validation**, not backend auth
- Only the 3 hardcoded users can sign in
- **Remember Me** stores employee ID/password in secure storage on the device
- Logout clears remembered credentials
- Settings includes logout and credential reset actions

## Pages

### 1. Login
- Employee ID + password sign-in
- Remembered credentials auto-fill when enabled
- Navigates to dashboard on success

### 2. Home / Dashboard
- Central entry page after login
- Drawer navigation for all main modules
- Welcome screen before a module is selected

### 3. Gun Overview
- Loads all current gun data
- Shows connection/cached-data status
- Displays health summaries and gun status details
- Uses threshold-aware health classification

### 4. Performance Trends
- Loads historical flow and temperature data per gun
- Supports multiple time ranges: `1H`, `6H`, `12H`, `24H`, `7D`, `30D`
- Uses chart downsampling for smoother rendering
- Sorts/deduplicates timestamps and inserts gap breaks to avoid misleading chart lines
- Subscribes to live updates and refreshes periodically

### 5. Daily Min/Max
- Tracks each gun's minimum and maximum flow/temperature values for the current day
- Combines current live values with persisted daily min/max values
- Resets automatically when a new day starts

### 6. Gun Inching
- Displays weld count data per gun
- Includes dropdown gun selector
- Updates in real time from API/WebSocket stream
- Shows cached data if offline

### 7. Emergency Alerts
- Loads active alerts from server or cache
- Sorts critical alerts first
- Supports pull-to-refresh and live stream updates
- Integrates with local notifications when enabled

### 8. Settings
- Server IP / URL and port configuration
- API key entry
- HTTP timeout, reconnect interval, and polling interval settings
- Alert threshold settings
- Notification, WebSocket, and offline mode toggles
- Logout and credential reset actions

## Data Architecture

### API + WebSocket
`ApiService` is the central data layer.

- Initializes settings and min/max services
- Loads cached guns, alerts, and weld counts from `SharedPreferences`
- Starts HTTP polling
- Connects to WebSocket when enabled
- Pushes live data through broadcast streams

### HTTP Endpoints Used
- `GET /api/guns`
- `GET /api/guns/:gunIndex`
- `GET /api/alerts`
- `GET /api/weld-counts`
- `GET /api/weld-counts/:gunIndex`
- `GET /api/history?gunName=...&range=...`

### WebSocket Event Types Used
- `sensor_update`
- `initial_data`
- `alert_update`
- `weld_count_update`

### Offline / Cached Mode
- Cached guns, alerts, and weld counts are stored locally
- If network/server access fails, pages fall back to cached data
- UI surfaces cached/offline status to the user

## Min/Max Tracking

`MinMaxService`:

- Stores daily min/max per gun in `SharedPreferences`
- Updates from live/current gun data
- Persists `minFlow`, `maxFlow`, `minTemp`, `maxTemp`
- Clears/reset data automatically on day change

## Notifications

`NotificationService`:

- Subscribes to alert stream from `ApiService`
- Sends local notifications for new alerts when enabled
- Requests platform notification permissions
- Avoids repeated notifications for the same alert within a cooldown window

## Weld Count / Gun Inching Integration

The backend supports weld count ingestion from a desktop/PLC-side JSON flow.

High-level flow:

`Desktop App / PLC Source -> JSON / Server Input -> Node.js API Server -> Flutter App`

Related docs already in the repo:

- `GUN_INCHING_SETUP.md`
- `WELD_COUNT_INTEGRATION.md`

## Tech Stack

### Flutter App
- Flutter / Dart
- Material 3 UI
- `http`
- `web_socket_channel`
- `shared_preferences`
- `flutter_secure_storage`
- `connectivity_plus`
- `flutter_local_notifications`
- `fl_chart`
- `pie_chart`
- `google_fonts`

### Backend
- Node.js
- Express
- WebSocket (`ws`)
- `ethernet-ip`
- `cors`

## Project Structure

- `lib/main.dart` - app entry point
- `lib/pages/` - app screens
- `lib/services/` - API, settings, notifications, auth, min/max
- `lib/models/` - gun, alert, weld count models
- `lib/utils/` - credential helper wrapper
- `lib/config/` - legacy/static config helpers
- `enhanced_plc_server.js` - main Node backend entry
- `package.json` - backend dependencies/scripts

## Setup

### Flutter App
1. Install Flutter dependencies:
   - `flutter pub get`
2. Run the app:
   - `flutter run`

### Backend Server
1. Install Node dependencies:
   - `npm install`
2. Start server:
   - `npm start`

## Configuration

Most runtime settings are managed from the in-app **Settings** page:

- Server IP / URL
- Port
- API key
- Timeout values
- Reconnect interval
- Poll interval
- Alert thresholds
- Notification / WebSocket / offline toggles

Notes:

- The API key field is intentionally blank by default in Settings UI
- `SettingsService` still contains default fallback values used if nothing is saved

## Development Notes

- `ApiConfig` still exists for cache keys and legacy defaults
- Current authentication is fixed-user and app-local, not a full identity system
- Remembered credentials are stored securely, but login validation itself is hardcoded

## Validation Status

The recent production-readiness pass completed these checks:

- `flutter analyze` -> passed with **no issues**
- `flutter build apk --debug` -> passed
- `flutter test` -> no `test/` directory exists in the repository

Generated artifact during validation:

- `build/app/outputs/flutter-apk/app-debug.apk`

## Known Limitations

- No automated Flutter test suite is currently present
- Authentication is not backed by a remote auth service
- Default settings/service fallbacks still exist in code for convenience
- Backend/API deployment and PLC connectivity must be configured per environment

## Related Repository Docs

- `SETUP_GUIDE.md`
- `CREDENTIALS_GUIDE.md`
- `GUN_INCHING_SETUP.md`
- `WELD_COUNT_INTEGRATION.md`
- `PERFORMANCE_UPGRADES_APPLIED.md`

## Summary

FLAME is a production-oriented monitoring app for real-time industrial gun visibility, combining live telemetry, historical trends, alerts, weld count tracking, daily min/max analytics, local caching, and configurable connectivity in a mobile Flutter client backed by a Node.js PLC API server.
