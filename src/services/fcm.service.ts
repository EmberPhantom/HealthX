import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getMessaging, Message } from 'firebase-admin/messaging';
import { config } from '../config/config';
import logger from '../utils/logger';

// ─── Lazy initialisation ──────────────────────────────────────────────────────

let _app: App | null = null;

function getApp(): App | null {
  if (_app) return _app;

  const { projectId, privateKey, clientEmail } = config.firebase;
  if (!projectId || !privateKey || !clientEmail) {
    logger.warn(
      '⚠️  FCM: FIREBASE_PROJECT_ID / FIREBASE_PRIVATE_KEY / FIREBASE_CLIENT_EMAIL ' +
        'are not set. Push notifications will be disabled.'
    );
    return null;
  }

  try {
    // Avoid double-initialisation if the module is hot-reloaded
    _app =
      getApps().find((a) => a.name === '[DEFAULT]') ??
      initializeApp({
        credential: cert({
          projectId,
          privateKey: privateKey.replace(/\\n/g, '\n'),
          clientEmail,
        }),
      });
    logger.info('✅ Firebase Admin SDK initialised');
  } catch (err) {
    logger.error('❌ Firebase Admin SDK initialisation failed:', err);
    _app = null;
  }

  return _app;
}

// ─── Types ────────────────────────────────────────────────────────────────────

export interface FcmPayload {
  title: string;
  body: string;
  /** notification category — maps to Android channel */
  category?: 'general' | 'orders' | 'appointments' | 'chat' | 'health' | 'promotions';
  imageUrl?: string;
  /** deep-link data forwarded to the Flutter tap handler */
  data?: Record<string, string>;
}

// Channel → Android notification channel id mapping
const CHANNEL_MAP: Record<string, string> = {
  general: 'healthx_channel',
  orders: 'healthx_orders',
  appointments: 'healthx_appointments',
  chat: 'healthx_chat',
  health: 'healthx_health_alerts',
  promotions: 'healthx_promotions',
};

// ─── Core send helpers ────────────────────────────────────────────────────────

/**
 * Send a push notification to a single FCM token.
 * Returns true on success, false if the token is invalid (caller should clear it).
 */
export async function sendToToken(
  token: string,
  payload: FcmPayload
): Promise<boolean> {
  const app = getApp();
  if (!app) return false;

  const channelId = CHANNEL_MAP[payload.category ?? 'general'] ?? CHANNEL_MAP.general;

  const message: Message = {
    token,
    notification: {
      title: payload.title,
      body: payload.body,
      imageUrl: payload.imageUrl,
    },
    android: {
      notification: {
        channelId,
        icon: 'ic_notification',
        color: '#10B981',
        sound: 'default',
        priority: 'high',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        imageUrl: payload.imageUrl,
      },
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          alert: { title: payload.title, body: payload.body },
          sound: 'default',
          badge: 1,
        },
      },
    },
    data: {
      category: payload.category ?? 'general',
      ...payload.data,
    },
  };

  try {
    const msgId = await getMessaging(app).send(message);
    logger.info(`📲 FCM sent [${payload.category}] → ${token.slice(-6)} (id=${msgId})`);
    return true;
  } catch (err: any) {
    const code: string = err?.errorInfo?.code ?? '';
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      logger.warn(`FCM token invalid, should be removed: ${token.slice(-6)}`);
      return false; // signal to caller to clear stored token
    }
    logger.error('FCM send error:', err?.message ?? err);
    return false;
  }
}

/**
 * Send to a topic (e.g. 'all_users', 'promotions').
 */
export async function sendToTopic(
  topic: string,
  payload: FcmPayload
): Promise<boolean> {
  const app = getApp();
  if (!app) return false;

  const channelId = CHANNEL_MAP[payload.category ?? 'general'] ?? CHANNEL_MAP.general;

  const message: Message = {
    topic,
    notification: {
      title: payload.title,
      body: payload.body,
      imageUrl: payload.imageUrl,
    },
    android: {
      notification: {
        channelId,
        icon: 'ic_notification',
        color: '#10B981',
        sound: 'default',
        priority: 'high',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      priority: 'high',
    },
    data: {
      category: payload.category ?? 'general',
      ...payload.data,
    },
  };

  try {
    const msgId = await getMessaging(app).send(message);
    logger.info(`📲 FCM topic "${topic}" sent (id=${msgId})`);
    return true;
  } catch (err: any) {
    logger.error('FCM topic send error:', err?.message ?? err);
    return false;
  }
}
