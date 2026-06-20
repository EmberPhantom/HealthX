"use client";

import React, { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  Stethoscope, 
  ShoppingBag, 
  Tags, 
  Image as ImageIcon, 
  Users, 
  ClipboardList, 
  Calendar,
  LogOut,
  Menu,
  X,
  User as UserIcon
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { getToken, getAdminUser, clearToken } from '@/lib/auth';
import { cn } from '@/lib/utils';
import { ThemeToggle } from '@/components/theme-toggle';

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
}

const navItems: NavItem[] = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Doctors', href: '/doctors', icon: Stethoscope },
  { name: 'Menu Items', href: '/menu-items', icon: ShoppingBag },
  { name: 'Categories', href: '/categories', icon: Tags },
  { name: 'Banners', href: '/banners', icon: ImageIcon },
  { name: 'Users', href: '/users', icon: Users },
  { name: 'Orders', href: '/orders', icon: ClipboardList },
  { name: 'Appointments', href: '/appointments', icon: Calendar },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [loading, setLoading] = useState(true);
  const [adminUser, setAdminUser] = useState<any>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    const token = getToken();
    const user = getAdminUser();

    if (!token || !user || user.role !== 'admin') {
      clearToken();
      router.push('/login');
    } else {
      setAdminUser(user);
      setLoading(false);
    }
  }, [router]);

  const handleLogout = () => {
    clearToken();
    router.push('/login');
  };

  const SidebarContent = ({ onClose }: { onClose?: () => void }) => (
    <div className="flex flex-col h-full bg-[var(--sidebar)] text-[var(--sidebar-foreground)]">
      <div className="h-16 flex items-center justify-between px-6 border-b border-[var(--sidebar-border)] gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--sidebar-primary)] text-[var(--sidebar-primary-foreground)] font-black text-sm">
            HX
          </div>
          <div>
            <h1 className="font-semibold text-sm leading-none text-[var(--sidebar-foreground)]">HealthX Admin</h1>
            <span className="text-[10px] text-muted-foreground font-medium">Console</span>
          </div>
        </div>
        {onClose && (
          <Button variant="ghost" size="icon" onClick={onClose} className="text-gray-400 hover:text-white md:hidden">
            <X className="h-5 w-5" />
          </Button>
        )}
      </div>

      <nav className="flex-1 px-4 py-6 space-y-1.5 overflow-y-auto">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={onClose}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors duration-150",
                isActive 
                  ? "bg-[var(--sidebar-accent)] text-[var(--sidebar-foreground)] border-l-2 border-[var(--sidebar-primary)]" 
                  : "text-muted-foreground hover:text-[var(--sidebar-foreground)] hover:bg-[var(--sidebar-accent)]/50"
              )}
            >
              <Icon className={cn("h-4 w-4", isActive ? "text-[var(--sidebar-primary)]" : "text-muted-foreground")} />
              {item.name}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-[var(--sidebar-border)] flex items-center justify-between mt-auto">
        <div className="flex items-center gap-3 overflow-hidden">
          <div className="h-9 w-9 rounded-full bg-[var(--sidebar-accent)] flex items-center justify-center flex-shrink-0">
            <UserIcon className="h-4 w-4 text-muted-foreground" />
          </div>
          <div className="overflow-hidden">
            <p className="text-xs font-semibold text-[var(--sidebar-foreground)] truncate">{adminUser?.name}</p>
            <p className="text-[10px] text-muted-foreground truncate">{adminUser?.email}</p>
          </div>
        </div>
        <Button 
          variant="ghost" 
          size="icon" 
          onClick={handleLogout}
          className="text-muted-foreground hover:text-red-400 hover:bg-red-500/10 h-8 w-8"
        >
          <LogOut className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="flex h-screen w-screen items-center justify-center bg-background text-primary">
        <div className="flex flex-col items-center gap-2">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-muted-foreground font-medium">Verifying authorization...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen w-screen bg-background text-foreground overflow-hidden">
      {/* Sidebar - Desktop */}
      <aside className="hidden md:block w-64 border-r border-[var(--sidebar-border)] flex-shrink-0">
        <SidebarContent />
      </aside>

      {/* Sidebar - Mobile drawer */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden bg-black/50 backdrop-blur-sm">
          <div className="w-64 h-full animate-in slide-in-from-left duration-200">
            <SidebarContent onClose={() => setSidebarOpen(false)} />
          </div>
        </div>
      )}

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="h-16 flex items-center justify-between px-6 border-b border-border bg-card">
          <div className="flex items-center gap-3">
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden text-muted-foreground hover:text-foreground"
              onClick={() => setSidebarOpen(true)}
            >
              <Menu className="h-6 w-6" />
            </Button>
            <h2 className="text-lg font-bold capitalize text-foreground">
              {pathname.substring(1).replace('-', ' ')}
            </h2>
          </div>

          <div className="flex items-center gap-4">
            <ThemeToggle />
            <div className="hidden sm:flex flex-col text-right">
              <span className="text-xs font-semibold text-foreground">{adminUser?.name}</span>
              <span className="text-[10px] text-muted-foreground font-mono tracking-wider uppercase">{adminUser?.role}</span>
            </div>
            <div className="h-9 w-9 rounded-full bg-primary text-primary-foreground border border-border flex items-center justify-center font-black">
              {adminUser?.name?.charAt(0).toUpperCase()}
            </div>
          </div>
        </header>

        {/* Page Content viewport */}
        <main className="flex-1 overflow-y-auto p-6 bg-background">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
