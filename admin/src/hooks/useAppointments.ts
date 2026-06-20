import { useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Appointment } from '@/types/models';
import { API_APPOINTMENTS } from '@/constants/routes';

export function useAppointments() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchAppointments = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_APPOINTMENTS);
      setAppointments(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch appointments');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateAppointmentStatus = async (apptId: string, status: string) => {
    try {
      const res: any = await api.patch(`${API_APPOINTMENTS}/${apptId}/status`, { status });
      setAppointments(prev => prev.map(a => a._id === apptId ? res.data : a));
      toast.success('Appointment status updated successfully');
      return res.data;
    } catch (err: any) {
      toast.error(err.message || 'Failed to update appointment status');
      throw err;
    }
  };

  return {
    appointments,
    loading,
    fetchAppointments,
    updateAppointmentStatus,
  };
}
export default useAppointments;
