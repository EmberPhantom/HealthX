"use client";

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import Script from 'next/script';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { setToken, setAdminUser, getToken } from '@/lib/auth';
import { api } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleGoogleSignIn = React.useCallback(async (response: any) => {
    setIsLoading(true);
    try {
      const res: any = await api.post('/api/v1/auth/google', {
        idToken: response.credential,
      });

      const { user, accessToken } = res.data;

      if (user.role !== 'admin') {
        toast.error('Access Denied: Only administrators can access this portal');
        setIsLoading(false);
        return;
      }

      setToken(accessToken);
      setAdminUser({
        userId: user.id || user._id,
        role: user.role,
        email: user.email,
        name: user.name,
      });

      toast.success(`Welcome back, ${user.name}!`);
      router.push('/dashboard');
    } catch (error: any) {
      toast.error(error.message || 'Google Sign-In failed.');
    } finally {
      setIsLoading(false);
    }
  }, [router]);

  const initGoogleSdk = React.useCallback(() => {
    if (typeof window !== 'undefined' && (window as any).google) {
      try {
        const client_id = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID;
        (window as any).google.accounts.id.initialize({
          client_id: client_id,
          callback: handleGoogleSignIn,
        });
        (window as any).google.accounts.id.renderButton(
          document.getElementById('google-signin-btn'),
          { 
            theme: 'filled_blue', 
            size: 'large', 
            text: 'signin_with', 
            shape: 'rectangular',
            width: 340
          }
        );
      } catch (e) {
        console.error('Failed to initialize Google SDK:', e);
      }
    }
  }, [handleGoogleSignIn]);

  useEffect(() => {
    // Redirect if already logged in
    if (getToken()) {
      router.push('/dashboard');
      return;
    }

    // Set up polling interval to initialize Google SDK once loaded
    const checkGoogle = setInterval(() => {
      if (typeof window !== 'undefined' && (window as any).google && document.getElementById('google-signin-btn')) {
        initGoogleSdk();
        clearInterval(checkGoogle);
      }
    }, 100);

    return () => clearInterval(checkGoogle);
  }, [router, initGoogleSdk]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast.error('Please fill in all fields');
      return;
    }

    setIsLoading(true);
    try {
      const response: any = await api.post('/api/v1/auth/login', {
        email,
        password,
      });

      const { user, accessToken } = response.data;

      if (user.role !== 'admin') {
        toast.error('Access Denied: Only administrators can access this portal');
        setIsLoading(false);
        return;
      }

      setToken(accessToken);
      setAdminUser({
        userId: user.id || user._id,
        role: user.role,
        email: user.email,
        name: user.name,
      });

      toast.success(`Welcome back, ${user.name}!`);
      router.push('/dashboard');
    } catch (error: any) {
      toast.error(error.message || 'Login failed. Please check your credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4 relative overflow-hidden">
      <Script 
        src="https://accounts.google.com/gsi/client" 
        onLoad={initGoogleSdk} 
        strategy="afterInteractive"
      />

      {/* Decorative gradient glowing backgrounds */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary/5 rounded-full blur-[120px] pointer-events-none" />

      <Card className="w-full max-w-md bg-card border border-border text-foreground shadow-2xl">
        <CardHeader className="space-y-1 text-center">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground mb-2 font-black text-xl">
            HX
          </div>
          <CardTitle className="text-2xl font-black tracking-tight text-foreground">HealthX Admin</CardTitle>
          <CardDescription className="text-muted-foreground">
            Sign in to access your admin dashboard
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleLogin}>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-semibold text-foreground" htmlFor="email">
                Email Address
              </label>
              <Input
                id="email"
                type="email"
                placeholder="admin@healthx.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="bg-card border-border text-foreground placeholder:text-muted-foreground focus-visible:ring-primary"
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold text-foreground" htmlFor="password">
                Password
              </label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="bg-card border-border text-foreground placeholder:text-muted-foreground focus-visible:ring-primary"
              />
            </div>
          </CardContent>
          <CardFooter className="flex flex-col gap-4">
            <Button
              type="submit"
              disabled={isLoading}
              className="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-bold py-2 rounded-md transition-colors duration-200"
            >
              {isLoading ? 'Signing In...' : 'Sign In'}
            </Button>
            
            <div className="flex items-center w-full justify-between gap-2 text-xs text-muted-foreground">
              <hr className="w-full border-border" />
              <span>OR</span>
              <hr className="w-full border-border" />
            </div>

            <div className="w-full flex justify-center py-1 overflow-hidden">
              <div id="google-signin-btn" style={{ colorScheme: 'dark' }} />
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}
