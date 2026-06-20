import React, { useRef } from 'react';
import { Camera } from 'lucide-react';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';
import { cn } from '@/lib/utils';

interface ImageUploadProps {
  filePreview: string;
  onFileChange: (file: File) => void;
  label?: string;
  description?: string;
  fallbackText?: string;
  fallbackEmoji?: string;
  aspectRatio?: 'square' | 'video' | 'circle';
  className?: string;
}

export function ImageUpload({
  filePreview,
  onFileChange,
  label = 'Upload Image',
  description = 'PNG, JPG, WEBP. Max 5MB.',
  fallbackText = 'IMG',
  fallbackEmoji,
  aspectRatio = 'square',
  className,
}: ImageUploadProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onFileChange(e.target.files[0]);
    }
  };

  const triggerSelect = () => {
    fileInputRef.current?.click();
  };

  const getFullImageUrl = (path: string) => {
    if (!path) return '';
    if (path.startsWith('blob:') || path.startsWith('http:') || path.startsWith('https:')) {
      return path;
    }
    const apiBase = process.env.NEXT_PUBLIC_API_URL ?? '';
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    return `${apiBase}${normalizedPath}`;
  };

  const resolvedSrc = getFullImageUrl(filePreview);

  if (aspectRatio === 'circle') {
    return (
      <div className={cn("flex items-center gap-4 py-2 border-b border-border/50", className)}>
        <div className="relative">
          <div className="h-16 w-16 border border-border bg-muted rounded-full overflow-hidden flex items-center justify-center">
            {resolvedSrc ? (
              <img 
                src={resolvedSrc} 
                alt="Preview" 
                className="object-cover w-full h-full"
              />
            ) : (
              <span className="text-muted-foreground text-lg font-bold">
                {fallbackEmoji || fallbackText}
              </span>
            )}
          </div>
          <button
            type="button"
            onClick={triggerSelect}
            className="absolute -bottom-1 -right-1 bg-primary hover:bg-primary/90 text-primary-foreground p-1.5 rounded-full cursor-pointer transition-colors shadow"
          >
            <Camera className="h-3 w-3" />
          </button>
        </div>
        <div>
          <p className="text-sm font-semibold text-foreground">{label}</p>
          <p className="text-xs text-muted-foreground">{description}</p>
        </div>
        <input
          type="file"
          ref={fileInputRef}
          accept="image/*"
          onChange={handleFileChange}
          className="hidden"
        />
      </div>
    );
  }

  // Rectangle / Banner / Square
  return (
    <div className={cn("space-y-1.5", className)}>
      <label className="text-xs font-semibold text-muted-foreground">{label}</label>
      <div className="flex items-center gap-4 p-3 bg-muted/20 border border-border rounded-md">
        <div className={cn(
          "relative border border-border bg-muted overflow-hidden flex items-center justify-center rounded-md flex-shrink-0",
          aspectRatio === 'square' ? 'h-16 w-16' : 'h-16 w-28'
        )}>
          {resolvedSrc ? (
            <img 
              src={resolvedSrc} 
              alt="Preview" 
              className="object-cover w-full h-full"
            />
          ) : (
            <span className="text-muted-foreground text-xs font-semibold uppercase font-mono">
              {fallbackEmoji || fallbackText}
            </span>
          )}
        </div>
        <div className="flex-1">
          <button
            type="button"
            onClick={triggerSelect}
            className="bg-primary hover:bg-primary/90 text-primary-foreground px-3 py-1.5 text-xs rounded font-medium cursor-pointer transition-colors inline-block"
          >
            Select File
          </button>
          <p className="text-[10px] text-muted-foreground mt-1">{description}</p>
        </div>
      </div>
      <input
        type="file"
        ref={fileInputRef}
        accept="image/*"
        onChange={handleFileChange}
        className="hidden"
      />
    </div>
  );
}
export default ImageUpload;
