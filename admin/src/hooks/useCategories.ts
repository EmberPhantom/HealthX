import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Category } from '@/types/models';
import { API_CATEGORIES } from '@/constants/routes';

export function useCategories() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchCategories = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_CATEGORIES);
      setCategories(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch categories');
    } finally {
      setLoading(false);
    }
  }, []);

  const createCategory = async (payload: Omit<Category, '_id'>) => {
    const res: any = await api.post(API_CATEGORIES, payload);
    return res.data;
  };

  const updateCategory = async (id: string, payload: Partial<Category>) => {
    const res: any = await api.put(`${API_CATEGORIES}/${id}`, payload);
    return res.data;
  };

  const deleteCategory = async (id: string) => {
    try {
      await api.delete(`${API_CATEGORIES}/${id}`);
      setCategories(prev => prev.filter(cat => cat._id !== id));
      toast.success('Category deleted successfully');
    } catch (err: any) {
      toast.error(err.message || 'Failed to delete category');
      throw err;
    }
  };

  return {
    categories,
    loading,
    fetchCategories,
    createCategory,
    updateCategory,
    deleteCategory,
  };
}
export default useCategories;
