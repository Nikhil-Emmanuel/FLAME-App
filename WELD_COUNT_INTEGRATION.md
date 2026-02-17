# Weld Count Integration - Updated for Your Schema

## ✅ What Was Updated

The Gun Inching feature has been **fully updated** to work with your actual weld count JSON schema from your desktop application.

### Your Actual Schema
```json
{
  "last_update": "2025-12-08 21:31:14.796",
  "counts": {
    "MB20_Gun1_LH": 23,
    "MB20_Gun3_LH": 7,
    "MB20_Gun3_RH": 12,
    "MB30_Gun1_LH": 62,
    "MB30_Gun2_LH": 50,
    "MB40_Gun1_RH": 82,
    "MB60_Gun1_LH": 46,
    "I193.6": 29,
    "I193.7": 21
  }
}
```

## 🔄 Backend Changes

### Both Servers Updated
- ✅ **mock_plc_server.js** - Generates data in your schema format
- ✅ **enhanced_plc_server.js** - Reads your actual JSON file

### Key Updates
1. **Data Structure**: Changed from array to nested object with `last_update` and `counts`
2. **Gun Names**: Supports your naming convention (MB20_Gun1_LH, I193.6, etc.)
3. **API Conversion**: Automatically converts to array format for Flutter app
4. **WebSocket Broadcasting**: Sends updates in Flutter-compatible format

### API Endpoints (No Changes Needed in Flutter)
The servers automatically convert your schema to the format the Flutter app expects:

**Your JSON File:**
```json
{
  "last_update": "2026-02-17 16:30:45 +05:30",
  "counts": {
    "MB20_Gun1_LH": 23,
    "MB30_Gun1_LH": 62
  }
}
```

**Converted to Flutter Format:**
```json
{
  "success": true,
  "timestamp": "2026-02-17 16:30:45 +05:30",
  "totalGuns": 2,
  "data": [
    {
      "gunIndex": 1,
      "gunName": "MB20_Gun1_LH",
      "weldCount": 23,
      "lastUpdated": "2026-02-17 16:30:45 +05:30"
    },
    {
      "gunIndex": 2,
      "gunName": "MB30_Gun1_LH",
      "weldCount": 62,
      "lastUpdated": "2026-02-17 16:30:45 +05:30"
    }
  ]
}
```

## 📱 Flutter App (No Changes Needed)

The Flutter app continues to work exactly as before! The data model and UI remain unchanged because the backend handles the conversion.

## 🚀 How to Use

### Option 1: Testing with Mock Server

1. **Start mock server:**
   ```bash
   node mock_plc_server.js
   ```

2. **Mock server will:**
   - Generate realistic gun names (MB20_Gun1_LH, MB30_Gun2_RH, etc.)
   - Start with random counts (0-100)
   - Increment by 0-3 every 5 seconds
   - Save to `weld_count_data.json`

3. **Run Flutter app:**
   ```bash
   flutter run
   ```

### Option 2: Production with Your Desktop App

1. **Your desktop app writes to `weld_count_data.json`:**
   ```json
   {
     "last_update": "2026-02-17 16:30:45 +05:30",
     "counts": {
       "MB20_Gun1_LH": 23,
       "MB20_Gun3_LH": 7,
       ...
     }
   }
   ```

2. **Start enhanced server:**
   ```bash
   node enhanced_plc_server.js
   ```

3. **Server automatically:**
   - Loads the JSON file on startup
   - Watches for file changes
   - Broadcasts updates to Flutter app in real-time

4. **Run Flutter app:**
   ```bash
   flutter run
   ```

## 📍 File Location

**Important:** The server looks for `weld_count_data.json` in the **project root directory** (same folder as the server files).

Your desktop app should write to:
```
e:\FLAME\FLAME APP\flame\weld_count_data.json
```

Or you can copy your existing file from:
```
e:\FLAME\FLAME Backup\F.L.A.M.E\Assets\weld_counts.json
```
to:
```
e:\FLAME\FLAME APP\flame\weld_count_data.json
```

## 🔧 Desktop App Integration

Your desktop app just needs to write the JSON file in the correct format. The server handles everything else!

### C# Example
```csharp
var weldData = new {
    last_update = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss +05:30"),
    counts = new Dictionary<string, int> {
        { "MB20_Gun1_LH", 23 },
        { "MB20_Gun3_LH", 7 },
        { "MB30_Gun1_LH", 62 }
    }
};
File.WriteAllText(@"e:\FLAME\FLAME APP\flame\weld_count_data.json", 
    JsonSerializer.Serialize(weldData, new JsonSerializerOptions { WriteIndented = true }));
```

### Python Example
```python
import json

weld_data = {
    "last_update": "2026-02-17 16:30:45 +05:30",
    "counts": {
        "MB20_Gun1_LH": 23,
        "MB20_Gun3_LH": 7,
        "MB30_Gun1_LH": 62
    }
}

with open(r'e:\FLAME\FLAME APP\flame\weld_count_data.json', 'w') as f:
    json.dump(weld_data, f, indent=2)
```

## ✨ Features

- ✅ **Supports all your gun names** (MB20_Gun1_LH, I193.6, etc.)
- ✅ **Real-time updates** when desktop app changes the file
- ✅ **Automatic conversion** to Flutter-compatible format
- ✅ **No Flutter changes needed** - works with existing UI
- ✅ **Offline support** - cached data when network is down
- ✅ **Scalable** - supports unlimited guns

## 🧪 Quick Test

1. **Copy your existing file:**
   ```bash
   copy "e:\FLAME\FLAME Backup\F.L.A.M.E\Assets\weld_counts.json" "e:\FLAME\FLAME APP\flame\weld_count_data.json"
   ```

2. **Start server:**
   ```bash
   node enhanced_plc_server.js
   ```

3. **You should see:**
   ```
   ✅ Loaded weld count data for 27 guns
   ```

4. **Run Flutter app and navigate to Gun Inching**

5. **You'll see all your guns in the dropdown!**

## 📊 What You'll See in the App

The Gun Inching page will show:
- **Dropdown**: All your gun names (MB20_Gun1_LH, MB30_Gun2_RH, etc.)
- **Weld Count**: Large display of current count
- **Last Updated**: Timestamp from your JSON file
- **Real-time Updates**: Changes when desktop app updates the file

---

**Everything is ready! Your actual weld count schema is fully supported! 🎉**

