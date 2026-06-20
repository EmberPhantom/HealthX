import { Request, Response } from 'express';
import Doctor from '../../models/Doctor';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';
import fileUploadService from '../../services/storage.service';
import { createDoctorSchema, updateDoctorSchema } from '../../schemas/admin.schema';

export const getAdminDoctors = catchAsync(async (req: Request, res: Response) => {
  const { specialty, city, search } = req.query;
  const filter: any = {};

  if (specialty) {
    filter.specialty = specialty as string;
  }
  if (city) {
    filter.city = new RegExp(city as string, 'i');
  }
  if (search) {
    filter.name = new RegExp(search as string, 'i');
  }

  const doctors = await Doctor.find(filter).sort({ name: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctors,
  });
});

export const createDoctor = catchAsync(async (req: Request, res: Response) => {
  const validatedData = createDoctorSchema.parse(req.body);

  const doctor = await Doctor.create(validatedData);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: doctor,
  });
});

export const updateDoctor = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const validatedData = updateDoctorSchema.parse(req.body);

  const doctor = await Doctor.findByIdAndUpdate(id, validatedData, {
    new: true,
    runValidators: true,
  });

  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctor,
  });
});

export const toggleDoctorActive = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const doctor = await Doctor.findById(id);

  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  doctor.isActive = !doctor.isActive;
  await doctor.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctor,
  });
});

export const deleteDoctor = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const doctor = await Doctor.findById(id);

  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  // Delete avatar if it is a local path
  if (doctor.avatarUrl && doctor.avatarUrl.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(doctor.avatarUrl);
    } catch (e) {
      // Ignored if file does not exist
    }
  }

  await doctor.deleteOne();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

export const uploadDoctorAvatar = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const file = req.file;

  if (!file) {
    throw new AppError('Please upload an avatar image file', 400);
  }

  const doctor = await Doctor.findById(id);
  if (!doctor) {
    throw new AppError('Doctor not found', 404);
  }

  // Delete previous avatar file if exists locally
  if (doctor.avatarUrl && doctor.avatarUrl.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(doctor.avatarUrl);
    } catch (e) {
      // Ignored
    }
  }

  const avatarUrl = await fileUploadService.saveAvatar(file, id);

  doctor.avatarUrl = avatarUrl;
  await doctor.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: doctor,
  });
});
