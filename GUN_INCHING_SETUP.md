# Gun Inching Feature - Setup Guide

## Overview
The Gun Inching feature allows real-time monitoring of weld counts for each gun. The desktop application broadcasts weld count data over the internet, and the Flutter app displays this information with live updates.

## Architecture

### Data Flow
```
Desktop App → JSON File → Node.js Server → WebSocket/HTTP → Flutter App
```

### Components
1. **Desktop App**: Writes weld count data to `weld_count_data.json`
2. **Node.js Server**: Reads JSON file and broadcasts via WebSocket
3. **Flutter App**: Displays real-time weld counts with gun selector

## Desktop App Integration

### JSON File Format
Create or update `weld_count_data.json` in your project root:

```json
{
  "last_update": "2026-02-17 16:30:45 +05:30",
  "counts": {
    "MB20_Gun1_LH": 23,
    "MB20_Gun3_LH": 7,
    "MB20_Gun3_RH": 12,
    "MB20_Gun2_RH": 12,
    "MB30_Gun1_LH": 62,
    "MB30_Gun2_LH": 50,
    "MB40_Gun1_LH": 52,
    "MB40_Gun2_LH": 21,
    "MB50_Gun1_LH": 21,
    "MB60_Gun1_RH": 51,
    "I193.6": 29,
    "I193.7": 21
  }
}
```

### Field Descriptions
- **last_update**: Timestamp of last update (IST format: "YYYY-MM-DD HH:MM:SS +05:30")
- **counts**: Object containing gun names as keys and weld counts as values
  - **Gun names**: Can be any string (e.g., "MB20_Gun1_LH", "I193.6")
  - **Weld counts**: Integer values representing total welds performed

## Server Configuration

### Enhanced PLC Server (Production)
The enhanced server automatically:
- Loads weld count data from `weld_count_data.json` on startup
- Watches the file for changes and broadcasts updates
- Serves data via REST API and WebSocket

**No code changes needed** - just update the JSON file!

### Mock Server (Development)
The mock server generates random weld count data for testing:
- Starts with random counts (0-1000)
- Increments by 0-3 welds every 5 seconds
- Perfect for testing without real PLC data

## API Endpoints

### REST API

#### Get All Weld Counts
```
GET /api/weld-counts
Headers: x-api-key: FlameApp123$byNevark
```

Response:
```json
{
  "success": true,
  "timestamp": "2026-02-17 10:30:45 +05:30",
  "totalGuns": 5,
  "data": [...]
}
```

#### Get Specific Gun Weld Count
```
GET /api/weld-counts/:gunIndex
Headers: x-api-key: FlameApp123$byNevark
```

### WebSocket

#### Connection
```
ws://your-server-ip:7575
```

#### Message Format
```json
{
  "type": "weld_count_update",
  "timestamp": "2026-02-17 10:30:45 +05:30",
  "data": [...]
}
```

## Flutter App Features

### Gun Inching Page
- **Dropdown Selector**: Choose any gun from the list
- **Real-time Updates**: Weld count updates automatically
- **Large Display**: Easy-to-read weld count
- **Last Updated**: Shows timestamp of last update
- **Offline Support**: Works with cached data when offline
- **Connection Status**: Visual indicator for online/offline state

### Navigation
Access via drawer menu: **Gun Inching** (build icon)

## Setup Steps

### 1. Start the Server

**For Development (Mock Data):**
```bash
node mock_plc_server.js
```

**For Production (Real Data):**
```bash
node enhanced_plc_server.js
```

### 2. Desktop App Integration

Your desktop app should:
1. Write weld count data to `weld_count_data.json`
2. Update the file whenever weld counts change
3. Use proper JSON format (see above)

**Example C# Code:**
```csharp
using System.Text.Json;

var weldData = new {
    last_update = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss +05:30"),
    counts = new Dictionary<string, int> {
        { "MB20_Gun1_LH", 23 },
        { "MB30_Gun1_LH", 62 },
        { "MB40_Gun1_RH", 82 }
    }
};
File.WriteAllText("weld_count_data.json", JsonSerializer.Serialize(weldData, new JsonSerializerOptions { WriteIndented = true }));
```

**Example Python Code:**
```python
import json
from datetime import datetime

weld_data = {
    "last_update": datetime.now().strftime("%Y-%m-%d %H:%M:%S +05:30"),
    "counts": {
        "MB20_Gun1_LH": 23,
        "MB30_Gun1_LH": 62,
        "MB40_Gun1_RH": 82
    }
}
with open('weld_count_data.json', 'w') as f:
    json.dump(weld_data, f, indent=2)
```

### 3. Run Flutter App
```bash
flutter run
```

### 4. Access Gun Inching
1. Login to the app
2. Open drawer menu
3. Select "Gun Inching"
4. Choose a gun from dropdown
5. View real-time weld count

## Internet Connectivity

### Making Server Accessible Over Internet

#### Option 1: Port Forwarding (Recommended for Local Network)
1. Configure router to forward port 7575 to server IP
2. Use public IP address in Flutter app config
3. Ensure firewall allows port 7575

#### Option 2: Cloud Hosting
1. Deploy Node.js server to cloud (AWS, Azure, DigitalOcean)
2. Use HTTPS/WSS for secure connections
3. Update `lib/config/api_config.dart` with cloud URL

#### Option 3: VPN/Tunnel (Most Secure)
1. Use ngrok, localtunnel, or similar service
2. Create secure tunnel to local server
3. Update app config with tunnel URL

### Security Considerations
- Change default API key in production
- Use HTTPS/WSS for internet connections
- Implement proper authentication
- Restrict access by IP if possible
- Monitor for unauthorized access

## Troubleshooting

### No Data Showing
1. Check `weld_count_data.json` exists and has valid JSON
2. Verify server is running and accessible
3. Check API key matches in app and server
4. Look for errors in server console

### Data Not Updating
1. Ensure desktop app is writing to JSON file
2. Check file permissions (server needs read access)
3. Verify WebSocket connection in app
4. Check server logs for file watch errors

### Connection Issues
1. Verify server IP in `lib/config/api_config.dart`
2. Check firewall settings
3. Test API manually: `curl -H "x-api-key: FlameApp123$byNevark" http://SERVER_IP:7575/api/weld-counts`
4. Ensure port 7575 is open

## Performance Notes

- **Update Frequency**: File changes detected immediately
- **Network Efficiency**: Only changed data is broadcast
- **Offline Support**: Last known values cached locally
- **Scalability**: Supports unlimited guns (tested up to 100)

## Future Enhancements

Potential additions:
- Weld count reset functionality
- Historical weld count graphs
- Daily/weekly/monthly statistics
- Export weld count reports
- Alert on weld count milestones
- Multi-user access control

---

**Ready to monitor your gun weld counts in real-time! 🔧**

