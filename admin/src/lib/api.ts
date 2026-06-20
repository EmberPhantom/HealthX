import { getToken, clearToken } from './auth';

class ApiClient {
  private getHeaders(isMultipart = false): HeadersInit {
    const headers: Record<string, string> = {};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    const token = getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    if (response.status === 401) {
      clearToken();
      if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      throw new Error('Unauthorized');
    }

    const data = await response.json().catch(() => ({}));
    
    if (!response.ok) {
      throw new Error(data.message || 'Something went wrong');
    }

    return data;
  }

  async get<T>(url: string): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const response = await fetch(`${baseUrl}${url}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async post<T>(url: string, body?: any): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const response = await fetch(`${baseUrl}${url}`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async put<T>(url: string, body?: any): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const response = await fetch(`${baseUrl}${url}`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async patch<T>(url: string, body?: any): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const response = await fetch(`${baseUrl}${url}`, {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async delete<T>(url: string): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const response = await fetch(`${baseUrl}${url}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async upload<T>(url: string, file: File, fieldName = 'file'): Promise<T> {
    const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? '';
    const formData = new FormData();
    formData.append(fieldName, file);

    const response = await fetch(`${baseUrl}${url}`, {
      method: 'POST',
      headers: this.getHeaders(true),
      body: formData,
    });
    return this.handleResponse<T>(response);
  }
}

export const api = new ApiClient();
export default api;
