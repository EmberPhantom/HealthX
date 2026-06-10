import { Response } from 'express';
import Address from '../models/Address';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

export const getAddresses = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const addresses = await Address.find({ userId: req.user.userId }).sort({ isDefault: -1, createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: addresses,
  });
});

export const createAddress = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { label, street, area, city, pincode, isDefault, latitude, longitude } = req.body;

  if (isDefault) {
    await Address.updateMany({ userId: req.user.userId }, { isDefault: false });
  }

  const addressCount = await Address.countDocuments({ userId: req.user.userId });

  const address = await Address.create({
    userId: req.user.userId,
    label,
    street,
    area,
    city,
    pincode,
    isDefault: addressCount === 0 ? true : !!isDefault,
    latitude,
    longitude,
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: address,
  });
});

export const updateAddress = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { label, street, area, city, pincode, isDefault, latitude, longitude } = req.body;

  if (isDefault) {
    await Address.updateMany({ userId: req.user.userId }, { isDefault: false });
  }

  const address = await Address.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId },
    {
      label,
      street,
      area,
      city,
      pincode,
      isDefault: !!isDefault,
      latitude,
      longitude,
    },
    { new: true, runValidators: true }
  );

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: address,
  });
});

export const deleteAddress = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const address = await Address.findOne({ _id: req.params.id, userId: req.user.userId });
  if (!address) {
    throw new AppError('Address not found', 404);
  }
  await address.deleteOne();

  // If we deleted the default address, set another address as default if exists
  if (address.isDefault) {
    const another = await Address.findOne({ userId: req.user.userId });
    if (another) {
      another.isDefault = true;
      await another.save();
    }
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

export const setDefaultAddress = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  await Address.updateMany({ userId: req.user.userId }, { isDefault: false });

  const address = await Address.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId },
    { isDefault: true },
    { new: true }
  );

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: address,
  });
});
