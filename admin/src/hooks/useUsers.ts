import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { User } from '@/types/models';
import { API_USERS } from '@/constants/routes';

export function useUsers() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_USERS);
      setUsers(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch users list');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateUserRole = async (userId: string, role: 'user' | 'admin' | 'provider') => {
    try {
      const res: any = await api.patch(`${API_USERS}/${userId}/role`, { role });
      setUsers(prev => prev.map(u => u._id === userId ? res.data : u));
      toast.success('User role updated successfully');
      return res.data;
    } catch (err: any) {
      toast.error(err.message || 'Failed to update user role');
      throw err;
    }
  };

  const toggleUserActive = async (userId: string) => {
    try {
      const res: any = await api.patch(`${API_USERS}/${userId}/toggle`);
      setUsers(prev => prev.map(u => u._id === userId ? res.data : u));
      toast.success('User status updated successfully');
      return res.data;
    } catch (err: any) {
      toast.error(err.message || 'Failed to update user status');
      throw err;
    }
  };

  return {
    users,
    loading,
    fetchUsers,
    updateUserRole,
    toggleUserActive,
  };
}
export default useUsers;
