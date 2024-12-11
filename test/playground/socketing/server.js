// server.js
// Minimal Node.js WebSocket server with channels
// To run: 
//   npm init -y
//   npm install ws
//   node server.js

const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });
const channels = new Map(); // Store channels and their subscribers

wss.on('connection', (ws) => {
  console.log('Client connected');
  ws.channels = new Set(); // Track channels this client subscribed to

  ws.on('message', (message) => {
    const data = JSON.parse(message);
    console.log('Received:', data);

    switch(data.type) {
      case 'subscribe':
        if (!channels.has(data.channel)) {
          channels.set(data.channel, new Set());
        }
        channels.get(data.channel).add(ws);
        ws.channels.add(data.channel);
        break;

      case 'unsubscribe':
        if (channels.has(data.channel)) {
          channels.get(data.channel).delete(ws);
          ws.channels.delete(data.channel);
        }
        break;

      case 'message':
        // Broadcast to all clients in the channel
        if (channels.has(data.channel)) {
          channels.get(data.channel).forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'message',
                channel: data.channel,
                content: data.content
              }));
            }
          });
        }
        break;
    }
  });

  ws.on('close', () => {
    // Cleanup: remove from all subscribed channels
    ws.channels.forEach(channel => {
      if (channels.has(channel)) {
        channels.get(channel).delete(ws);
      }
    });
    console.log('Client disconnected');
  });
});

console.log('WebSocket server is running on ws://localhost:8080');

