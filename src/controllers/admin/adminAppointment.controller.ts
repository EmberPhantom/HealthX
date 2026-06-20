import { Request, Response } from 'express';
import Appointment from '../../models/Appointment';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';

export const getAdminAppointments = catchAsync(async (req: Request, res: Response) => {
  const { status } = req.query;
  const filter: any = {};

  if (status) {
    filter.status = status as string;
  }

  const appointments = await Appointment.find(filter)
    .populate('userId', 'name email phone')
    .populate('doctorId', 'name specialty qualification consultationFee clinicName')
    .sort({ appointmentDate: -1, timeSlot: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: appointments,
  });
});

export const updateAppointmentStatus = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
  if (!status || !validStatuses.includes(status)) {
    throw new AppError('Invalid appointment status', 400);
  }

  const appointment = await Appointment.findByIdAndUpdate(
    id,
    { status },
    { new: true, runValidators: true }
  )
    .populate('userId', 'name email phone')
    .populate('doctorId', 'name specialty qualification');

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: appointment,
  });
});
