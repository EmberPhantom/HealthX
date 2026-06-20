"use client";

import React, { useEffect, useState } from 'react';
import { useAppointments } from '@/hooks/useAppointments';
import { toast } from 'sonner';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

import { Appointment } from '@/types/models';
import { APPOINTMENT_STATUS_OPTIONS } from '@/constants/defaults';
import { PageHeader } from '@/components/shared/PageHeader';
import { SearchBar } from '@/components/shared/SearchBar';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function AppointmentsPage() {
  const {
    appointments,
    loading,
    fetchAppointments,
    updateAppointmentStatus,
  } = useAppointments();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  useEffect(() => {
    fetchAppointments();
  }, [fetchAppointments]);

  const handleStatusChange = async (apptId: string, newStatus: string) => {
    try {
      await updateAppointmentStatus(apptId, newStatus);
    } catch (err) {
      // toast is already fired inside the hook
    }
  };

  const filteredAppointments = appointments.filter(a => {
    const userName = a.userId?.name || 'Unknown';
    const doctorName = a.doctorId?.name || 'Unknown';
    const matchesSearch = userName.toLowerCase().includes(search.toLowerCase()) || 
                          doctorName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || a.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Consultation Appointments"
        description="View patient doctor bookings, telemedicine sessions, and update appointment status."
      />

      {/* Filter Row */}
      <div className="flex flex-wrap items-center gap-3">
        <SearchBar 
          value={search}
          onChange={setSearch}
          placeholder="Search Patient or Doctor..."
        />

        <Select value={statusFilter} onValueChange={(val) => setStatusFilter(val || 'ALL')}>
          <SelectTrigger className="w-[180px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Filter Status" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Statuses</SelectItem>
            {APPOINTMENT_STATUS_OPTIONS.map(opt => (
              <SelectItem key={opt} value={opt}>{opt}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {loading ? (
        <LoadingSkeleton variant="table" count={3} />
      ) : (
        <Card className="bg-card border-border overflow-hidden">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader className="border-border">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="text-muted-foreground">Patient</TableHead>
                  <TableHead className="text-muted-foreground">Doctor</TableHead>
                  <TableHead className="text-muted-foreground">Date & Time</TableHead>
                  <TableHead className="text-muted-foreground">Type</TableHead>
                  <TableHead className="text-muted-foreground">Fee</TableHead>
                  <TableHead className="text-muted-foreground">Status</TableHead>
                  <TableHead className="text-muted-foreground">Payment</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredAppointments.length === 0 ? (
                  <EmptyState colSpan={7} message="No appointments found matching the filter." />
                ) : (
                  filteredAppointments.map(appt => (
                    <TableRow key={appt._id} className="hover:bg-muted/10 border-border">
                      <TableCell>
                        <div className="font-semibold text-foreground">{appt.userId?.name || 'Deleted User'}</div>
                        <div className="text-[10px] text-muted-foreground">{appt.userId?.email}</div>
                      </TableCell>
                      <TableCell>
                        <div className="font-semibold text-foreground">{appt.doctorId?.name || 'Deleted Doctor'}</div>
                        <div className="text-[10px] text-muted-foreground">{appt.doctorId?.specialty}</div>
                      </TableCell>
                      <TableCell>
                        <div className="text-sm font-semibold text-foreground">
                          {new Date(appt.appointmentDate).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}
                        </div>
                        <div className="text-[10px] text-muted-foreground font-mono mt-0.5">{appt.timeSlot}</div>
                      </TableCell>
                      <TableCell>
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${appt.type === 'video' ? 'bg-indigo-50 text-indigo-700 border border-indigo-100' : 'bg-amber-50 text-amber-700 border border-amber-100'}`}>
                          {appt.type}
                        </span>
                      </TableCell>
                      <TableCell className="font-semibold text-foreground">₹{appt.consultationFee}</TableCell>
                      <TableCell>
                        <Select 
                          value={appt.status} 
                          onValueChange={(val: any) => handleStatusChange(appt._id, val)}
                        >
                          <SelectTrigger className="w-[130px] h-8 bg-input border-border text-xs text-foreground focus:border-primary">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-popover border-border text-foreground">
                            {APPOINTMENT_STATUS_OPTIONS.map(opt => (
                              <SelectItem key={opt} value={opt}>{opt}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <Badge 
                          className={
                            appt.isPaid ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 
                            'bg-red-50 text-red-700 border-red-100'
                          }
                        >
                          {appt.isPaid ? 'Paid' : 'Unpaid'}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </Card>
      )}
    </div>
  );
}
