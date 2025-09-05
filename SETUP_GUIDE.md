# FLAME App Setup Guide

## 🚀 Quick Setup

### 1. Server Configuration
1. **Update Server IP**: Edit `lib/config/api_config.dart`
   ```dart
   static const String serverIp = 'YOUR_SERVER_IP_HERE'; // Change this
   ```

2. **Start Mock Server** (for testing):
   ```bash
   node mock_plc_server.js
   ```

3. **Start Real Server** (for production):
   ```bash
   node enhanced_plc_server.js
   ```

### 2. Flutter App Setup
1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

## 📱 App Features

### ✅ Implemented Features
- **Real-time Gun Status Monitoring**
- **Live Data Updates via WebSocket**
- **Offline Mode with Cached Data**
- **Emergency Alerts System**
- **Interactive Pie Charts**
- **Excel Report Generation**
- **Connection Status Indicators**
- **Automatic Reconnection**

### 🔧 Technical Features
- **Thread-safe API Operations**
- **Non-blocking File I/O**
- **Automatic Fallback to HTTP Polling**
- **Smart Caching System**
- **Network Connectivity Detection**
- **Error Handling & Recovery**

## 🎯 Performance Optimizations

### ✅ Applied Optimizations
1. **Efficient State Management**
   - StreamBuilder for real-time updates
   - Proper disposal of subscriptions
   - Minimal widget rebuilds

2. **Network Optimization**
   - Connection pooling
   - Timeout handling
   - Automatic retry logic
   - Offline capability

3. **Memory Management**
   - Proper stream disposal
   - Cached data management
   - Efficient data structures

4. **UI Performance**
   - Lazy loading for large lists
   - Optimized table rendering
   - Smooth animations
   - Responsive design

## 📊 Data Flow

```
Mock/Real PLC Server → WebSocket/HTTP → Flutter App → UI Updates
                                    ↓
                              Local Cache (Offline Mode)
```

## 🔧 Configuration Options

### API Configuration (`lib/config/api_config.dart`)
- **Server IP & Port**: Change for your network
- **Timeouts**: Adjust for network conditions
- **Polling Intervals**: Balance between real-time and performance
- **Alert Thresholds**: Match your operational requirements

### Server Configuration
- **Port**: 7575 (configurable)
- **API Key**: `FlameApp123$byNevark` (change for security)
- **Data Generation**: 2-second intervals
- **Alert Simulation**: 10% chance for mock data

## 🚨 Troubleshooting

### Common Issues
1. **Connection Failed**
   - Check server IP in `api_config.dart`
   - Ensure server is running
   - Verify network connectivity

2. **No Data Showing**
   - Check API key configuration
   - Verify server endpoints are accessible
   - Look for error messages in debug console

3. **Performance Issues**
   - Increase polling intervals
   - Check network latency
   - Monitor memory usage

### Debug Tips
- Enable debug mode for detailed logs
- Check network requests in Flutter Inspector
- Monitor WebSocket connection status
- Verify cached data in device storage

## 📈 Monitoring

### Real-time Metrics
- **Connection Status**: Green (connected), Orange (cached), Red (offline)
- **Data Freshness**: Timestamp on each update
- **Alert Count**: Live count of active alerts
- **Gun Status**: Individual gun health indicators

### Performance Indicators
- **Response Time**: HTTP request latency
- **Update Frequency**: WebSocket message rate
- **Cache Hit Rate**: Offline data usage
- **Error Rate**: Failed requests/connections

## 🔒 Security Notes

1. **Change Default API Key** in production
2. **Use HTTPS** for production deployment
3. **Implement proper authentication** for multi-user scenarios
4. **Secure network access** with firewall rules
5. **Regular security updates** for dependencies

## 📱 Supported Platforms

- ✅ **Android** (Primary target)
- ✅ **iOS** (Compatible)
- ✅ **Windows** (Desktop)
- ✅ **Linux** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Web** (Browser)

## 🎨 UI/UX Features

- **Dark Theme**: Industrial blue color scheme
- **Responsive Design**: Adapts to different screen sizes
- **Intuitive Navigation**: Drawer-based menu system
- **Visual Indicators**: Color-coded status and alerts
- **Smooth Animations**: Enhanced user experience
- **Accessibility**: Screen reader compatible

## 🔄 Update Process

1. **Server Updates**: Restart server with new code
2. **App Updates**: Hot reload during development
3. **Configuration Changes**: Restart app after config updates
4. **Data Migration**: Automatic cache management

---

**Ready to monitor your industrial guns with real-time precision! 🎯**
