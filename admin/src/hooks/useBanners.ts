import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Banner } from '@/types/models';
import { API_BANNERS } from '@/constants/routes';

export function useBanners() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchBanners = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_BANNERS);
      setBanners(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch banners');
    } finally {
      setLoading(false);
    }
  }, []);

  const createBanner = async (payload: Omit<Banner, '_id' | 'imagePath'>) => {
    const res: any = await api.post(API_BANNERS, payload);
    return res.data;
  };

  const updateBanner = async (id: string, payload: Partial<Banner>) => {
    const res: any = await api.put(`${API_BANNERS}/${id}`, payload);
    return res.data;
  };

  const deleteBanner = async (id: string) => {
    try {
      await api.delete(`${API_BANNERS}/${id}`);
      setBanners(prev => prev.filter(banner => banner._id !== id));
      toast.success('Banner deleted successfully');
    } catch (err: any) {
      toast.error(err.message || 'Failed to delete banner');
      throw err;
    }
  };

  const uploadBannerImage = async (id: string, file: File) => {
    toast.loading('Uploading banner image...', { id: 'banner-upload' });
    try {
      const uploadRes: any = await api.upload(`${API_BANNERS}/${id}/image`, file, 'image');
      toast.success('Image uploaded successfully', { id: 'banner-upload' });
      return uploadRes.data;
    } catch (err: any) {
      toast.error(err.message || 'Banner image upload failed', { id: 'banner-upload' });
      throw err;
    }
  };

  return {
    banners,
    loading,
    fetchBanners,
    createBanner,
    updateBanner,
    deleteBanner,
    uploadBannerImage,
  };
}
export default useBanners;
