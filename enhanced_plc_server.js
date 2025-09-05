const { Controller, Tag } = require('ethernet-ip');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const http = require('http');
const WebSocket = require('ws');

const CONFIG_FILE = path.join(__dirname, 'settings.json');
const OUTPUT_FILE = path.join(__dirname, 'sensor_data.json');

// API Configuration
const API_PORT = 7575;
const API_KEY = 'FlameApp123$byNevark'; // Change this to a secure random key
const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

let CONFIG = {};
try {
  CONFIG = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf-8'));
} catch (err) {
  console.error("❌ Failed to read config.json:", err.message || err);
  process.exit(1);
}

const PLC_IP = CONFIG.IpAddress;
const POLL_INTERVAL = 2000;
const PLC = new Controller();
const TAGS = [];
const TOTAL_SENSORS = CONFIG.GunCount;

// Step 1: Add Sensor_Temp_Flow from index 1 to min(7, TOTAL_SENSORS)
const sensorLimit = Math.min(TOTAL_SENSORS, 7);
for (let i = 1; i < sensorLimit; i++) {
  TAGS.push({ name: `Sensor_Temp_Flow[${i}].Flow_Out`, label: `Weld Gun ${i} - Flow`, index: i });
  TAGS.push({ name: `Sensor_Temp_Flow[${i}].Temp_Out`, label: `Weld Gun ${i} - Temp`, index: i });
}

// Step 2: If GunCount > 7, use Wago_Module[1..] for the rest
for (let i = 1; i <= TOTAL_SENSORS - 7; i++) {
  const index = i + 5;
  TAGS.push({ name: `Wago_Module[${i}].Flow_Out`, label: `Weld Gun ${index} - Flow`, index: index });
  TAGS.push({ name: `Wago_Module[${i}].Temp_Out`, label: `Weld Gun ${index} - Temp`, index: index });
}

// Helper function to get IST timestamp
function getISTTimestamp() {
  const date = new Date();
  const utc = date.getTime() + (date.getTimezoneOffset() * 60000);
  const istOffset = 5.5 * 60 * 60000;
  const istDate = new Date(utc + istOffset);

  const YYYY = istDate.getFullYear();
  const MM = String(istDate.getMonth() + 1).padStart(2, '0');
  const DD = String(istDate.getDate()).padStart(2, '0');
  const hh = String(istDate.getHours()).padStart(2, '0');
  const mm = String(istDate.getMinutes()).padStart(2, '0');
  const ss = String(istDate.getSeconds()).padStart(2, '0');

  return `${YYYY}-${MM}-${DD} ${hh}:${mm}:${ss} +05:30`;
}

// Thread-safe data storage with mutex-like behavior
let latestSensorData = [];
let isWritingData = false;
let connectedClients = new Set();

// Thread-safe data access
function getSensorDataSafely() {
  // Return a deep copy to prevent race conditions
  return JSON.parse(JSON.stringify(latestSensorData));
}

// Thread-safe data update
async function updateSensorDataSafely(newData) {
  // Wait if currently writing
  while (isWritingData) {
    await new Promise(resolve => setTimeout(resolve, 10));
  }

  isWritingData = true;
  try {
    latestSensorData = [...newData];
    await saveDataToFileAsync(latestSensorData);
    broadcastToClients(latestSensorData);
  } finally {
    isWritingData = false;
  }
}

// Middleware for API authentication
function authenticateAPI(req, res, next) {
  const apiKey = req.headers['x-api-key'] || req.query.apiKey;
  
  if (!apiKey || apiKey !== API_KEY) {
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: 'Valid API key required' 
    });
  }
  
  next();
}

// CORS configuration for Flutter app
app.use(cors({
  origin: '*', // In production, specify your app's domain
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'x-api-key']
}));

app.use(express.json());

// API Routes
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'online', 
    timestamp: getISTTimestamp(),
    totalGuns: TOTAL_SENSORS,
    connectedClients: connectedClients.size
  });
});

// Get all gun data
app.get('/api/guns', authenticateAPI, (req, res) => {
  const safeData = getSensorDataSafely();
  res.json({
    success: true,
    timestamp: getISTTimestamp(),
    totalGuns: TOTAL_SENSORS,
    data: safeData
  });
});

