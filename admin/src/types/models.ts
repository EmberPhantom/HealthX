export interface Slot {
  day: string;
  times: string[];
}

export interface Doctor {
  _id?: string;
  name: string;
  specialty: string;
  qualification: string;
  experience: number;
  consultationFee: number;
  rating?: number;
  reviewCount?: number;
  clinicName: string;
  address: string;
  city: string;
  languages: string[];
  availableSlots: Slot[];
  isActive: boolean;
  avatarUrl?: string;
}

export interface MenuItem {
  _id?: string;
  name: string;
  description: string;
  price: number;
  calories: number;
  imageUrl: string;
  emoji: string;
  category: string;
  type: 'Regular' | 'ReadyToEat';
  tags: string[];
  isVeg: boolean;
}

export interface Category {
  _id?: string;
  name: string;
  emoji: string;
}

export interface Banner {
  _id?: string;
  title: string;
  subtitle: string;
  chipLabel: string;
  imagePath: string;
}

export interface User {
  _id: string;
  name: string;
  email: string;
  phone?: string;
  role: 'user' | 'admin' | 'provider';
  isActive: boolean;
  createdAt: string;
}

export interface OrderItem {
  menuItemId: string;
  name: string;
  quantity: number;
  price: number;
}

export interface Order {
  _id: string;
  userId?: {
    name: string;
    email: string;
    phone?: string;
  };
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  tax: number;
  total: number;
  status: 'placed' | 'confirmed' | 'preparing' | 'on_the_way' | 'delivered' | 'cancelled';
  paymentMethod: string;
  isPaid: boolean;
  createdAt: string;
}

export interface Appointment {
  _id: string;
  userId?: {
    name: string;
    email: string;
    phone?: string;
  };
  doctorId?: {
    name: string;
    specialty: string;
  };
  appointmentDate: string;
  timeSlot: string;
  type: 'in-person' | 'video';
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  consultationFee: number;
  isPaid: boolean;
  createdAt: string;
}
