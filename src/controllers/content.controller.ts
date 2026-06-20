import { Request, Response } from 'express';
import { contentService } from '../services/content.service';
import { catchAsync } from '../utils/catchAsync';

export const getCategories = catchAsync(async (req: Request, res: Response) => {
  const categories = await contentService.getCategories();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: categories,
  });
});

export const getBanners = catchAsync(async (req: Request, res: Response) => {
  const banners = await contentService.getBanners();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: banners,
  });
});

export const getMealPlans = catchAsync(async (req: Request, res: Response) => {
  const mealPlans = await contentService.getMealPlans();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: mealPlans,
  });
});

export const getMenuItems = catchAsync(async (req: Request, res: Response) => {
  const type = req.query.type as string;
  const menuItems = await contentService.getMenuItems(type);
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: menuItems,
  });
});

export const getSubscriptionPlans = catchAsync(async (req: Request, res: Response) => {
  const plans = await contentService.getSubscriptionPlans();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: plans,
  });
});

export const getRewardTasks = catchAsync(async (req: Request, res: Response) => {
  const tasks = await contentService.getRewardTasks();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: tasks,
  });
});

export const getSupportInfo = catchAsync(async (req: Request, res: Response) => {
  const support = await contentService.getSupportInfo();
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: support,
  });
});
