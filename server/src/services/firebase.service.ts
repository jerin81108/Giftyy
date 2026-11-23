import { initializeApp, cert, App } from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';
import path from 'path';
import fs from 'fs';
import { config } from '../config';

class FirebaseService {
  private app: App | null = null;
  public isInitialized = false;

  constructor() {
    this.init();
  }

  private init(): void {
    try {
      // Find service account file path
      const candidatePaths = [
        config.firebase?.serviceAccountPath,
        path.join(__dirname, '../config/firebase-service-account.json'),
        path.join(process.cwd(), 'serviceAccountKey.json'),
        path.join(process.cwd(), 'src/config/firebase-service-account.json'),
        path.join(process.cwd(), 'server/serviceAccountKey.json'),
        path.join(process.cwd(), 'server/src/config/firebase-service-account.json'),
      ].filter(Boolean) as string[];

      let serviceAccountPath: string | null = null;
      for (const p of candidatePaths) {
        if (fs.existsSync(p)) {
          serviceAccountPath = p;
          break;
        }
      }

      if (serviceAccountPath) {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        this.app = initializeApp({
          credential: cert(serviceAccount),
          projectId: serviceAccount.project_id || config.firebase.projectId,
        });
        this.isInitialized = true;
        console.log(`🔥 Firebase Admin SDK initialized successfully with project [${serviceAccount.project_id}]`);
      } else {
        console.warn('⚠️ No Firebase service account file found. Push notifications will run in mock mode.');
      }
    } catch (err) {
      console.warn('⚠️ Firebase initialization warning:', (err as Error).message);
    }
  }

  // Verify Firebase Phone Auth or user ID token sent from Flutter client
  async verifyIdToken(idToken: string): Promise<DecodedIdToken | null> {
    if (!this.isInitialized || !this.app) {
      return null;
    }
    try {
      return await getAuth(this.app).verifyIdToken(idToken);
    } catch (error) {
      console.error('Firebase verifyIdToken error:', (error as Error).message);
      return null;
    }
  }

  // Send Push Notification to single device token (FCM)
  async sendPushNotification(
    fcmToken: string,
    notification: { title: string; body: string },
    data?: Record<string, string>
  ): Promise<boolean> {
    if (!this.isInitialized || !this.app || !fcmToken) {
      console.log(`[FCM Mock] Push to ${fcmToken?.substring(0, 10)}...: "${notification.title}" - "${notification.body}"`);
      return true;
    }

    try {
      await getMessaging(this.app).send({
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data || {},
      });
      return true;
    } catch (error) {
      console.error('Firebase sendPushNotification error:', (error as Error).message);
      return false;
    }
  }

  // Send Multicast Notification to multiple devices
  async sendMulticastNotification(
    fcmTokens: string[],
    notification: { title: string; body: string },
    data?: Record<string, string>
  ): Promise<{ successCount: number; failureCount: number }> {
    const validTokens = fcmTokens.filter(t => t && t.trim().length > 0);
    if (!this.isInitialized || !this.app || validTokens.length === 0) {
      console.log(`[FCM Mock] Multicast (${validTokens.length} devices): "${notification.title}"`);
      return { successCount: validTokens.length, failureCount: 0 };
    }

    try {
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens: validTokens,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data || {},
      });
      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error('Firebase sendMulticastNotification error:', (error as Error).message);
      return { successCount: 0, failureCount: validTokens.length };
    }
  }

  // Send Notification to room topic (e.g. topic: "room_priya-ear-piercing-4821")
  async sendTopicNotification(
    topic: string,
    notification: { title: string; body: string },
    data?: Record<string, string>
  ): Promise<boolean> {
    if (!this.isInitialized || !this.app) {
      console.log(`[FCM Mock] Topic [${topic}]: "${notification.title}" - "${notification.body}"`);
      return true;
    }

    try {
      const cleanTopic = topic.replace(/[^a-zA-Z0-9-_.~%]+/g, '_');
      await getMessaging(this.app).send({
        topic: cleanTopic,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data || {},
      });
      return true;
    } catch (error) {
      console.error('Firebase sendTopicNotification error:', (error as Error).message);
      return false;
    }
  }
}

export const firebaseService = new FirebaseService();
