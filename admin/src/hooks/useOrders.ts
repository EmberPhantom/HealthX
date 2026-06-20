import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Order } from '@/types/models';
import { API_ORDERS } from '@/constants/routes';

export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchOrders = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_ORDERS);
      setOrders(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch orders');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateOrderStatus = async (orderId: string, status: string) => {
    try {
      const res: any = await api.patch(`${API_ORDERS}/${orderId}/status`, { status });
      setOrders(prev => prev.map(o => o._id === orderId ? res.data : o));
      toast.success('Order status updated successfully');
      return res.data;
    } catch (err: any) {
      toast.error(err.message || 'Failed to update order status');
      throw err;
    }
  };

  return {
    orders,
    loading,
    fetchOrders,
    updateOrderStatus,
  };
}
export default useOrders;
