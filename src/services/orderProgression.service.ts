import Order from '../models/Order';
import Notification from '../models/Notification';
import logger from '../utils/logger';

class OrderProgressionService {
  /**
   * Periodically checks and progresses orders
   */
  async progressActiveOrders() {
    try {
      const now = new Date();
      // Find orders that are not delivered or cancelled
      const activeOrders = await Order.find({
        status: { $in: ['placed', 'confirmed', 'preparing', 'on_the_way'] }
      });

      for (const order of activeOrders) {
        const elapsedMs = now.getTime() - order.createdAt.getTime();
        const elapsedMinutes = elapsedMs / (60 * 1000);

        let newStatus: typeof order.status | null = null;
        let notificationTitle = '';
        let notificationMsg = '';

        if (order.status === 'placed' && elapsedMinutes >= 1) {
          newStatus = 'confirmed';
          notificationTitle = 'Order Confirmed! 👨‍🍳';
          notificationMsg = `Your order #${order._id.toString().slice(-6)} has been confirmed by the restaurant.`;
        } else if (order.status === 'confirmed' && elapsedMinutes >= 3) {
          newStatus = 'preparing';
          notificationTitle = 'Preparing Meal 🍲';
          notificationMsg = `The kitchen is preparing your order #${order._id.toString().slice(-6)}.`;
        } else if (order.status === 'preparing' && elapsedMinutes >= 10) {
          newStatus = 'on_the_way';
          notificationTitle = 'Order Dispatched! 🛵';
          notificationMsg = `Our delivery partner Ramesh Kumar is en route with your order.`;
        } else if (order.status === 'on_the_way' && elapsedMinutes >= 20) {
          newStatus = 'delivered';
          notificationTitle = 'Order Delivered! 🎉';
          notificationMsg = `Your order #${order._id.toString().slice(-6)} has been delivered. Enjoy your meal!`;
        }

        if (newStatus) {
          order.status = newStatus;
          if (newStatus === 'delivered') {
            order.isPaid = true; // Mark as paid upon delivery
          }
          await order.save();
          logger.info(`Order #${order._id} status progressed to: ${newStatus}`);

          // Create notification
          await Notification.create({
            userId: order.userId,
            title: notificationTitle,
            message: notificationMsg,
            type: 'order',
            isRead: false,
          });
        }
      }
    } catch (error) {
      logger.error('Error progressing active orders:', error);
    }
  }

  /**
   * Run progression updates on an order whenever it's requested.
   * This guarantees status updates are immediately visible to users checking details,
   * even if the background interval has not fired yet.
   */
  async progressSingleOrder(order: any): Promise<any> {
    if (!order || ['delivered', 'cancelled'].includes(order.status)) {
      return order;
    }

    const now = new Date();
    const elapsedMs = now.getTime() - order.createdAt.getTime();
    const elapsedMinutes = elapsedMs / (60 * 1000);

    let statusUpdated = false;
    let currentStatus = order.status;

    // Sequential cascade progression checks
    if (currentStatus === 'placed' && elapsedMinutes >= 1) {
      currentStatus = 'confirmed';
      statusUpdated = true;
    }
    if (currentStatus === 'confirmed' && elapsedMinutes >= 3) {
      currentStatus = 'preparing';
      statusUpdated = true;
    }
    if (currentStatus === 'preparing' && elapsedMinutes >= 10) {
      currentStatus = 'on_the_way';
      statusUpdated = true;
    }
    if (currentStatus === 'on_the_way' && elapsedMinutes >= 20) {
      currentStatus = 'delivered';
      statusUpdated = true;
    }

    if (statusUpdated) {
      const oldStatus = order.status;
      order.status = currentStatus;
      if (currentStatus === 'delivered') {
        order.isPaid = true;
      }
      await order.save();
      logger.info(`Order #${order._id} dynamically progressed from ${oldStatus} to ${currentStatus} during fetch.`);

      // Create notification for each dynamic step passed
      const orderShortId = order._id.toString().slice(-6);
      const notifications = [];
      if (oldStatus === 'placed' && elapsedMinutes >= 1) {
        notifications.push({ title: 'Order Confirmed! 👨‍🍳', msg: `Your order #${orderShortId} has been confirmed.` });
      }
      if (oldStatus === 'placed' || oldStatus === 'confirmed') {
        if (elapsedMinutes >= 3) {
          notifications.push({ title: 'Preparing Meal 🍲', msg: `The kitchen is preparing your order #${orderShortId}.` });
        }
      }
      if (oldStatus === 'placed' || oldStatus === 'confirmed' || oldStatus === 'preparing') {
        if (elapsedMinutes >= 10) {
          notifications.push({ title: 'Order Dispatched! 🛵', msg: `Our delivery partner Ramesh Kumar is en route with your order.` });
        }
      }
      if (elapsedMinutes >= 20) {
        notifications.push({ title: 'Order Delivered! 🎉', msg: `Your order #${orderShortId} has been delivered. Enjoy your meal!` });
      }

      for (const n of notifications) {
        await Notification.create({
          userId: order.userId,
          title: n.title,
          message: n.msg,
          type: 'order',
          isRead: false,
        });
      }
    }

    return order;
  }
}

export default new OrderProgressionService();
