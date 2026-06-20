"use client";

import React, { useEffect, useState } from 'react';
import { useMenuItems } from '@/hooks/useMenuItems';
import { toast } from 'sonner';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';

import { MenuItem } from '@/types/models';
import { PageHeader } from '@/components/shared/PageHeader';
import { SearchBar } from '@/components/shared/SearchBar';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { ImageUpload } from '@/components/shared/ImageUpload';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function MenuItemsPage() {
  const {
    items,
    categories,
    loading,
    fetchItemsAndCategories,
    createMenuItem,
    updateMenuItem,
    deleteMenuItem,
    uploadImage,
  } = useMenuItems();

  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('ALL');
  const [typeFilter, setTypeFilter] = useState('ALL');
  const [isOpen, setIsOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null);

  // Form States
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState(0);
  const [calories, setCalories] = useState(0);
  const [emoji, setEmoji] = useState('🥗');
  const [category, setCategory] = useState('');
  const [type, setType] = useState<'Regular' | 'ReadyToEat'>('Regular');
  const [tagsStr, setTagsStr] = useState('');
  const [isVeg, setIsVeg] = useState(true);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState('');

  // Delete State
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  useEffect(() => {
    fetchItemsAndCategories();
  }, [fetchItemsAndCategories]);

  const handleOpenAdd = () => {
    setEditingItem(null);
    setName('');
    setDescription('');
    setPrice(150);
    setCalories(350);
    setEmoji('🥗');
    setCategory(categories[0]?.name || 'Salads');
    setType('Regular');
    setTagsStr('');
    setIsVeg(true);
    setSelectedFile(null);
    setFilePreview('');
    setIsOpen(true);
  };

  const handleOpenEdit = (item: MenuItem) => {
    setEditingItem(item);
    setName(item.name);
    setDescription(item.description);
    setPrice(item.price);
    setCalories(item.calories);
    setEmoji(item.emoji);
    setCategory(item.category);
    setType(item.type);
    setTagsStr(item.tags.join(', '));
    setIsVeg(item.isVeg);
    setSelectedFile(null);
    setFilePreview(item.imageUrl || '');
    setIsOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (confirmDeleteId) {
      await deleteMenuItem(confirmDeleteId);
      setConfirmDeleteId(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !description || !category) {
      toast.error('Please fill in all required fields');
      return;
    }

    const payload = {
      name,
      description,
      price: Number(price),
      calories: Number(calories),
      emoji,
      category,
      type,
      tags: tagsStr.split(',').map(t => t.trim()).filter(Boolean),
      isVeg,
    };

    try {
      let savedItem: any;
      if (editingItem && editingItem._id) {
        savedItem = await updateMenuItem(editingItem._id, payload);
        toast.success('Item updated successfully');
      } else {
        savedItem = await createMenuItem(payload);
        toast.success('Item created successfully');
      }

      // Upload image if selected
      if (selectedFile && savedItem._id) {
        await uploadImage(savedItem._id, selectedFile);
      }

      fetchItemsAndCategories();
      setIsOpen(false);
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong');
    }
  };

  const filteredItems = items.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(search.toLowerCase()) || 
                          item.description.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'ALL' || item.category === categoryFilter;
    const matchesType = typeFilter === 'ALL' || item.type === typeFilter;
    return matchesSearch && matchesCategory && matchesType;
  });

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Shop & Menu Items"
        description="Manage products, nutrition info, and prices for the HealthX Shop."
        action={
          <Button onClick={handleOpenAdd} className="bg-primary hover:bg-primary/90 text-primary-foreground flex items-center gap-2">
            <Plus className="h-4 w-4" /> Add Item
          </Button>
        }
      />

      {/* Filters & Search Row */}
      <div className="flex flex-wrap items-center gap-3">
        <SearchBar 
          value={search}
          onChange={setSearch}
          placeholder="Search items..."
        />

        <Select value={categoryFilter} onValueChange={(val) => setCategoryFilter(val || 'ALL')}>
          <SelectTrigger className="w-[180px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Category" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Categories</SelectItem>
            {categories.map(cat => (
              <SelectItem key={cat._id} value={cat.name}>{cat.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={typeFilter} onValueChange={(val) => setTypeFilter(val || 'ALL')}>
          <SelectTrigger className="w-[180px] bg-card border-border text-foreground focus:border-primary">
            <SelectValue placeholder="Type" />
          </SelectTrigger>
          <SelectContent className="bg-popover border-border text-foreground">
            <SelectItem value="ALL">All Types</SelectItem>
            <SelectItem value="Regular">Regular</SelectItem>
            <SelectItem value="ReadyToEat">ReadyToEat</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {loading ? (
        <LoadingSkeleton variant="table" count={3} />
      ) : (
        <Card className="bg-card border-border overflow-hidden">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader className="border-border">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="text-muted-foreground w-[80px]">Image</TableHead>
                  <TableHead className="text-muted-foreground">Name</TableHead>
                  <TableHead className="text-muted-foreground">Category</TableHead>
                  <TableHead className="text-muted-foreground">Type</TableHead>
                  <TableHead className="text-muted-foreground">Nutrition</TableHead>
                  <TableHead className="text-muted-foreground">Price</TableHead>
                  <TableHead className="text-muted-foreground">Diet</TableHead>
                  <TableHead className="text-muted-foreground text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredItems.length === 0 ? (
                  <EmptyState colSpan={8} message="No shop items found. Click 'Add Item' to add a new product." />
                ) : (
                  filteredItems.map(item => (
                    <TableRow key={item._id} className="hover:bg-muted/10 border-border">
                      <TableCell>
                        <Avatar className="h-10 w-10 border border-border rounded-md bg-muted">
                          <AvatarImage 
                            src={item.imageUrl ? (item.imageUrl.startsWith('http') || item.imageUrl.startsWith('blob:') ? item.imageUrl : `${process.env.NEXT_PUBLIC_API_URL ?? ''}${item.imageUrl.startsWith('/') ? item.imageUrl : `/${item.imageUrl}`}`) : ''} 
                            alt={item.name} 
                            className="object-cover"
                          />
                          <AvatarFallback className="bg-primary/10 text-xl">
                            {item.emoji}
                          </AvatarFallback>
                        </Avatar>
                      </TableCell>
                      <TableCell className="font-semibold text-foreground">
                        <span className="mr-1">{item.emoji}</span> {item.name}
                        <div className="text-[11px] text-muted-foreground font-normal max-w-xs truncate mt-0.5">{item.description}</div>
                      </TableCell>
                      <TableCell className="text-foreground">{item.category}</TableCell>
                      <TableCell>
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${item.type === 'ReadyToEat' ? 'bg-amber-50 text-amber-700 border border-amber-100' : 'bg-blue-50 text-blue-700 border border-blue-100'}`}>
                          {item.type}
                        </span>
                      </TableCell>
                      <TableCell className="text-sm text-foreground">{item.calories} kcal</TableCell>
                      <TableCell className="font-bold text-foreground">₹{item.price}</TableCell>
                      <TableCell>
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${item.isVeg ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-red-50 text-red-700 border border-red-100'}`}>
                          {item.isVeg ? 'Veg' : 'Non-Veg'}
                        </span>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            onClick={() => handleOpenEdit(item)}
                            className="h-8 w-8 text-muted-foreground hover:text-foreground hover:bg-muted"
                          >
                            <Edit2 className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            onClick={() => {
                              setConfirmDeleteId(item._id!);
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
          </div>
        </Card>
      )}

      {/* Add / Edit Item Dialog */}
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-xl bg-popover border-border text-foreground max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold">{editingItem ? 'Edit Shop Item' : 'Add New Shop Item'}</DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Provide product details, pricing, nutritional value, and picture.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Image Selection */}
            <ImageUpload 
              filePreview={filePreview}
              onFileChange={(file) => {
                setSelectedFile(file);
                setFilePreview(URL.createObjectURL(file));
              }}
              label="Product Image"
              description="Formats: JPG, PNG, WEBP. Max size: 5MB."
              fallbackEmoji={emoji}
              aspectRatio="square"
            />

            {/* Inputs */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Product Name *</label>
                <Input 
                  placeholder="e.g. Quinoa Salad" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Emoji (for backup icon)</label>
                <Input 
                  placeholder="e.g. 🥗, 🍎, 🥤" 
                  value={emoji} 
                  onChange={(e) => setEmoji(e.target.value)} 
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5 md:col-span-2">
                <label className="text-xs font-semibold text-muted-foreground">Description *</label>
                <Input 
                  placeholder="Tell clients about this food item..." 
                  value={description} 
                  onChange={(e) => setDescription(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Category *</label>
                <Select value={category} onValueChange={(val) => setCategory(val || '')}>
                  <SelectTrigger className="bg-input border-border text-foreground">
                    <SelectValue placeholder="Select Category" />
                  </SelectTrigger>
                  <SelectContent className="bg-popover border-border text-foreground">
                    {categories.map(cat => (
                      <SelectItem key={cat._id} value={cat.name}>{cat.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Product Type *</label>
                <Select value={type} onValueChange={(val: any) => setType(val || 'Regular')}>
                  <SelectTrigger className="bg-input border-border text-foreground">
                    <SelectValue placeholder="Select Type" />
                  </SelectTrigger>
                  <SelectContent className="bg-popover border-border text-foreground">
                    <SelectItem value="Regular">Regular</SelectItem>
                    <SelectItem value="ReadyToEat">ReadyToEat</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-muted-foreground">Price (₹) *</label>
                  <Input 
                    type="number" 
                    value={price} 
                    onChange={(e) => setPrice(Number(e.target.value))} 
                    required
                    min={0}
                    className="bg-input border-border text-foreground focus:border-primary"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-muted-foreground">Calories (kcal) *</label>
                  <Input 
                    type="number" 
                    value={calories} 
                    onChange={(e) => setCalories(Number(e.target.value))} 
                    required
                    min={0}
                    className="bg-input border-border text-foreground focus:border-primary"
                  />
                </div>
              </div>

              <div className="flex items-center justify-between p-3 bg-secondary/50 rounded-md border border-border mt-3.5 col-span-1 md:col-span-2">
                <div>
                  <p className="text-xs font-semibold">Vegetarian Item</p>
                  <p className="text-[10px] text-muted-foreground">Toggle off for non-vegetarian products</p>
                </div>
                <Switch 
                  checked={isVeg} 
                  onCheckedChange={setIsVeg}
                  className="data-[state=checked]:bg-primary"
                />
              </div>

              <div className="space-y-1.5 md:col-span-2">
                <label className="text-xs font-semibold text-muted-foreground">Tags (comma separated)</label>
                <Input 
                  placeholder="High-Protein, Keto-Friendly, Sugar-Free" 
                  value={tagsStr} 
                  onChange={(e) => setTagsStr(e.target.value)} 
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>
            </div>

            <DialogFooter className="pt-2 border-t border-border">
              <Button type="button" variant="ghost" onClick={() => setIsOpen(false)} className="text-muted-foreground hover:text-foreground">
                Cancel
              </Button>
              <Button type="submit" className="bg-primary hover:bg-primary/90 text-primary-foreground">
                Save Item
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog 
        isOpen={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Menu Item"
        description="Are you sure you want to delete this menu item? This cannot be undone."
        onConfirm={handleConfirmDelete}
        variant="destructive"
      />
    </div>
  );
}
