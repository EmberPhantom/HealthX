import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Doctor } from '@/types/models';
import { API_DOCTORS } from '@/constants/routes';

export function useDoctors() {
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchDoctors = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_DOCTORS);
      setDoctors(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch doctors');
    } finally {
      setLoading(false);
    }
  }, []);

  const createDoctor = async (doctorData: Omit<Doctor, '_id'>) => {
    const res: any = await api.post(API_DOCTORS, doctorData);
    return res.data;
  };

  const updateDoctor = async (id: string, doctorData: Partial<Doctor>) => {
    const res: any = await api.put(`${API_DOCTORS}/${id}`, doctorData);
    return res.data;
  };

  const toggleActive = async (id: string) => {
    try {
      const res: any = await api.patch(`${API_DOCTORS}/${id}/toggle`);
      setDoctors(prev => prev.map(d => d._id === id ? res.data : d));
      toast.success('Doctor status updated successfully');
      return res.data;
    } catch (err: any) {
      toast.error(err.message || 'Failed to update status');
      throw err;
    }
  };

  const deleteDoctor = async (id: string) => {
    try {
      await api.delete(`${API_DOCTORS}/${id}`);
      setDoctors(prev => prev.filter(d => d._id !== id));
      toast.success('Doctor deleted successfully');
    } catch (err: any) {
      toast.error(err.message || 'Failed to delete doctor');
      throw err;
    }
  };

  const uploadAvatar = async (id: string, file: File) => {
    toast.loading('Uploading avatar image...', { id: 'avatar-upload' });
    try {
      const uploadRes: any = await api.upload(`${API_DOCTORS}/${id}/avatar`, file, 'file');
      toast.success('Avatar uploaded successfully', { id: 'avatar-upload' });
      return uploadRes.data;
    } catch (err: any) {
      toast.error(err.message || 'Avatar upload failed', { id: 'avatar-upload' });
      throw err;
    }
  };

  return {
    doctors,
    setDoctors,
    loading,
    fetchDoctors,
    createDoctor,
    updateDoctor,
    toggleActive,
    deleteDoctor,
    uploadAvatar,
  };
}
export default useDoctors;
