import { Request, Response } from 'express';
import Category from '../../models/Category';
import MenuItem from '../../models/MenuItem';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';
import { createCategorySchema, updateCategorySchema } from '../../schemas/admin.schema';

export const getAdminCategories = catchAsync(async (req: Request, res: Response) => {
  const categories = await Category.find().sort({ name: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: categories,
  });
});

export const createCategory = catchAsync(async (req: Request, res: Response) => {
  const validatedData = createCategorySchema.parse(req.body);

  // Check unique name
  const existingCategory = await Category.findOne({ name: { $regex: new RegExp(`^${validatedData.name}$`, 'i') } });
  if (existingCategory) {
    throw new AppError('Category with this name already exists', 400);
  }

  const category = await Category.create(validatedData);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: category,
  });
});

export const updateCategory = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const validatedData = updateCategorySchema.parse(req.body);

  const category = await Category.findById(id);
  if (!category) {
    throw new AppError('Category not found', 404);
  }

  if (validatedData.name && validatedData.name.toLowerCase() !== category.name.toLowerCase()) {
    const existingCategory = await Category.findOne({ name: { $regex: new RegExp(`^${validatedData.name}$`, 'i') } });
    if (existingCategory) {
      throw new AppError('Category with this name already exists', 400);
    }
  }

  Object.assign(category, validatedData);
  await category.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: category,
  });
});

export const deleteCategory = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const category = await Category.findById(id);

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  // Prevent delete if items still reference this category
  const itemUsingCategory = await MenuItem.findOne({ category: category.name });
  if (itemUsingCategory) {
    throw new AppError(`Cannot delete category "${category.name}" as it is currently assigned to one or more menu items (e.g. "${itemUsingCategory.name}")`, 400);
  }

  await category.deleteOne();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});
