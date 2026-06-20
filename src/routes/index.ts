import express, { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import onboardingRoutes from './onboarding.routes';
import securityRoutes from './security.routes';
import contentRoutes from './content.routes';
import mealRoutes from './meal.routes';
import trackerRoutes from './tracker.routes';
import notificationRoutes from './notification.routes';
import addressRoutes from './address.routes';
import orderRoutes from './order.routes';
import doctorRoutes from './doctor.routes';
import appointmentRoutes from './appointment.routes';
import healthRecordRoutes from './healthRecord.routes';
import prakritiRoutes from './prakriti.routes';
import subscriptionRoutes from './subscription.routes';
import debugRoutes from './debug.routes';
import chatRoutes from './chat.routes';
import prescriptionRoutes from './prescription.routes';
import adminRoutes from './admin.routes';
import aiHealthRoutes from './ai-health.routes';
import { config } from '../config/config';

const router = Router();

/**
 * Mount all route modules
 */
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/onboarding', onboardingRoutes);
router.use('/security', securityRoutes);
router.use('/content', contentRoutes);
router.use('/meals', mealRoutes);
router.use('/trackers', trackerRoutes);
router.use('/notifications', notificationRoutes);
router.use('/addresses', addressRoutes);
router.use('/orders', orderRoutes);
router.use('/doctors', doctorRoutes);
router.use('/appointments', appointmentRoutes);
router.use('/health-records', healthRecordRoutes);
router.use('/prakriti', prakritiRoutes);
router.use('/subscriptions', subscriptionRoutes);
router.use('/chats', chatRoutes);
router.use('/prescriptions', prescriptionRoutes);
router.use('/admin', adminRoutes);
router.use('/ai-health', aiHealthRoutes);

if (config.env !== 'production') {
  router.use('/debug', debugRoutes);
}

export default router;
