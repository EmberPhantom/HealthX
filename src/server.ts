import app from './app';
import { connectDB } from './config/db';
import { initializeRedis, closeRedis } from './config/redis';
import { config } from './config/config';
import logger from './utils/logger';
import { startAIHealthWorkers } from './scripts/ai-health.worker';

const startServer = async (): Promise<void> => {
  try {
    // Connect to MongoDB
    logger.info('Connecting to MongoDB...');
    await connectDB();

    // Connect to Redis
    logger.info('Connecting to Redis...');
    await initializeRedis();
    logger.info('Redis connection initialized');

    // Start AI Health background workers (queues + weekly cron)
    await startAIHealthWorkers();

    // Start Express server
    // Listen on 0.0.0.0 to allow connections from physical devices on the same network
    const server = app.listen(config.port, '0.0.0.0', () => {
      logger.info(`
        ┌────────────────────────────────────┐
        │   HealthX Backend API Started      │
        ├────────────────────────────────────┤
        │ Port:        ${config.port}
        │ Environment: ${config.env}
        │ Node Version: ${process.version}
        │ Status:      🚀 Ready
        └────────────────────────────────────┘
      `);
    });

    // Start background order progression simulator (runs every 30 seconds)
    const progressionInterval = setInterval(async () => {
      try {
        const { default: orderProgressionService } = await import('./services/order-progression.service');
        await orderProgressionService.progressActiveOrders();
      } catch (error) {
        logger.error('Error in order progression background simulator:', error);
      }
    }, 30000);

    // Appointment 24-hour reminder — runs every hour
    const appointmentReminderInterval = setInterval(async () => {
      try {
        const Appointment = (await import('./models/Appointment')).default;
        const notificationDispatcher = (await import('./services/notification.service')).default;
        const now = new Date();
        const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const in25h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        // Find appointments happening in the next 24-25 hour window
        const upcoming = await Appointment.find({
          status: 'confirmed',
          appointmentDate: { $gte: in24h, $lt: in25h },
        });

        for (const appt of upcoming) {
          await notificationDispatcher.dispatch({
            userId: appt.userId,
            title: 'Appointment Reminder 📅',
            body: `You have a confirmed appointment tomorrow at ${appt.timeSlot}. Don't forget to prepare your symptoms list.`,
            type: 'info',
            category: 'appointments',
            data: {
              type: 'appointment_reminder',
              appointment_id: appt._id.toString(),
            },
          });
        }
        if (upcoming.length) {
          logger.info(`Sent appointment reminders for ${upcoming.length} upcoming appointment(s)`);
        }
      } catch (err) {
        logger.error('Error in appointment reminder job:', err);
      }
    }, 60 * 60 * 1000); // every hour

    // Subscription expiry warning — runs once a day
    const subscriptionExpiryInterval = setInterval(async () => {
      try {
        const UserSubscription = (await import('./models/UserSubscription')).default;
        const notificationDispatcher = (await import('./services/notification.service')).default;
        const now = new Date();
        const in3days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

        const expiring = await UserSubscription.find({
          status: 'active',
          endDate: { $gte: now, $lte: in3days },
        });

        for (const sub of expiring) {
          const daysLeft = Math.ceil((sub.endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
          await notificationDispatcher.dispatch({
            userId: sub.userId,
            title: 'Subscription Expiring Soon ⏳',
            body: `Your "${sub.planName}" plan expires in ${daysLeft} day${daysLeft === 1 ? '' : 's'}. Renew now to keep your benefits.`,
            type: 'warning',
            category: 'general',
          });
        }
        if (expiring.length) {
          logger.info(`Sent expiry warnings for ${expiring.length} subscription(s)`);
        }
      } catch (err) {
        logger.error('Error in subscription expiry job:', err);
      }
    }, 24 * 60 * 60 * 1000); // every 24 hours

    // Handle graceful shutdown
    const gracefulShutdown = async (signal: string): Promise<void> => {
      logger.info(`\nReceived ${signal}, starting graceful shutdown...`);

      clearInterval(progressionInterval);
      clearInterval(appointmentReminderInterval);
      clearInterval(subscriptionExpiryInterval);
      server.close(async () => {
        logger.info('Express server closed');

        try {
          await closeRedis();
          logger.info('Redis connection closed');
        } catch (error) {
          logger.error('Error closing Redis:', error);
        }

        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown - graceful shutdown timeout');
        process.exit(1);
      }, 10000);
    };

    // Handle signals
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Handle unhandled rejections
    process.on('unhandledRejection', (reason: Error | string) => {
      logger.error('Unhandled Rejection:', reason);
      process.exit(1);
    });

    // Handle uncaught exceptions
    process.on('uncaughtException', (error: Error) => {
      logger.error('Uncaught Exception:', error);
      process.exit(1);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();