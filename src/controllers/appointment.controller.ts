import { Response } from 'express';
import Appointment from '../models/Appointment';
import Doctor from '../models/Doctor';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';
import notificationDispatcher from '../services/notification.service';

export const bookAppointment = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { doctorId, appointmentDate, timeSlot, type, symptoms, notes } = req.body;

  const doctor = await Doctor.findById(doctorId);
  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  const dateVal = new Date(appointmentDate);
  if (isNaN(dateVal.getTime())) {
    throw new AppError('Invalid appointment date', 400);
  }

  // Consultation fee is retrieved directly from Doctor schema
  const appointment = await Appointment.create({
    userId: req.user.userId,
    doctorId,
    appointmentDate: dateVal,
    timeSlot,
    type: type || 'in-person',
    status: 'confirmed', // confirm immediately for MVP
    symptoms,
    notes,
    consultationFee: doctor.consultationFee,
    isPaid: false,
  });

  // Populate doctor details
  await appointment.populate('doctorId');

  // Create notification + push
  await notificationDispatcher.dispatch({
    userId: req.user.userId,
    title: 'Appointment Booked! 🩺',
    body: `Your appointment with ${doctor.name} is confirmed for ${dateVal.toDateString()} at ${timeSlot}.`,
    type: 'success',
    category: 'appointments',
    data: {
      type: 'appointment_update',
      appointment_id: appointment._id.toString(),
    },
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: appointment,
  });
});

export const getAppointments = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const appointments = await Appointment.find({ userId: req.user.userId })
    .populate('doctorId')
    .sort({ appointmentDate: -1, createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: appointments,
  });
});

export const getAppointment = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const appointment = await Appointment.findOne({
    _id: req.params.id,
    userId: req.user.userId,
  }).populate('doctorId');

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: appointment,
  });
});

export const cancelAppointment = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const appointment = await Appointment.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId },
    { status: 'cancelled' },
    { new: true }
  ).populate('doctorId');

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  // Create notification + push
  await notificationDispatcher.dispatch({
    userId: req.user.userId,
    title: 'Appointment Cancelled ⚠️',
    body: `Your appointment with ${(appointment.doctorId as any).name} has been cancelled.`,
    type: 'warning',
    category: 'appointments',
    data: {
      type: 'appointment_update',
      appointment_id: req.params.id,
    },
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: appointment,
  });
});
