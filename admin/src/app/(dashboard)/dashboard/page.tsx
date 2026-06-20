"use client";

import React, { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { toast } from 'sonner';
import { Users, Stethoscope, ShoppingBag, Calendar, ArrowUpRight, TrendingUp } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';
import { API_STATS } from '@/constants/routes';
import { PageHeader } from '@/components/shared/PageHeader';
import { Skeleton } from '@/components/ui/skeleton';

export default function DashboardPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const res: any = await api.get(API_STATS);
      setData(res.data);
    } catch (err: any) {
      toast.error(err.message || 'Failed to fetch dashboard stats');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="bg-card border-border animate-pulse">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-8 w-8 rounded-full" />
              </CardHeader>
              <CardContent className="space-y-2">
                <Skeleton className="h-8 w-16" />
                <Skeleton className="h-3 w-32" />
              </CardContent>
            </Card>
          ))}
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <Card className="bg-card border-border h-96 animate-pulse p-4">
            <Skeleton className="h-6 w-1/3 mb-4" />
            <Skeleton className="h-full w-full" />
          </Card>
          <Card className="bg-card border-border h-96 animate-pulse p-4">
            <Skeleton className="h-6 w-1/3 mb-4" />
            <Skeleton className="h-full w-full" />
          </Card>
        </div>
      </div>
    );
  }

  const { stats, recentAppointments, recentOrders } = data || {};

  const statItems = [
    { name: 'Total Users', value: stats?.totalUsers || 0, icon: Users, color: 'text-blue-500', bg: 'bg-blue-500/10' },
    { name: 'Active Doctors', value: stats?.activeDoctors || 0, icon: Stethoscope, color: 'text-emerald-500', bg: 'bg-emerald-500/10' },
    { name: 'Total Orders', value: stats?.totalOrders || 0, icon: ShoppingBag, color: 'text-amber-500', bg: 'bg-amber-500/10' },
    { name: 'Total Appointments', value: stats?.totalAppointments || 0, icon: Calendar, color: 'text-purple-500', bg: 'bg-purple-500/10' },
  ];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Welcome to HealthX Admin" 
        description="Here's what is happening across the platform today."
      />

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statItems.map((item, idx) => {
          const Icon = item.icon;
          return (
            <Card key={idx} className="bg-card border-border">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{item.name}</CardTitle>
                <div className={`${item.bg} ${item.color} p-2 rounded-full`}>
                  <Icon className="h-4 w-4" />
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-foreground">{item.value}</div>
                <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                  <TrendingUp className="h-3 w-3 text-emerald-500" /> Active data on server
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Recent Appointments */}
        <Card className="bg-card border-border">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle className="text-md">Recent Appointments</CardTitle>
              <CardDescription className="text-xs text-muted-foreground">Latest consultations scheduled by patients</CardDescription>
            </div>
            <Link href="/appointments" className="text-xs text-foreground font-semibold hover:underline flex items-center gap-0.5">
              View All <ArrowUpRight className="h-3 w-3" />
            </Link>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader className="border-border">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="text-muted-foreground">Patient</TableHead>
                  <TableHead className="text-muted-foreground">Doctor</TableHead>
                  <TableHead className="text-muted-foreground text-right">Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentAppointments?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center py-6 text-muted-foreground text-sm">
                      No appointments found
                    </TableCell>
                  </TableRow>
                ) : (
                  recentAppointments?.map((appt: any) => (
                    <TableRow key={appt._id} className="hover:bg-muted/10 border-border">
                      <TableCell className="font-medium text-foreground">{appt.userId?.name || 'Unknown User'}</TableCell>
                      <TableCell>
                        <p className="text-sm font-semibold text-foreground">{appt.doctorId?.name}</p>
                        <p className="text-[10px] text-muted-foreground">{appt.doctorId?.specialty}</p>
                      </TableCell>
                      <TableCell className="text-right">
                        <Badge 
                          variant={appt.status === 'confirmed' ? 'default' : appt.status === 'completed' ? 'secondary' : 'outline'}
                          className={
                            appt.status === 'confirmed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' :
                            appt.status === 'cancelled' ? 'bg-red-500/10 text-red-400 border-red-500/20' :
                            appt.status === 'completed' ? 'bg-blue-500/10 text-blue-400 border-blue-500/20' :
                            'bg-amber-500/10 text-amber-400 border-amber-500/20'
                          }
                        >
                          {appt.status}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        {/* Recent Orders */}
        <Card className="bg-card border-border">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle className="text-md">Recent Orders</CardTitle>
              <CardDescription className="text-xs text-muted-foreground">Latest shop purchases and deliveries</CardDescription>
            </div>
            <Link href="/orders" className="text-xs text-foreground font-semibold hover:underline flex items-center gap-0.5">
              View All <ArrowUpRight className="h-3 w-3" />
            </Link>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader className="border-border">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="text-muted-foreground">User</TableHead>
                  <TableHead className="text-muted-foreground">Total</TableHead>
                  <TableHead className="text-muted-foreground text-right">Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentOrders?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center py-6 text-muted-foreground text-sm">
                      No orders found
                    </TableCell>
                  </TableRow>
                ) : (
                  recentOrders?.map((order: any) => (
                    <TableRow key={order._id} className="hover:bg-muted/10 border-border">
                      <TableCell className="font-medium text-foreground">{order.userId?.name || 'Unknown User'}</TableCell>
                      <TableCell className="text-foreground">₹{order.total}</TableCell>
                      <TableCell className="text-right">
                        <Badge 
                          className={
                            order.status === 'delivered' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' :
                            order.status === 'cancelled' ? 'bg-red-500/10 text-red-400 border-red-500/20' :
                            'bg-blue-500/10 text-blue-400 border-blue-500/20'
                          }
                        >
                          {order.status}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
