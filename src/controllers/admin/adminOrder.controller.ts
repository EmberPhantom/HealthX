import { Request, Response } from 'express';
import Order from '../../models/Order';
import { catchAsync } from '../../utils/catchAsync';
import { AppError } from '../../utils/AppError';

export const getAdminOrders = catchAsync(async (req: Request, res: Response) => {
  const { status } = req.query;
  const filter: any = {};

  if (status) {
    filter.status = status as string;
  }

  const orders = await Order.find(filter)
    .populate('userId', 'name email phone')
    .sort({ createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: orders,
  });
});

export const updateOrderStatus = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered', 'cancelled'];
  if (!status || !validStatuses.includes(status)) {
    throw new AppError('Invalid order status', 400);
  }

  const order = await Order.findByIdAndUpdate(
    id,
    { status },
    { new: true, runValidators: true }
  ).populate('userId', 'name email phone');

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: order,
  });
});
