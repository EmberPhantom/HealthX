import { Request, Response } from 'express';
import User from '../../models/User';
import Doctor from '../../models/Doctor';
import Order from '../../models/Order';
import Appointment from '../../models/Appointment';
import { catchAsync } from '../../utils/catchAsync';

export const getAdminStats = catchAsync(async (req: Request, res: Response) => {
  const [
    totalUsers,
    activeDoctors,
    totalOrders,
    totalAppointments,
    recentAppointments,
    recentOrders,
  ] = await Promise.all([
    User.countDocuments(),
    Doctor.countDocuments({ isActive: true }),
    Order.countDocuments(),
    Appointment.countDocuments(),
    Appointment.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('userId', 'name email')
      .populate('doctorId', 'name specialty'),
    Order.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('userId', 'name email'),
  ]);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      stats: {
        totalUsers,
        activeDoctors,
        totalOrders,
        totalAppointments,
      },
      recentAppointments,
      recentOrders,
    },
  });
});
