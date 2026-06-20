"use client";

import React, { useEffect, useState } from 'react';
import { useBanners } from '@/hooks/useBanners';
import { toast } from 'sonner';
import { Plus, Trash2, Edit2 } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardFooter, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';

import { Banner } from '@/types/models';
import { PageHeader } from '@/components/shared/PageHeader';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { ImageUpload } from '@/components/shared/ImageUpload';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';

export default function BannersPage() {
  const {
    banners,
    loading,
    fetchBanners,
    createBanner,
    updateBanner,
    deleteBanner,
    uploadBannerImage,
  } = useBanners();

  const [isOpen, setIsOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);

  // Form States
  const [title, setTitle] = useState('');
  const [subtitle, setSubtitle] = useState('');
  const [chipLabel, setChipLabel] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState('');

  // Delete State
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  useEffect(() => {
    fetchBanners();
  }, [fetchBanners]);

  const handleOpenAdd = () => {
    setEditingBanner(null);
    setTitle('');
    setSubtitle('');
    setChipLabel('');
    setSelectedFile(null);
    setFilePreview('');
    setIsOpen(true);
  };

  const handleOpenEdit = (banner: Banner) => {
    setEditingBanner(banner);
    setTitle(banner.title);
    setSubtitle(banner.subtitle);
    setChipLabel(banner.chipLabel);
    setSelectedFile(null);
    setFilePreview(banner.imagePath || '');
    setIsOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (confirmDeleteId) {
      await deleteBanner(confirmDeleteId);
      setConfirmDeleteId(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !subtitle || !chipLabel) {
      toast.error('Please fill in all required fields');
      return;
    }

    const payload = { title, subtitle, chipLabel };

    try {
      let savedBanner: any;
      if (editingBanner && editingBanner._id) {
        savedBanner = await updateBanner(editingBanner._id, payload);
        toast.success('Banner updated successfully');
      } else {
        if (!selectedFile) {
          toast.error('Please select a banner image');
          return;
        }
        savedBanner = await createBanner(payload);
        toast.success('Banner created successfully');
      }

      // Upload image if selected
      if (selectedFile && savedBanner._id) {
        await uploadBannerImage(savedBanner._id, selectedFile);
      }

      fetchBanners();
      setIsOpen(false);
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong');
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Promotional Banners"
        description="Manage promotional slides featured on the mobile app home screen."
        action={
          <Button onClick={handleOpenAdd} className="bg-primary hover:bg-primary/90 text-primary-foreground flex items-center gap-2">
            <Plus className="h-4 w-4" /> Add Banner
          </Button>
        }
      />

      {loading ? (
        <LoadingSkeleton variant="grid" count={3} />
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {banners.length === 0 ? (
            <div className="col-span-full text-center py-12 text-muted-foreground bg-card rounded-lg border border-border">
              No active banners found. Click "Add Banner" to upload.
            </div>
          ) : (
            banners.map(banner => (
              <Card key={banner._id} className="bg-card border-border overflow-hidden flex flex-col justify-between">
                <div className="relative h-40 bg-muted flex items-center justify-center border-b border-border">
                  {banner.imagePath ? (
                    <img 
                      src={banner.imagePath.startsWith('http') || banner.imagePath.startsWith('blob:') ? banner.imagePath : `${process.env.NEXT_PUBLIC_API_URL ?? ''}${banner.imagePath.startsWith('/') ? banner.imagePath : `/${banner.imagePath}`}`} 
                      alt={banner.title} 
                      className="object-cover w-full h-full"
                    />
                  ) : (
                    <div className="text-xs text-muted-foreground font-mono">No Image Uploaded</div>
                  )}
                  <span className="absolute top-2 left-2 bg-primary text-primary-foreground text-[10px] px-2 py-0.5 rounded font-semibold">
                    {banner.chipLabel}
                  </span>
                </div>
                <CardHeader className="p-4 pb-2">
                  <CardTitle className="text-base text-foreground font-bold">{banner.title}</CardTitle>
                  <CardDescription className="text-xs text-muted-foreground mt-1">{banner.subtitle}</CardDescription>
                </CardHeader>
                <CardFooter className="p-4 pt-2 flex justify-between border-t border-border/40 mt-auto">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={() => handleOpenEdit(banner)}
                    className="text-muted-foreground hover:text-foreground hover:bg-muted gap-1.5"
                  >
                    <Edit2 className="h-4 w-4" /> Edit
                  </Button>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={() => {
                      setConfirmDeleteId(banner._id!);
                      setDeleteOpen(true);
                    }}
                    className="text-red-400 hover:text-red-300 hover:bg-red-500/10 gap-1.5"
                  >
                    <Trash2 className="h-4 w-4" /> Delete
                  </Button>
                </CardFooter>
              </Card>
            ))
          )}
        </div>
      )}

      {/* Add / Edit Banner Dialog */}
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-md bg-popover border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold">{editingBanner ? 'Edit Banner' : 'Add Promotion Banner'}</DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Fill in the header texts, badge, and select a promotional banner image to display.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Image Upload Box */}
            <ImageUpload 
              filePreview={filePreview}
              onFileChange={(file) => {
                setSelectedFile(file);
                setFilePreview(URL.createObjectURL(file));
              }}
              label="Banner Image *"
              description="PNG, JPG, WEBP. Max 10MB."
              fallbackText="PREVIEW"
              aspectRatio="video"
            />

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground">Badge/Chip Label *</label>
              <Input 
                placeholder="e.g. 50% OFF, LIMITED OFFER, NEW ARRIVAL" 
                value={chipLabel} 
                onChange={(e) => setChipLabel(e.target.value)} 
                required
                className="bg-input border-border text-foreground focus:border-primary"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground">Main Title *</label>
              <Input 
                placeholder="e.g. Healthy Eating Revolution" 
                value={title} 
                onChange={(e) => setTitle(e.target.value)} 
                required
                className="bg-input border-border text-foreground focus:border-primary"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground">Subtitle / Description *</label>
              <Input 
                placeholder="e.g. Save 50% on all subscription meals today only" 
                value={subtitle} 
                onChange={(e) => setSubtitle(e.target.value)} 
                required
                className="bg-input border-border text-foreground focus:border-primary"
              />
            </div>

            <DialogFooter className="pt-2 border-t border-border">
              <Button type="button" variant="ghost" onClick={() => setIsOpen(false)} className="text-muted-foreground hover:text-foreground">
                Cancel
              </Button>
              <Button type="submit" className="bg-primary hover:bg-primary/90 text-primary-foreground">
                {editingBanner ? 'Save Changes' : 'Create Banner'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog 
        isOpen={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Banner"
        description="Are you sure you want to delete this promotional banner? This cannot be undone."
        onConfirm={handleConfirmDelete}
        variant="destructive"
      />
    </div>
  );
}
