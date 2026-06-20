"use client";

import React, { useEffect, useState } from 'react';
import { useDoctors } from '@/hooks/useDoctors';
import { toast } from 'sonner';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Switch } from '@/components/ui/switch';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';

import { Doctor, Slot } from '@/types/models';
import { DEFAULT_DAYS, DEFAULT_TIMES } from '@/constants/defaults';
import { PageHeader } from '@/components/shared/PageHeader';
import { SearchBar } from '@/components/shared/SearchBar';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { ImageUpload } from '@/components/shared/ImageUpload';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { EmptyState } from '@/components/shared/EmptyState';

export default function DoctorsPage() {
  const {
    doctors,
    loading,
    fetchDoctors,
    createDoctor,
    updateDoctor,
    toggleActive,
    deleteDoctor,
    uploadAvatar,
  } = useDoctors();

  const [search, setSearch] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [editingDoctor, setEditingDoctor] = useState<Doctor | null>(null);
  
  // Form States
  const [name, setName] = useState('');
  const [specialty, setSpecialty] = useState('');
  const [qualification, setQualification] = useState('');
  const [experience, setExperience] = useState(5);
  const [consultationFee, setConsultationFee] = useState(500);
  const [clinicName, setClinicName] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');
  const [languagesStr, setLanguagesStr] = useState('English, Hindi');
  const [slots, setSlots] = useState<{ [day: string]: string }>({});
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState<string>('');

  // Delete State
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  useEffect(() => {
    fetchDoctors();
  }, [fetchDoctors]);

  const handleOpenAdd = () => {
    setEditingDoctor(null);
    setName('');
    setSpecialty('');
    setQualification('');
    setExperience(5);
    setConsultationFee(500);
    setClinicName('');
    setAddress('');
    setCity('');
    setLanguagesStr('English, Hindi');
    
    // Set default slots
    const initialSlots: { [day: string]: string } = {};
    DEFAULT_DAYS.forEach(day => {
      initialSlots[day] = DEFAULT_TIMES.join(', ');
    });
    setSlots(initialSlots);
    setSelectedFile(null);
    setFilePreview('');
    setIsOpen(true);
  };

  const handleOpenEdit = (doctor: Doctor) => {
    setEditingDoctor(doctor);
    setName(doctor.name);
    setSpecialty(doctor.specialty);
    setQualification(doctor.qualification);
    setExperience(doctor.experience);
    setConsultationFee(doctor.consultationFee);
    setClinicName(doctor.clinicName);
    setAddress(doctor.address);
    setCity(doctor.city);
    setLanguagesStr(doctor.languages.join(', '));

    // Hydrate slots
    const populatedSlots: { [day: string]: string } = {};
    DEFAULT_DAYS.forEach(day => {
      const match = doctor.availableSlots.find(s => s.day.toLowerCase() === day.toLowerCase());
      populatedSlots[day] = match ? match.times.join(', ') : '';
    });
    setSlots(populatedSlots);
    setSelectedFile(null);
    setFilePreview(doctor.avatarUrl || '');
    setIsOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (confirmDeleteId) {
      await deleteDoctor(confirmDeleteId);
      setConfirmDeleteId(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !specialty || !qualification || !clinicName || !city || !address) {
      toast.error('Please fill in all required fields');
      return;
    }

    const availableSlots: Slot[] = Object.keys(slots).map(day => ({
      day,
      times: slots[day].split(',').map(t => t.trim()).filter(Boolean)
    }));

    const doctorData = {
      name,
      specialty,
      qualification,
      experience: Number(experience),
      consultationFee: Number(consultationFee),
      clinicName,
      address,
      city,
      languages: languagesStr.split(',').map(l => l.trim()).filter(Boolean),
      availableSlots,
      isActive: editingDoctor ? editingDoctor.isActive : true,
    };

    try {
      let savedDoctor: any;
      if (editingDoctor && editingDoctor._id) {
        savedDoctor = await updateDoctor(editingDoctor._id, doctorData);
        toast.success('Doctor updated successfully');
      } else {
        savedDoctor = await createDoctor(doctorData);
        toast.success('Doctor created successfully');
      }

      // If a file is selected, upload it
      if (selectedFile && savedDoctor._id) {
        await uploadAvatar(savedDoctor._id, selectedFile);
      }

      // Refresh list
      fetchDoctors();
      setIsOpen(false);
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong');
    }
  };

  const filteredDoctors = doctors.filter(d => 
    d.name.toLowerCase().includes(search.toLowerCase()) ||
    d.specialty.toLowerCase().includes(search.toLowerCase()) ||
    d.city.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Doctors Directory"
        description="Manage registered doctors, consultation details, and schedules."
        action={
          <Button onClick={handleOpenAdd} className="bg-primary hover:bg-primary/90 text-primary-foreground flex items-center gap-2">
            <Plus className="h-4 w-4" /> Add Doctor
          </Button>
        }
      />

      <SearchBar 
        value={search}
        onChange={setSearch}
        placeholder="Search doctors by name, specialty, city..."
      />

      {loading ? (
        <LoadingSkeleton variant="table" count={3} />
      ) : (
        <Card className="bg-card border-border overflow-hidden">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader className="border-border">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="text-muted-foreground w-[80px]">Avatar</TableHead>
                  <TableHead className="text-muted-foreground">Name</TableHead>
                  <TableHead className="text-muted-foreground">Specialty</TableHead>
                  <TableHead className="text-muted-foreground">Clinic / Location</TableHead>
                  <TableHead className="text-muted-foreground">Fee</TableHead>
                  <TableHead className="text-muted-foreground">Status</TableHead>
                  <TableHead className="text-muted-foreground text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredDoctors.length === 0 ? (
                  <EmptyState colSpan={7} message="No doctors found. Click 'Add Doctor' to create one." />
                ) : (
                  filteredDoctors.map(doctor => (
                    <TableRow key={doctor._id} className="hover:bg-muted/10 border-border">
                      <TableCell>
                        <Avatar className="h-10 w-10 border border-border bg-muted">
                          <AvatarImage 
                            src={doctor.avatarUrl ? (doctor.avatarUrl.startsWith('http') || doctor.avatarUrl.startsWith('blob:') ? doctor.avatarUrl : `${process.env.NEXT_PUBLIC_API_URL ?? ''}${doctor.avatarUrl.startsWith('/') ? doctor.avatarUrl : `/${doctor.avatarUrl}`}`) : ''} 
                            alt={doctor.name} 
                            className="object-cover"
                          />
                          <AvatarFallback className="bg-muted text-muted-foreground text-xs font-bold">
                            {doctor.name.replace('Dr. ', '').substring(0, 2).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                      </TableCell>
                      <TableCell className="font-semibold text-foreground">
                        {doctor.name}
                        <div className="text-[11px] text-muted-foreground font-normal mt-0.5">{doctor.qualification} • {doctor.experience} Yrs Exp</div>
                      </TableCell>
                      <TableCell className="text-foreground">{doctor.specialty}</TableCell>
                      <TableCell className="text-sm">
                        <div className="text-foreground font-medium">{doctor.clinicName}</div>
                        <div className="text-[11px] text-muted-foreground">{doctor.city}</div>
                      </TableCell>
                      <TableCell className="font-semibold text-foreground">₹{doctor.consultationFee}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Switch 
                            checked={doctor.isActive} 
                            onCheckedChange={() => toggleActive(doctor._id!)}
                            className="data-[state=checked]:bg-primary data-[state=unchecked]:bg-muted"
                          />
                          <span className={`text-xs ${doctor.isActive ? 'text-emerald-600 dark:text-emerald-400 font-semibold' : 'text-muted-foreground'}`}>
                            {doctor.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            onClick={() => handleOpenEdit(doctor)}
                            className="h-8 w-8 text-muted-foreground hover:text-foreground hover:bg-muted"
                          >
                            <Edit2 className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            onClick={() => {
                              setConfirmDeleteId(doctor._id!);
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

      {/* Add / Edit Doctor Dialog */}
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-2xl bg-popover border-border text-foreground max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold">{editingDoctor ? 'Edit Doctor' : 'Add New Doctor'}</DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Provide the professional profile details, available time slots, and upload an avatar.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Avatar Selection */}
            <ImageUpload 
              filePreview={filePreview}
              onFileChange={(file) => {
                setSelectedFile(file);
                setFilePreview(URL.createObjectURL(file));
              }}
              label="Doctor Photograph"
              description="Supported formats: JPG, PNG, WEBP. Max size: 2MB."
              fallbackText="Dr"
              aspectRatio="circle"
            />

            {/* General Info Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Doctor Name *</label>
                <Input 
                  placeholder="e.g. Dr. John Doe" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Specialty *</label>
                <Input 
                  placeholder="e.g. Diabetologist, Cardiologist" 
                  value={specialty} 
                  onChange={(e) => setSpecialty(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Qualification *</label>
                <Input 
                  placeholder="e.g. MBBS, MD" 
                  value={qualification} 
                  onChange={(e) => setQualification(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-muted-foreground">Experience (Yrs) *</label>
                  <Input 
                    type="number" 
                    value={experience} 
                    onChange={(e) => setExperience(Number(e.target.value))} 
                    required
                    min={0}
                    className="bg-input border-border text-foreground focus:border-primary"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-muted-foreground">Consultation Fee (₹) *</label>
                  <Input 
                    type="number" 
                    value={consultationFee} 
                    onChange={(e) => setConsultationFee(Number(e.target.value))} 
                    required
                    min={0}
                    className="bg-input border-border text-foreground focus:border-primary"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Clinic Name *</label>
                <Input 
                  placeholder="e.g. Care Hospital" 
                  value={clinicName} 
                  onChange={(e) => setClinicName(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">City *</label>
                <Input 
                  placeholder="e.g. Hyderabad" 
                  value={city} 
                  onChange={(e) => setCity(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5 md:col-span-2">
                <label className="text-xs font-semibold text-muted-foreground">Full Address *</label>
                <Input 
                  placeholder="Street, Landmark, Area..." 
                  value={address} 
                  onChange={(e) => setAddress(e.target.value)} 
                  required
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>

              <div className="space-y-1.5 md:col-span-2">
                <label className="text-xs font-semibold text-muted-foreground">Languages Spoken (comma separated)</label>
                <Input 
                  placeholder="English, Hindi, Telugu" 
                  value={languagesStr} 
                  onChange={(e) => setLanguagesStr(e.target.value)} 
                  className="bg-input border-border text-foreground focus:border-primary"
                />
              </div>
            </div>

            {/* Time Slots Area */}
            <div className="space-y-3 pt-2 border-t border-border/50">
              <div>
                <h3 className="text-sm font-semibold">Available Consultation Slots</h3>
                <p className="text-xs text-muted-foreground">Separate times with a comma, e.g. 09:00 AM, 11:30 AM, 04:00 PM</p>
              </div>
              <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
                {DEFAULT_DAYS.map(day => (
                  <div key={day} className="flex gap-4 items-center">
                    <span className="text-xs font-semibold w-24 text-muted-foreground">{day}</span>
                    <Input 
                      placeholder="No slots scheduled"
                      value={slots[day] || ''}
                      onChange={(e) => setSlots({ ...slots, [day]: e.target.value })}
                      className="bg-input border-border text-xs text-foreground focus:border-primary"
                    />
                  </div>
                ))}
              </div>
            </div>

            <DialogFooter className="pt-2 border-t border-border">
              <Button type="button" variant="ghost" onClick={() => setIsOpen(false)} className="text-muted-foreground hover:text-foreground">
                Cancel
              </Button>
              <Button type="submit" className="bg-primary hover:bg-primary/90 text-primary-foreground">
                Save Doctor
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog 
        isOpen={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Doctor Profile"
        description="Are you sure you want to delete this doctor? This cannot be undone."
        onConfirm={handleConfirmDelete}
        variant="destructive"
      />
    </div>
  );
}
