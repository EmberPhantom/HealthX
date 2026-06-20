import { Request, Response } from 'express';
import MenuItem from '../../models/MenuItem';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';
import fileUploadService from '../../services/storage.service';
import { createMenuItemSchema, updateMenuItemSchema } from '../../schemas/admin.schema';

export const getAdminMenuItems = catchAsync(async (req: Request, res: Response) => {
  const { category, type, search } = req.query;
  const filter: any = {};

  if (category) {
    filter.category = category as string;
  }
  if (type) {
    filter.type = type as string;
  }
  if (search) {
    filter.name = new RegExp(search as string, 'i');
  }

  const items = await MenuItem.find(filter).sort({ category: 1, name: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: items,
  });
});

export const createMenuItem = catchAsync(async (req: Request, res: Response) => {
  const validatedData = createMenuItemSchema.parse(req.body);

  const menuItem = await MenuItem.create(validatedData);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: menuItem,
  });
});

export const updateMenuItem = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const validatedData = updateMenuItemSchema.parse(req.body);

  const menuItem = await MenuItem.findByIdAndUpdate(id, validatedData, {
    new: true,
    runValidators: true,
  });

  if (!menuItem) {
    throw new AppError('Menu item not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: menuItem,
  });
});

export const deleteMenuItem = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const menuItem = await MenuItem.findById(id);

  if (!menuItem) {
    throw new AppError('Menu item not found', 404);
  }

  // Delete image if it is a local path
  if (menuItem.imageUrl && menuItem.imageUrl.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(menuItem.imageUrl);
    } catch (e) {
      // Ignored
    }
  }

  await menuItem.deleteOne();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

export const uploadMenuItemImage = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const file = req.file;

  if (!file) {
    throw new AppError('Please upload an image file', 400);
  }

  const menuItem = await MenuItem.findById(id);
  if (!menuItem) {
    throw new AppError('Menu item not found', 404);
  }

  // Delete previous image if exists locally
  if (menuItem.imageUrl && menuItem.imageUrl.startsWith('/uploads')) {
    try {
      await fileUploadService.deleteFile(menuItem.imageUrl);
    } catch (e) {
      // Ignored
    }
  }

  const imageUrl = await fileUploadService.saveImage(file, 'menu-items');

  menuItem.imageUrl = imageUrl;
  await menuItem.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: menuItem,
  });
});
