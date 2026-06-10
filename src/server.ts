import app from './app';
import { connectDB } from './config/db';
import { initializeRedis, closeRedis } from './config/redis';
import { config } from './config/config';
import logger from './utils/logger';

const startServer = async (): Promise<void> => {
  try {
    // Connect to MongoDB
    logger.info('Connecting to MongoDB...');
    await connectDB();

    // Connect to Redis
    logger.info('Connecting to Redis...');
    await initializeRedis();
    logger.info('Redis connection initialized');

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
      const { default: orderProgressionService } = await import('./services/orderProgression.service');
      await orderProgressionService.progressActiveOrders();
    }, 30000);

    // Handle graceful shutdown
    const gracefulShutdown = async (signal: string): Promise<void> => {
      logger.info(`\nReceived ${signal}, starting graceful shutdown...`);

      clearInterval(progressionInterval);
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