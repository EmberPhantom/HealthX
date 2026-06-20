export interface AdminUser {
  userId: string;
  role: string;
  email?: string;
  name?: string;
}

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('healthx_admin_token');
}

export function setToken(token: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem('healthx_admin_token', token);
}

export function clearToken(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem('healthx_admin_token');
  localStorage.removeItem('healthx_admin_user');
}

export function getAdminUser(): AdminUser | null {
  if (typeof window === 'undefined') return null;
  const userStr = localStorage.getItem('healthx_admin_user');
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch (e) {
    return null;
  }
}

export function setAdminUser(user: AdminUser): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem('healthx_admin_user', JSON.stringify(user));
}

export function decodeJwt(token: string): any {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      window
        .atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}
