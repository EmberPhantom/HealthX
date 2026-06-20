"use client";

import React, { useEffect, useState } from 'react';
import { useOrders } from '@/hooks/useOrders';
import { toast } from 'sonner';
import { Eye } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';

import { Order } from '@/types/models';
import { ORDER_STATUS_OPTIONS } from '@/constants/defaults';
import { PageHeader } from '@/components/shared/PageHeader';
import { SearchBar } from '@/components/shared/SearchBar';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function OrdersPage() {
  const {
    orders,
    loading,
    fetchOrders,
    updateOrderStatus,
  } = useOrders();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const handleStatusChange = async (orderId: string, newStatus: string) => {
    try {
      await updateOrderStatus(orderId, newStatus);
    } catch (err) {
      // toast already fired in hook
    }
  };

  const handleOpenDetails = (order: Order) => {
    setSelectedOrder(order);
    setDetailsOpen(true);
  };

  const filteredOrders = orders.filter(o => {
    const userName = o.userId?.name || 'Unknown';
    const matchesSearch = userName.toLowerCase().includes(search.toLowerCase()) || 
                          o._id.includes(search);
    const matchesStatus = statusFilter === 'ALL' || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Orders Log"
        description="View customer purchases, food delivery progress, and update status."
      />

      {/* Filter Row */}
      <div className="flex flex-wrap items-center gap-3">
        <SearchBar 
          value={search}
          onChange={setSearch}
          placeholder="Search by User or Order ID..."
        />

        <Select value={statusFilter} onValueChange={(val) => setStatusFilter(val || 'ALL')}>
          <SelectTrigger className="w-[180px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Filter Status" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Statuses</SelectItem>
            {ORDER_STATUS_OPTIONS.map(opt => (
              <SelectItem key={opt} value={opt}>{opt.replace('_', ' ')}</SelectItem>
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
                  <TableHead className="text-muted-foreground">Order ID</TableHead>
                  <TableHead className="text-muted-foreground">User</TableHead>
                  <TableHead className="text-muted-foreground">Items Count</TableHead>
                  <TableHead className="text-muted-foreground">Total Price</TableHead>
                  <TableHead className="text-muted-foreground">Status</TableHead>
                  <TableHead className="text-muted-foreground">Payment</TableHead>
                  <TableHead className="text-muted-foreground">Ordered At</TableHead>
                  <TableHead className="text-muted-foreground text-right">Details</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredOrders.length === 0 ? (
                  <EmptyState colSpan={8} message="No orders found matching the filter." />
                ) : (
                  filteredOrders.map(order => (
                    <TableRow key={order._id} className="hover:bg-muted/10 border-border">
                      <TableCell className="font-mono text-xs text-muted-foreground">{order._id.substring(0, 10)}...</TableCell>
                      <TableCell>
                        <div className="font-semibold text-foreground">{order.userId?.name || 'Deleted User'}</div>
                        <div className="text-[10px] text-muted-foreground">{order.userId?.email}</div>
                      </TableCell>
                      <TableCell className="text-foreground">{order.items.reduce((acc, curr) => acc + curr.quantity, 0)} items</TableCell>
                      <TableCell className="font-bold text-foreground">₹{order.total}</TableCell>
                      <TableCell>
                        <Select 
                          value={order.status} 
                          onValueChange={(val: any) => handleStatusChange(order._id, val)}
                        >
                          <SelectTrigger className="w-[140px] h-8 bg-input border-border text-xs text-foreground focus:border-primary">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-popover border-border text-foreground">
                            {ORDER_STATUS_OPTIONS.map(opt => (
                              <SelectItem key={opt} value={opt}>{opt.replace('_', ' ')}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <Badge 
                          className={
                            order.isPaid ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 
                            'bg-red-50 text-red-700 border-red-100'
                          }
                        >
                          {order.isPaid ? 'Paid' : 'Unpaid'}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-xs font-mono text-muted-foreground">
                        {new Date(order.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button 
                          variant="ghost" 
                          size="icon" 
                          onClick={() => handleOpenDetails(order)}
                          className="h-8 w-8 text-muted-foreground hover:text-foreground hover:bg-muted"
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </Card>
      )}

      {/* Details Dialog */}
      <Dialog open={detailsOpen} onOpenChange={setDetailsOpen}>
        <DialogContent className="max-w-md bg-popover border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold">Order Details</DialogTitle>
            <DialogDescription className="text-muted-foreground font-mono text-xs">ID: {selectedOrder?._id}</DialogDescription>
          </DialogHeader>

          {selectedOrder && (
            <div className="space-y-4">
              <div className="space-y-1.5 border-b border-border pb-3">
                <p className="text-xs font-semibold text-muted-foreground uppercase">Customer Information</p>
                <p className="text-sm font-semibold">{selectedOrder.userId?.name}</p>
                <p className="text-xs text-muted-foreground">{selectedOrder.userId?.email}</p>
                {selectedOrder.userId?.phone && <p className="text-xs text-muted-foreground">{selectedOrder.userId.phone}</p>}
              </div>

              <div className="space-y-1.5 border-b border-border pb-3">
                <p className="text-xs font-semibold text-muted-foreground uppercase">Items Ordered</p>
                <div className="space-y-2">
                  {selectedOrder.items.map((item, idx) => (
                    <div key={idx} className="flex justify-between items-center text-xs">
                      <span className="text-foreground">{item.name} <span className="text-muted-foreground">x{item.quantity}</span></span>
                      <span className="font-mono text-foreground">₹{item.price * item.quantity}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="space-y-1.5 text-xs text-muted-foreground">
                <div className="flex justify-between">
                  <span>Subtotal</span>
                  <span>₹{selectedOrder.subtotal}</span>
                </div>
                <div className="flex justify-between">
                  <span>Delivery Fee</span>
                  <span>₹{selectedOrder.deliveryFee}</span>
                </div>
                <div className="flex justify-between">
                  <span>Tax</span>
                  <span>₹{selectedOrder.tax}</span>
                </div>
                <div className="flex justify-between text-sm font-bold text-foreground border-t border-border/50 pt-2">
                  <span>Total</span>
                  <span className="text-foreground font-black">₹{selectedOrder.total}</span>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
