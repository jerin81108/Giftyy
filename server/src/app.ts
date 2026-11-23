import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import routes from './routes';
import { errorHandler } from './middlewares/error.middleware';
import { apiRateLimiter } from './middlewares/rateLimiter';

export const createApp = (): Application => {
  const app = express();

  // Security & logging middlewares
  app.use(helmet({
    contentSecurityPolicy: false, // allow loading in webviews and frames
  }));
  app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-razorpay-signature', 'x-guest-id'],
  }));
  app.use(morgan('dev'));

  // Raw body buffer capture for Razorpay webhook HMAC verification
  app.use(express.json({
    verify: (req: any, _res, buf) => {
      req.rawBody = buf.toString();
    },
  }));
  app.use(express.urlencoded({ extended: true }));

  // Apply rate limiter to API routes
  app.use('/api', apiRateLimiter);

  // Health check endpoint
  app.get('/health', (_req: Request, res: Response) => {
    res.json({
      status: 'healthy',
      app: 'Dream Wishlist API',
      timestamp: new Date().toISOString(),
    });
  });

  // Mount API router
  app.use('/api', routes);

  // Error handling middleware
  app.use(errorHandler);

  return app;
};
