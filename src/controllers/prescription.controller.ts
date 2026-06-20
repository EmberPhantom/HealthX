import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import Appointment from '../models/Appointment';
import Prescription from '../models/Prescription';
import { catchAsync } from '../utils/catchAsync';
import { AppError } from '../utils/AppError';
import notificationDispatcher from '../services/notification.service';

/**
 * Get prescription details by appointmentId
 */
export const getPrescription = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { appointmentId } = req.params;
  
  // Verify appointment exists first
  const appointment = await Appointment.findById(appointmentId);
  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  // Authorization check: Patient can only access their own prescriptions
  if (req.user.role === 'user' && appointment.userId.toString() !== req.user.userId) {
    throw new AppError('You do not have permission to access this prescription', 403);
  }

  const prescription = await Prescription.findOne({ appointmentId });
  if (!prescription) {
    throw new AppError('Prescription not found for this appointment', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: prescription,
  });
});

/**
 * Create a new prescription (for testing or doctor interface)
 */
export const createPrescription = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { appointmentId, medications, doctorNotes } = req.body;
  
  if (!appointmentId) {
    throw new AppError('Appointment ID is required', 400);
  }

  const appointment = await Appointment.findById(appointmentId);
  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  // Only providers/doctors or admins can create prescriptions
  if (req.user.role === 'user') {
    throw new AppError('Only doctors are permitted to issue prescriptions', 403);
  }

  // Check if prescription already exists
  const existingPrescription = await Prescription.findOne({ appointmentId });
  if (existingPrescription) {
    throw new AppError('A prescription has already been issued for this appointment', 400);
  }

  const prescription = await Prescription.create({
    appointmentId,
    doctorId: appointment.doctorId,
    userId: appointment.userId,
    medications: medications || [],
    doctorNotes,
  });

  // Notify the patient that their prescription is ready
  notificationDispatcher.dispatch({
    userId: appointment.userId,
    title: 'Prescription Ready 📝',
    body: 'Your doctor has issued a prescription for your consultation. Tap to view.',
    type: 'success',
    category: 'appointments',
    data: {
      type: 'prescription_ready',
      appointment_id: appointmentId,
    },
  }).catch(() => {});

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: prescription,
  });
});
