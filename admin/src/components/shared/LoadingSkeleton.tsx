import React from 'react';
import { Skeleton } from '@/components/ui/skeleton';
import { Card } from '@/components/ui/card';

interface LoadingSkeletonProps {
  variant?: 'table' | 'grid' | 'list';
  count?: number;
  className?: string;
}

export function LoadingSkeleton({ variant = 'table', count = 3, className }: LoadingSkeletonProps) {
  if (variant === 'grid') {
    return (
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: count }).map((_, i) => (
          <Card key={i} className="border-border bg-card h-64 p-4 flex flex-col justify-between animate-pulse">
            <div className="space-y-3">
              <Skeleton className="h-32 w-full rounded-md" />
              <Skeleton className="h-6 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
            </div>
            <Skeleton className="h-8 w-24 self-end" />
          </Card>
        ))}
      </div>
    );
  }

  if (variant === 'list') {
    return (
      <div className="space-y-3">
        {Array.from({ length: count }).map((_, i) => (
          <Card key={i} className="border-border bg-card p-4 flex items-center justify-between animate-pulse">
            <div className="flex items-center gap-3">
              <Skeleton className="h-10 w-10 rounded-full" />
              <div className="space-y-2">
                <Skeleton className="h-4 w-28" />
                <Skeleton className="h-3 w-16" />
              </div>
            </div>
            <Skeleton className="h-8 w-16" />
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {Array.from({ length: count }).map((_, i) => (
        <Card key={i} className="border-border bg-card h-16 flex items-center justify-between px-6 animate-pulse">
          <div className="flex items-center gap-4 w-full">
            <Skeleton className="h-10 w-10 rounded-md" />
            <div className="space-y-2 flex-1">
              <Skeleton className="h-4 w-1/4" />
              <Skeleton className="h-3 w-1/3" />
            </div>
            <Skeleton className="h-8 w-20" />
          </div>
        </Card>
      ))}
    </div>
  );
}
export default LoadingSkeleton;
