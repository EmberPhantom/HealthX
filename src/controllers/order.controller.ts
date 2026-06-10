import { Response } from 'express';
import Order from '../models/Order';
import User from '../models/User';
import Notification from '../models/Notification';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

export const placeOrder = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { items, addressId, paymentMethod } = req.body;

  if (!items || !items.length) {
    throw new AppError('No items in the order', 400);
  }

  // Calculate totals
  const subtotal = items.reduce((sum: number, i: any) => sum + (i.price * i.quantity), 0);
  const deliveryFee = 40;
  const tax = Math.round(subtotal * 0.05 * 100) / 100;
  const total = subtotal + deliveryFee + tax;

  // Since payments/razorpay/stripe are explicitly excluded, we bypass gateways
  // COD is marked unpaid, online methods are mocked as paid
  const isPaid = paymentMethod !== 'COD';

  // Mock estimated delivery: 35 minutes from now
  const estimatedDelivery = new Date(Date.now() + 35 * 60 * 1000);

  // Mock delivery partner
  const deliveryPartner = {
    name: 'Ramesh Kumar',
    phone: '+919876543210',
    vehicleNo: 'KA-01-EF-1234',
  };

  const order = await Order.create({
    userId: req.user.userId,
    addressId,
    items,
    subtotal,
    deliveryFee,
    tax,
    total,
    status: 'placed',
    paymentMethod,
    isPaid,
    deliveryPartner,
    estimatedDelivery,
  });

  // Increment user's order stats
  await User.findByIdAndUpdate(req.user.userId, { $inc: { totalOrders: 1 } });

  // Create notifications
  await Notification.create({
    userId: req.user.userId,
    title: 'Order Placed! 🎉',
    message: `Your order #${order._id.toString().slice(-6)} has been placed.`,
    type: 'order',
    isRead: false,
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: order,
  });
});

export const getOrders = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  let orders = await Order.find({ userId: req.user.userId }).sort({ createdAt: -1 });

  // Progress orders dynamically on fetch to ensure live updates
  const { default: orderProgressionService } = await import('../services/orderProgression.service');
  orders = await Promise.all(orders.map(o => orderProgressionService.progressSingleOrder(o)));

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: orders,
  });
});

export const getOrder = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  let order = await Order.findOne({ _id: req.params.id, userId: req.user.userId }).populate('addressId');

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  // Progress single order dynamically on fetch
  const { default: orderProgressionService } = await import('../services/orderProgression.service');
  order = await orderProgressionService.progressSingleOrder(order);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: order,
  });
});

export const cancelOrder = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { cancelReason } = req.body;

  const order = await Order.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId, status: { $in: ['placed', 'confirmed'] } },
    {
      status: 'cancelled',
      cancelledAt: new Date(),
      cancelReason: cancelReason || 'Cancelled by user',
    },
    { new: true }
  );

  if (!order) {
    throw new AppError('Order cannot be cancelled or was not found', 400);
  }

  // Create notification
  await Notification.create({
    userId: req.user.userId,
    title: 'Order Cancelled 🚫',
    message: `Your order #${order._id.toString().slice(-6)} has been cancelled.`,
    type: 'order',
    isRead: false,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: order,
  });
});

export const getOrderStatus = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const order = await Order.findOne({ _id: req.params.id, userId: req.user.userId });
  if (!order) {
    throw new AppError('Order not found', 404);
  }

  const { default: orderProgressionService } = await import('../services/orderProgression.service');
  const progressedOrder = await orderProgressionService.progressSingleOrder(order);
  if (!progressedOrder) {
    throw new AppError('Order not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      status: progressedOrder.status,
      estimatedDelivery: progressedOrder.estimatedDelivery,
      deliveryPartner: progressedOrder.deliveryPartner,
    },
  });
});
