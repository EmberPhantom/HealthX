import mongoose from 'mongoose';
import Notification from '../models/Notification';
import User from '../models/User';
import { sendToToken, FcmPayload } from './fcm.service';
import logger from '../utils/logger';

// ─── Types ────────────────────────────────────────────────────────────────────

export type NotificationType = 'info' | 'success' | 'warning' | 'error';
export type NotificationCategory =
  | 'general'
  | 'orders'
  | 'appointments'
  | 'chat'
  | 'health'
  | 'promotions';

export interface DispatchPayload {
  userId: mongoose.Types.ObjectId | string;
  title: string;
  body: string;
  type?: NotificationType;
  category?: NotificationCategory;
  imageUrl?: string;
  /** Extra data forwarded to the Flutter deep-link handler */
  data?: Record<string, string>;
}

// ─── Preference key mapping ───────────────────────────────────────────────────
// Maps notification category → SharedPreferences key used on the Flutter side.
// The backend mirrors this so it can honour user opt-outs stored server-side
// (currently preferences are local only, but we guard by category).

const CATEGORY_PREF_KEY: Record<NotificationCategory, string> = {
  general: 'health_alerts',
  orders: 'order_updates',
  appointments: 'health_alerts',
  chat: 'health_alerts',
  health: 'health_alerts',
  promotions: 'promotions_offers',
};

// ─── Dispatcher ───────────────────────────────────────────────────────────────

class NotificationDispatcher {
  /**
   * Save a notification to the DB and (if the user has an FCM token) push it
   * to the device tray.  This is the single canonical entry-point — all
   * controllers and services should call this instead of bare Notification.create().
   */
  async dispatch(payload: DispatchPayload): Promise<void> {
    const {
      userId,
      title,
      body,
      type = 'info',
      category = 'general',
      imageUrl,
      data = {},
    } = payload;

    // 1. Persist to DB (always)
    try {
      await Notification.create({
        userId,
        title,
        body,
        type,
        category,
        isRead: false,
      });
    } catch (err) {
      logger.error('NotificationDispatcher: DB write failed:', err);
      // Don't block the push attempt
    }

    // 2. Attempt FCM push
    try {
      const user = await User.findById(userId).select('fcmToken').lean();
      const token = (user as any)?.fcmToken;

      if (!token) {
        // No token registered — DB-only notification is fine
        return;
      }

      const fcmPayload: FcmPayload = {
        title,
        body,
        category,
        imageUrl,
        data: {
          category,
          ...data,
        },
      };

      const delivered = await sendToToken(token, fcmPayload);

      // If token is stale, clear it so we don't keep trying
      if (!delivered) {
        await User.findByIdAndUpdate(userId, { $unset: { fcmToken: '' } });
        logger.warn(`Cleared stale FCM token for user ${userId}`);
      }
    } catch (err) {
      // Push failure must never break the business operation
      logger.error('NotificationDispatcher: FCM push failed:', err);
    }
  }

  /**
   * Convenience — dispatch multiple notifications at once (e.g. bulk admin send).
   */
  async dispatchMany(payloads: DispatchPayload[]): Promise<void> {
    await Promise.allSettled(payloads.map((p) => this.dispatch(p)));
  }

  /**
   * Get unread count for a user (used by the badge API).
   */
  async getUnreadCount(userId: string): Promise<number> {
    return Notification.countDocuments({ userId, isRead: false });
  }

  /**
   * Mark all notifications as read for a user.
   */
  async markAllRead(userId: string): Promise<void> {
    await Notification.updateMany({ userId, isRead: false }, { isRead: true });
  }
}

export default new NotificationDispatcher();
