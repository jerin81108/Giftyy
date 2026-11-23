import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { store } from '../services/store.service';
import { IUser } from '../models/types';

export interface AuthenticatedRequest extends Request {
  user?: IUser;
}

export const authenticateJwt = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ success: false, message: 'Authentication required. No token provided.' });
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwtSecret) as { id: string; role: string };

    const user = await store.findUserById(decoded.id);
    if (!user) {
      res.status(401).json({ success: false, message: 'User not found or session expired.' });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ success: false, message: 'Invalid or expired authorization token.' });
  }
};

export const optionalAuthenticateJwt = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, config.jwtSecret) as { id: string; role: string };
      const user = await store.findUserById(decoded.id);
      if (user) {
        req.user = user;
      }
    }
  } catch (error) {
    // Ignore invalid token in optional auth
  }
  next();
};

export const requireRole = (role: 'couple' | 'admin') => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user || (req.user.role !== role && req.user.role !== 'admin')) {
      res.status(403).json({ success: false, message: 'Access denied. Insufficient permissions.' });
      return;
    }
    next();
  };
};
