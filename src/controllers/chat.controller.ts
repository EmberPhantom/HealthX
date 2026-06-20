import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import Appointment from '../models/Appointment';
import ChatMessage from '../models/ChatMessage';
import { catchAsync } from '../utils/catchAsync';
import { AppError } from '../utils/AppError';
import notificationDispatcher from '../services/notification.service';

/**
 * Get all chat messages for a specific appointment/consultation
 */
export const getMessages = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { appointmentId } = req.params;
  const appointment = await Appointment.findById(appointmentId);

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  // Authorization check: Patients can only access their own appointments.
  // Providers (doctors) and Admins are permitted access.
  if (req.user.role === 'user' && appointment.userId.toString() !== req.user.userId) {
    throw new AppError('You do not have permission to access this chat', 403);
  }

  const messages = await ChatMessage.find({ appointmentId })
    .populate('senderId', 'name')
    .sort({ loggedAt: 1 });

  const formattedMessages = messages.map((msg) => {
    const sender = msg.senderId as any;
    return {
      _id: msg._id,
      appointmentId: msg.appointmentId,
      senderId: sender?._id || msg.senderId,
      senderName: sender?.name || 'User',
      text: msg.content,
      timestamp: msg.loggedAt,
    };
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: formattedMessages,
  });
});

/**
 * Send a new chat message for a specific appointment/consultation
 */
export const sendMessage = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { appointmentId } = req.params;
  const { text, content } = req.body;
  const messageText = text || content;

  if (!messageText || typeof messageText !== 'string' || messageText.trim() === '') {
    throw new AppError('Message text is required', 400);
  }

  const appointment = await Appointment.findById(appointmentId);

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  // Authorization check: Patients can only send messages in their own appointments.
  if (req.user.role === 'user' && appointment.userId.toString() !== req.user.userId) {
    throw new AppError('You do not have permission to send a message in this chat', 403);
  }

  const message = await ChatMessage.create({
    appointmentId,
    senderId: req.user.userId,
    content: messageText.trim(),
  });

  // Notify the other party (patient ↔ doctor) about the new message
  const recipientId = req.user.userId === appointment.userId.toString()
    ? (appointment as any).doctorId  // patient sent → notify doctor
    : appointment.userId;             // doctor sent → notify patient

  notificationDispatcher.dispatch({
    userId: recipientId,
    title: 'New Consultation Message 💬',
    body: `You have a new message regarding your consultation.`,
    type: 'info',
    category: 'chat',
    data: {
      type: 'chat_message',
      appointment_id: appointmentId,
    },
  }).catch(() => {}); // fire-and-forget — never block the response

  // Populate senderId for formatted return
  const populatedMessage = await ChatMessage.findById(message._id).populate('senderId', 'name');
  const sender = populatedMessage?.senderId as any;

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: {
      _id: message._id,
      appointmentId: message.appointmentId,
      senderId: sender?._id || message.senderId,
      senderName: sender?.name || 'User',
      text: message.content,
      timestamp: message.loggedAt,
    },
  });
});
