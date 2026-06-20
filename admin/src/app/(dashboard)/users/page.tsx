"use client";

import React, { useEffect, useState } from 'react';
import { useUsers } from '@/hooks/useUsers';
import { toast } from 'sonner';
import { ShieldAlert } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { getAdminUser } from '@/lib/auth';

import { User } from '@/types/models';
import { PageHeader } from '@/components/shared/PageHeader';
import { SearchBar } from '@/components/shared/SearchBar';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function UsersPage() {
  const {
    users,
    loading,
    fetchUsers,
    updateUserRole,
    toggleUserActive,
  } = useUsers();

  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [currentAdmin, setCurrentAdmin] = useState<any>(null);

  useEffect(() => {
    setCurrentAdmin(getAdminUser());
    fetchUsers();
  }, [fetchUsers]);

  const handleRoleChange = async (userId: string, newRole: 'user' | 'admin' | 'provider') => {
    if (userId === currentAdmin?.userId) {
      toast.error('You cannot change your own admin role');
      return;
    }

    try {
      await updateUserRole(userId, newRole);
    } catch (err: any) {
      // toast is already fired inside the hook
    }
  };

  const handleToggleActive = async (userId: string) => {
    if (userId === currentAdmin?.userId) {
      toast.error('You cannot deactivate your own admin account');
      return;
    }

    try {
      await toggleUserActive(userId);
    } catch (err: any) {
      // toast is already fired inside the hook
    }
  };

  const filteredUsers = users.filter(u => {
    const matchesSearch = u.name.toLowerCase().includes(search.toLowerCase()) || 
                          u.email.toLowerCase().includes(search.toLowerCase()) ||
                          (u.phone && u.phone.includes(search));
    const matchesRole = roleFilter === 'ALL' || u.role === roleFilter;
    const matchesStatus = statusFilter === 'ALL' || 
                          (statusFilter === 'ACTIVE' && u.isActive) ||
                          (statusFilter === 'INACTIVE' && !u.isActive);
    return matchesSearch && matchesRole && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <PageHeader 
        title="User Accounts"
        description="View registered users, change role levels, and disable/enable accounts."
      />

      {/* Filter Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <SearchBar 
          value={search}
          onChange={setSearch}
          placeholder="Search by name, email, phone..."
        />

        <Select value={roleFilter} onValueChange={(val) => setRoleFilter(val || 'ALL')}>
          <SelectTrigger className="w-[150px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Role" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Roles</SelectItem>
            <SelectItem value="user">User</SelectItem>
            <SelectItem value="provider">Provider</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
          </SelectContent>
        </Select>

        <Select value={statusFilter} onValueChange={(val) => setStatusFilter(val || 'ALL')}>
          <SelectTrigger className="w-[150px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Statuses</SelectItem>
            <SelectItem value="ACTIVE">Active Only</SelectItem>
            <SelectItem value="INACTIVE">Inactive Only</SelectItem>
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
                  <TableHead className="text-muted-foreground">Name</TableHead>
                  <TableHead className="text-muted-foreground">Email / Phone</TableHead>
                  <TableHead className="text-muted-foreground">Role</TableHead>
                  <TableHead className="text-muted-foreground">Active</TableHead>
                  <TableHead className="text-muted-foreground">Joined</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.length === 0 ? (
                  <EmptyState colSpan={5} message="No user accounts found." />
                ) : (
                  filteredUsers.map(user => (
                    <TableRow key={user._id} className="hover:bg-muted/10 border-border">
                      <TableCell className="font-semibold text-foreground">
                        {user.name}
                        {user._id === currentAdmin?.userId && (
                          <span className="ml-2 bg-primary/30 text-foreground text-[9px] px-1.5 py-0.5 rounded font-bold uppercase tracking-wider">You</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="text-sm font-medium text-foreground">{user.email}</div>
                        {user.phone && <div className="text-[10px] text-muted-foreground font-mono">{user.phone}</div>}
                      </TableCell>
                      <TableCell>
                        <Select 
                          value={user.role} 
                          disabled={user._id === currentAdmin?.userId}
                          onValueChange={(val: any) => handleRoleChange(user._id, val)}
                        >
                          <SelectTrigger className="w-[120px] h-8 bg-input border-border text-xs text-foreground focus:border-primary">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-popover border-border text-foreground">
                            <SelectItem value="user">User</SelectItem>
                            <SelectItem value="provider">Provider</SelectItem>
                            <SelectItem value="admin">Admin</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Switch 
                            checked={user.isActive} 
                            disabled={user._id === currentAdmin?.userId}
                            onCheckedChange={() => handleToggleActive(user._id)}
                            className="data-[state=checked]:bg-primary data-[state=unchecked]:bg-muted h-5 w-9 [&>span]:h-4 [&>span]:w-4"
                          />
                          <span className={`text-xs ${user.isActive ? 'text-emerald-600 dark:text-emerald-400 font-semibold' : 'text-muted-foreground'}`}>
                            {user.isActive ? 'Active' : 'Disabled'}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell className="text-xs font-mono text-muted-foreground">
                        {new Date(user.createdAt).toLocaleDateString()}
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
