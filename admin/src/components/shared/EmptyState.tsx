import React from 'react';
import { TableRow, TableCell } from '@/components/ui/table';

interface EmptyStateProps {
  message: string;
  colSpan?: number;
  action?: React.ReactNode;
}

export function EmptyState({ message, colSpan, action }: EmptyStateProps) {
  const content = (
    <div className="flex flex-col items-center justify-center text-center p-8 border border-dashed border-border/60 rounded-md bg-card/30">
      <p className="text-muted-foreground text-sm font-medium mb-3">{message}</p>
      {action}
    </div>
  );

  if (colSpan !== undefined) {
    return (
      <TableRow>
        <TableCell colSpan={colSpan} className="p-0 border-none">
          <div className="py-8 px-4 flex justify-center w-full">
            {content}
          </div>
        </TableCell>
      </TableRow>
    );
  }

  return content;
}
export default EmptyState;
