import mongoose, { Schema, Document } from 'mongoose';

export interface IOrder extends Document {
  userId: mongoose.Types.ObjectId;
  items: Array<{
    menuItemId: mongoose.Types.ObjectId;
    name: string;
    quantity: number;
    price: number;
  }>;
  subtotal: number;
  deliveryFee: number;
  tax: number;
  total: number;
  status: 'placed' | 'confirmed' | 'preparing' | 'on_the_way' | 'delivered' | 'cancelled';
  paymentMethod: string;
  isPaid: boolean;
  addressId?: mongoose.Types.ObjectId;
  deliveryPartner?: {
    name: string;
    phone: string;
    vehicleNo: string;
  };
  estimatedDelivery?: Date;
  cancelledAt?: Date;
  cancelReason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const orderSchema = new Schema<IOrder>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    addressId: { type: Schema.Types.ObjectId, ref: 'Address' },
    items: [{
      menuItemId: { type: Schema.Types.ObjectId, ref: 'MenuItem', required: true },
      name: { type: String, required: true },
      quantity: { type: Number, required: true },
      price: { type: Number, required: true },
    }],
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, required: true },
    tax: { type: Number, required: true },
    total: { type: Number, required: true },
    status: {
      type: String,
      enum: ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered', 'cancelled'],
      default: 'placed'
    },
    paymentMethod: { type: String, required: true },
    isPaid: { type: Boolean, default: false },
    deliveryPartner: {
      name: String,
      phone: String,
      vehicleNo: String,
    },
    estimatedDelivery: Date,
    cancelledAt: Date,
    cancelReason: String,
  },
  { timestamps: true }
);

orderSchema.index({ userId: 1, createdAt: -1 });

const Order = mongoose.model<IOrder>('Order', orderSchema);
export default Order;
