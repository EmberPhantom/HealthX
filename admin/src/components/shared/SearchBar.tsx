import React from 'react';
import { Search } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}

export function SearchBar({ value, onChange, placeholder = 'Search...', className }: SearchBarProps) {
  return (
    <div className={cn(
      "flex items-center gap-2 w-full sm:max-w-xs bg-card border border-border rounded-md px-3 py-1.5 focus-within:border-primary focus-within:ring-1 focus-within:ring-primary transition-all duration-150",
      className
    )}>
      <Search className="h-4 w-4 text-muted-foreground" />
      <input 
        type="text" 
        placeholder={placeholder} 
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="bg-transparent text-sm w-full outline-none text-foreground placeholder-muted-foreground"
      />
    </div>
  );
}
export default SearchBar;
