import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { MenuItem, Category } from '@/types/models';
import { API_MENU_ITEMS, API_CATEGORIES } from '@/constants/routes';

export function useMenuItems() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchItemsAndCategories = useCallback(async () => {
    try {
      setLoading(true);
      const [itemsRes, catRes]: any = await Promise.all([
        api.get(API_MENU_ITEMS),
        api.get(API_CATEGORIES)
      ]);
      setItems(itemsRes.data);
      setCategories(catRes.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to load menu items');
    } finally {
      setLoading(false);
    }
  }, []);

  const createMenuItem = async (payload: Omit<MenuItem, '_id' | 'imageUrl'>) => {
    const res: any = await api.post(API_MENU_ITEMS, payload);
    return res.data;
  };

  const updateMenuItem = async (id: string, payload: Partial<MenuItem>) => {
    const res: any = await api.put(`${API_MENU_ITEMS}/${id}`, payload);
    return res.data;
  };

  const deleteMenuItem = async (id: string) => {
    try {
      await api.delete(`${API_MENU_ITEMS}/${id}`);
      setItems(prev => prev.filter(item => item._id !== id));
      toast.success('Menu item deleted successfully');
    } catch (err: any) {
      toast.error(err.message || 'Failed to delete menu item');
      throw err;
    }
  };

  const uploadImage = async (id: string, file: File) => {
    toast.loading('Uploading item image...', { id: 'image-upload' });
    try {
      const uploadRes: any = await api.upload(`${API_MENU_ITEMS}/${id}/image`, file, 'image');
      toast.success('Image uploaded successfully', { id: 'image-upload' });
      return uploadRes.data;
    } catch (err: any) {
      toast.error(err.message || 'Image upload failed', { id: 'image-upload' });
      throw err;
    }
  };

  return {
    items,
    categories,
    loading,
    fetchItemsAndCategories,
    createMenuItem,
    updateMenuItem,
    deleteMenuItem,
    uploadImage,
  };
}
export default useMenuItems;
