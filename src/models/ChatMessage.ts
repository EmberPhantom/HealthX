import mongoose, { Schema, Document } from 'mongoose';

export interface IChatMessage extends Document {
  appointmentId: mongoose.Types.ObjectId;
  senderId: mongoose.Types.ObjectId;
  content: string;
  loggedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const chatMessageSchema = new Schema<IChatMessage>(
  {
    appointmentId: { type: Schema.Types.ObjectId, ref: 'Appointment', required: true },
    senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    content: { type: String, required: true },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

chatMessageSchema.index({ appointmentId: 1, loggedAt: 1 });

const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
export default ChatMessage;
