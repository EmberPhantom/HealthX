import Order from '../models/Order';
import notificationDispatcher from './notification.service';
import logger from '../utils/logger';

// Status label + body copy per progression step
const STEP_COPY: Record<string, { title: string; body: (id: string) => string }> = {
  confirmed: {
    title: 'Order Confirmed! 👨‍🍳',
    body: (id) => `Your order #${id} has been confirmed by the restaurant.`,
  },
  preparing: {
    title: 'Preparing Your Meal 🍲',
    body: (id) => `The kitchen is preparing your order #${id}.`,
  },
  on_the_way: {
    title: 'Order Dispatched! 🛵',
    body: () => 'Our delivery partner Ramesh Kumar is en route with your order.',
  },
  delivered: {
    title: 'Order Delivered! 🎉',
    body: (id) => `Your order #${id} has been delivered. Enjoy your meal!`,
  },
};

/** Determine the next status based on elapsed time thresholds */
function nextStatus(current: string, elapsedMinutes: number): string | null {
  if (current === 'placed' && elapsedMinutes >= 1) return 'confirmed';
  if (current === 'confirmed' && elapsedMinutes >= 3) return 'preparing';
  if (current === 'preparing' && elapsedMinutes >= 10) return 'on_the_way';
  if (current === 'on_the_way' && elapsedMinutes >= 20) return 'delivered';
  return null;
}

class OrderProgressionService {
  /**
   * Background interval — progresses orders one step at a time.
   * Called every 30 seconds from server.ts.  This is the ONLY place that
   * creates order-progression notifications to prevent duplicates.
   */
  async progressActiveOrders() {
    try {
      const now = new Date();
      const activeOrders = await Order.find({
        status: { $in: ['placed', 'confirmed', 'preparing', 'on_the_way'] },
      });

      for (const order of activeOrders) {
        const elapsedMinutes = (now.getTime() - order.createdAt.getTime()) / 60000;
        const newStatus = nextStatus(order.status, elapsedMinutes);

        if (newStatus) {
          order.status = newStatus as typeof order.status;
          if (newStatus === 'delivered') order.isPaid = true;
          await order.save();
          logger.info(`Order #${order._id} → ${newStatus}`);

          const shortId = order._id.toString().slice(-6);
          const copy = STEP_COPY[newStatus];
          if (copy) {
            await notificationDispatcher.dispatch({
              userId: order.userId,
              title: copy.title,
              body: copy.body(shortId),
              type: 'info',
              category: 'orders',
              data: {
                type: 'order_update',
                order_id: order._id.toString(),
              },
            });
          }
        }
      }
    } catch (error) {
      logger.error('Error progressing active orders:', error);
    }
  }

  /**
   * On-demand progression for a single order — only updates the DB status,
   * NO notification created here to avoid duplicates with the interval job.
   */
  async progressSingleOrder(order: any): Promise<any> {
    if (!order || ['delivered', 'cancelled'].includes(order.status)) {
      return order;
    }

    const now = new Date();
    const elapsedMinutes = (now.getTime() - order.createdAt.getTime()) / 60000;

    // Cascade through all thresholds to find the final status
    let current = order.status;
    let changed = false;

    const steps = ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered'];
    for (const _ of steps) {
      const n = nextStatus(current, elapsedMinutes);
      if (!n) break;
      current = n;
      changed = true;
    }

    if (changed) {
      const oldStatus = order.status;
      order.status = current;
      if (current === 'delivered') order.isPaid = true;
      await order.save();
      logger.info(
        `Order #${order._id} dynamically progressed ${oldStatus} → ${current} on fetch (no notification — interval handles that)`
      );
    }

    return order;
  }
}

export default new OrderProgressionService();
