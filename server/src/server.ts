import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { store } from './services/store.service';
import { socketService } from './services/socket.service';

const startServer = async () => {
  try {
    // 1. Initialize DB / store
    await store.init();

    // 2. Create Express app & HTTP Server
    const app = createApp();
    const server = http.createServer(app);

    // 3. Initialize WebSockets
    socketService.init(server);

    // 4. Listen
    server.listen(config.port, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║             ✨ GIFTYY BACKEND API SERVER ✨                ║
║           "Skip the gifts. Fund the dream"                 ║
║                                                            ║
║  Port:         http://localhost:${config.port}                      ║
║  Health Check: http://localhost:${config.port}/health               ║
║  Environment:  ${config.nodeEnv.padEnd(44)}║
║  KYC Engine:   ${(config.kyc.provider.toUpperCase() + ' (ID Verification Active)').padEnd(44)}║
║  Razorpay:     ${(config.razorpay.mockMode ? 'Mock Mode Enabled' : 'Live Gateway Active').padEnd(44)}║
╚════════════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