// Get specific gun data
app.get('/api/guns/:gunIndex', authenticateAPI, (req, res) => {
  const gunIndex = parseInt(req.params.gunIndex);
  const safeData = getSensorDataSafely();
  const gunData = safeData.find(gun => gun.gunIndex === gunIndex);

  if (!gunData) {
    return res.status(404).json({
      success: false,
      error: 'Gun not found',
      gunIndex: gunIndex
    });
  }

  res.json({
    success: true,
    timestamp: getISTTimestamp(),
    data: gunData
  });
});

// Get alerts (guns with critical values)
app.get('/api/alerts', authenticateAPI, (req, res) => {
  const safeData = getSensorDataSafely();
  const alerts = safeData.filter(gun => {
    // Define your alert criteria here
    const highTemp = gun.temperature > 45.0;
    const lowFlow = gun.flowRate < 8.0;
    return highTemp || lowFlow;
  });

  res.json({
    success: true,
    timestamp: getISTTimestamp(),
    alertCount: alerts.length,
    alerts: alerts.map(gun => ({
      ...gun,
      alertType: gun.temperature > 45.0 ? 'HIGH_TEMPERATURE' : 'LOW_FLOW',
      severity: gun.temperature > 50.0 || gun.flowRate < 5.0 ? 'CRITICAL' : 'WARNING'
    }))
  });
});

// WebSocket connection handling
wss.on('connection', (ws, req) => {
  console.log('📱 New WebSocket client connected');
  connectedClients.add(ws);

  // Send current data immediately
  const safeData = getSensorDataSafely();
  ws.send(JSON.stringify({
    type: 'initial_data',
    timestamp: getISTTimestamp(),
    data: safeData
  }));
  
  ws.on('close', () => {
    console.log('📱 WebSocket client disconnected');
    connectedClients.delete(ws);
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    connectedClients.delete(ws);
  });
});

// Function to broadcast data to all connected WebSocket clients
function broadcastToClients(data) {
  const message = JSON.stringify({
    type: 'sensor_update',
    timestamp: getISTTimestamp(),
    data: data
  });
  
  connectedClients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

async function connectAndPollPLC() {
  try {
    await PLC.connect(PLC_IP, 0);
    console.log(`✅ Connected to PLC at ${PLC_IP}`);

    setInterval(async () => {
      const newSensorData = [];

      for (let i = 0; i < TAGS.length; i += 2) {
        const flowTag = new Tag(TAGS[i].name);
        const tempTag = new Tag(TAGS[i + 1].name);

        try {
          await PLC.readTag(flowTag);
          await PLC.readTag(tempTag);

          const flow = parseFloat(flowTag.value).toFixed(1);
          const temp = parseFloat(tempTag.value).toFixed(1);

          newSensorData.push({
            gunIndex: TAGS[i].index,
            timestamp: getISTTimestamp(),
            flowRate: parseFloat(flow),
            temperature: parseFloat(temp)
          });

        } catch (err) {
          console.error(`❌ Failed to read ${TAGS[i].label} or ${TAGS[i + 1].label}:`, err.message || err);
        }
      }

      // Thread-safe update
      await updateSensorDataSafely(newSensorData);

    }, POLL_INTERVAL);

  } catch (err) {
    console.error("❌ PLC connection or read error:", err);
    setTimeout(connectAndPollPLC, 10000);
  }
}

// Async file writing to prevent blocking
function saveDataToFileAsync(data) {
  return new Promise((resolve, reject) => {
    fs.writeFile(OUTPUT_FILE, JSON.stringify(data, null, 2), (err) => {
      if (err) {
        console.error("❌ Failed to write sensor data to file:", err.message || err);
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

// Start the API server
server.listen(API_PORT, () => {
  console.log(`🚀 FLAME API Server running on port ${API_PORT}`);
  console.log(`📡 WebSocket endpoint: ws://localhost:${API_PORT}`);
  console.log(`🔑 API Key: ${API_KEY}`);
  console.log(`📊 Monitoring ${TOTAL_SENSORS} guns`);
});

// Start PLC polling
connectAndPollPLC();
