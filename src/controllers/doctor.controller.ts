import { Request, Response } from 'express';
import { doctorService } from '../services/doctor.service';
import { catchAsync } from '../utils/catchAsync';
import { AppError } from '../utils/AppError';

export const getDoctors = catchAsync(async (req: Request, res: Response) => {
  const { specialty, city } = req.query;
  const doctors = await doctorService.getDoctors({
    specialty: specialty as string,
    city: city as string,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctors,
  });
});

export const getDoctor = catchAsync(async (req: Request, res: Response) => {
  const doctor = await doctorService.getDoctorById(req.params.id);
  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctor,
  });
});

export const getDoctorSlots = catchAsync(async (req: Request, res: Response) => {
  const doctor = await doctorService.getDoctorById(req.params.id);
  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  const { date } = req.query;
  if (!date) {
    throw new AppError('Date query parameter is required', 400);
  }

  const parsedDate = new Date(date as string);
  if (isNaN(parsedDate.getTime())) {
    throw new AppError('Invalid date format', 400);
  }

  // Get weekday name
  const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayName = weekdays[parsedDate.getDay()];

  // Find slot configuration for that day
  const slotsConfig = doctor.availableSlots.find(
    (s) => s.day.toLowerCase() === dayName.toLowerCase()
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: slotsConfig ? slotsConfig.times : [],
  });
});

export const getSpecialties = catchAsync(async (req: Request, res: Response) => {
  const specialties = await doctorService.getSpecialties();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: specialties,
  });
});
