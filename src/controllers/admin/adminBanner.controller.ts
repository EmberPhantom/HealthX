import { Request, Response } from 'express';
import Banner from '../../models/Banner';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';
import fileUploadService from '../../services/storage.service';
import { createBannerSchema, updateBannerSchema } from '../../schemas/admin.schema';

export const getAdminBanners = catchAsync(async (req: Request, res: Response) => {
  const banners = await Banner.find().sort({ createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: banners,
  });
});

export const createBanner = catchAsync(async (req: Request, res: Response) => {
  const validatedData = createBannerSchema.parse(req.body);

  const banner = await Banner.create(validatedData);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: banner,
  });
});

export const updateBanner = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const validatedData = updateBannerSchema.parse(req.body);

  const banner = await Banner.findByIdAndUpdate(id, validatedData, {
    new: true,
    runValidators: true,
  });

  if (!banner) {
    throw new AppError('Banner not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: banner,
  });
});

export const deleteBanner = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const banner = await Banner.findById(id);

  if (!banner) {
    throw new AppError('Banner not found', 404);
  }

  // Delete image if it is a local path
  if (banner.imagePath && banner.imagePath.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(banner.imagePath);
    } catch (e) {
      // Ignored
    }
  }

  await banner.deleteOne();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

export const uploadBannerImage = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const file = req.file;

  if (!file) {
    throw new AppError('Please upload an image file', 400);
  }

  const banner = await Banner.findById(id);
  if (!banner) {
    throw new AppError('Banner not found', 404);
  }

  // Delete previous image if exists locally
  if (banner.imagePath && banner.imagePath.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(banner.imagePath);
    } catch (e) {
      // Ignored
    }
  }

  const imagePath = await fileUploadService.saveImage(file, 'banners');

  banner.imagePath = imagePath;
  await banner.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: banner,
  });
});
