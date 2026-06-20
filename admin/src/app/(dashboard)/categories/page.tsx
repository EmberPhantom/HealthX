"use client";

import React, { useEffect, useState } from 'react';
import { useCategories } from '@/hooks/useCategories';
import { toast } from 'sonner';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';

import { Category } from '@/types/models';
import { PageHeader } from '@/components/shared/PageHeader';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function CategoriesPage() {
  const {
    categories,
    loading,
    fetchCategories,
    createCategory,
    updateCategory,
    deleteCategory,
  } = useCategories();

  const [isOpen, setIsOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  // Form States
  const [name, setName] = useState('');
  const [emoji, setEmoji] = useState('🥗');

  // Delete State
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  const handleOpenAdd = () => {
    setEditingCategory(null);
    setName('');
    setEmoji('🥗');
    setIsOpen(true);
  };

  const handleOpenEdit = (category: Category) => {
    setEditingCategory(category);
    setName(category.name);
    setEmoji(category.emoji);
    setIsOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (confirmDeleteId) {
      await deleteCategory(confirmDeleteId);
      setConfirmDeleteId(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) {
      toast.error('Category name is required');
      return;
    }

    const payload = { name, emoji };

    try {
      if (editingCategory && editingCategory._id) {
        await updateCategory(editingCategory._id, payload);
        toast.success('Category updated successfully');
      } else {
        await createCategory(payload);
        toast.success('Category created successfully');
      }
      fetchCategories();
      setIsOpen(false);
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong');
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <PageHeader 
        title="Categories"
        description="Manage categories used in the shop and meal planners."
        action={
          <Button onClick={handleOpenAdd} className="bg-primary hover:bg-primary/90 text-primary-foreground flex items-center gap-2">
            <Plus className="h-4 w-4" /> Add Category
          </Button>
        }
      />

      {loading ? (
        <LoadingSkeleton variant="table" count={3} />
      ) : (
        <Card className="bg-card border-border overflow-hidden">
          <Table>
            <TableHeader className="border-border">
              <TableRow className="hover:bg-transparent border-border">
                <TableHead className="text-muted-foreground w-[80px]">Emoji</TableHead>
                <TableHead className="text-muted-foreground">Name</TableHead>
                <TableHead className="text-muted-foreground text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {categories.length === 0 ? (
                <EmptyState colSpan={3} message="No categories found. Click 'Add Category' to create one." />
              ) : (
                categories.map(category => (
                  <TableRow key={category._id} className="hover:bg-muted/10 border-border">
                    <TableCell className="text-2xl">{category.emoji}</TableCell>
                    <TableCell className="font-semibold text-foreground">{category.name}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button 
                          variant="ghost" 
                          size="icon" 
                          onClick={() => handleOpenEdit(category)}
                          className="h-8 w-8 text-muted-foreground hover:text-foreground hover:bg-muted"
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                        <Button 
                          variant="ghost" 
                          size="icon" 
                          onClick={() => {
                            setConfirmDeleteId(category._id!);
                            setDeleteOpen(true);
                          }}
                          className="h-8 w-8 text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </Card>
      )}

      {/* Add / Edit Category Dialog */}
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-md bg-popover border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold">{editingCategory ? 'Edit Category' : 'Add New Category'}</DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Provide a name and an emoji representational icon.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground">Category Name *</label>
              <Input 
                placeholder="e.g. Salads, Smoothies, Keto" 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                required
                className="bg-input border-border text-foreground focus:border-primary"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground">Emoji representation</label>
              <Input 
                placeholder="e.g. 🥗" 
                value={emoji} 
                onChange={(e) => setEmoji(e.target.value)} 
                className="bg-input border-border text-foreground focus:border-primary"
              />
            </div>

            <DialogFooter className="pt-2 border-t border-border">
              <Button type="button" variant="ghost" onClick={() => setIsOpen(false)} className="text-muted-foreground hover:text-foreground">
                Cancel
              </Button>
              <Button type="submit" className="bg-primary hover:bg-primary/90 text-primary-foreground">
                Save Category
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog 
        isOpen={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Category"
        description="Are you sure you want to delete this category? This cannot be undone."
        onConfirm={handleConfirmDelete}
        variant="destructive"
      />
    </div>
  );
}
