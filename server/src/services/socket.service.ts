import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';

class SocketService {
  private io: Server | null = null;

  init(server: HttpServer) {
    this.io = new Server(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
    });

    this.io.on('connection', (socket: Socket) => {
      // Room subscription per wedding slug or ID
      socket.on('join_wedding', (weddingId: string) => {
        socket.join(`wedding:${weddingId}`);
      });

      socket.on('leave_wedding', (weddingId: string) => {
        socket.leave(`wedding:${weddingId}`);
      });
    });

    console.log('⚡ Socket.io real-time service initialized');
  }

  // Broadcast when a guest makes a contribution
  broadcastContribution(weddingId: string, payload: {
    contributionId: string;
    itemId?: string;
    guestName: string;
    amount: number;
    message?: string;
    isAnonymous: boolean;
    weddingTotalRaised: number;
    contributorCount: number;
    itemRaisedAmount?: number;
    itemPercentFunded?: number;
  }) {
    if (!this.io) return;
    this.io.to(`wedding:${weddingId}`).emit('new_contribution', payload);
  }

  // Broadcast when wishlist is updated
  broadcastWishlistUpdate(weddingId: string, items: any[]) {
    if (!this.io) return;
    this.io.to(`wedding:${weddingId}`).emit('wishlist_updated', items);
  }
}

export const socketService = new SocketService();
