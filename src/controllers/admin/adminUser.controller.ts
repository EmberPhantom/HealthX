import { Request, Response } from 'express';
import User from '../../models/User';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';
import { updateUserRoleSchema, updateUserStatusSchema } from '../../schemas/admin.schema';

export const getAdminUsers = catchAsync(async (req: Request, res: Response) => {
  const { search, role, isActive } = req.query;
  const filter: any = {};

  if (search) {
    filter.$or = [
      { name: new RegExp(search as string, 'i') },
      { email: new RegExp(search as string, 'i') },
    ];
  }

  if (role) {
    filter.role = role as string;
  }

  if (isActive !== undefined) {
    filter.isActive = isActive === 'true';
  }

  const users = await User.find(filter).sort({ createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: users,
  });
});

export const updateUserRole = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  
  // Prevent changing one's own role to avoid self-lockout
  if (res.locals.userId && res.locals.userId === id) {
    throw new AppError('You cannot change your own admin role', 400);
  }

  const validatedData = updateUserRoleSchema.parse(req.body);

  const user = await User.findByIdAndUpdate(
    id,
    { role: validatedData.role },
    { new: true, runValidators: true }
  );

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: user,
  });
});

export const toggleUserActive = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;

  // Prevent deactivating oneself
  if (res.locals.userId && res.locals.userId === id) {
    throw new AppError('You cannot deactivate your own admin account', 400);
  }

  const user = await User.findById(id);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  user.isActive = !user.isActive;
  await user.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: user,
  });
});
