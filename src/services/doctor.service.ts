import Doctor, { IDoctor } from '../models/Doctor';
import logger from '../utils/logger';

export class DoctorService {
  async getDoctors(query: { specialty?: string; city?: string }): Promise<IDoctor[]> {
    const filter: any = { isActive: true };
    if (query.specialty) {
      filter.specialty = query.specialty;
    }
    if (query.city) {
      filter.city = new RegExp(query.city, 'i');
    }

    let doctors = await Doctor.find(filter);

    // If there are fewer than 10 doctors, re-seed with a complete list for all specialties
    if (doctors.length < 10 && Object.keys(query).length === 0) {
      logger.info('Seeding/Upgrading complete doctor list...');
      await Doctor.deleteMany({});

      const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const standardSlots1 = ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM'];
      const standardSlots2 = ['09:30 AM', '10:30 AM', '11:30 AM', '02:30 PM', '03:30 PM', '04:30 PM'];

      const doctorSpecs = [
        { name: 'Dr. Ramesh Patel', specialty: 'Diabetologist', qual: 'MBBS, MD (Medicine), C.Diab', fee: 800, clinic: 'Patel Diabetes Clinic' },
        { name: 'Dr. Sunita Sharma', specialty: 'Cardiologist', qual: 'MBBS, MD, DM (Cardiology)', fee: 1200, clinic: 'Sharma Heart & Wellness' },
        { name: 'Dr. Amit Verma', specialty: 'General Physician', qual: 'MBBS, MD', fee: 500, clinic: 'FitLife Wellness Center' },
        { name: 'Dr. Priya Rao', specialty: 'Diabetologist', qual: 'MBBS, MD, FCCP (Diabetes)', fee: 700, clinic: 'SugarCare Diabetes Center' },
        { name: 'Dr. Sarah Jenkins', specialty: 'Dermatologist', qual: 'MBBS, MD (Dermatology)', fee: 750, clinic: 'Jenkins Skin Clinic' },
        { name: 'Dr. Alan Turing', specialty: 'Neurologist', qual: 'MBBS, MD, DM (Neurology)', fee: 1500, clinic: 'Turing Brain Center' },
        { name: 'Dr. Howard Stark', specialty: 'Nephrologist', qual: 'MBBS, MD, DM (Nephrology)', fee: 1100, clinic: 'Stark Kidney Care' },
        { name: 'Dr. Gregory House', specialty: 'Consulting Physician', qual: 'MD (Internal Medicine)', fee: 2000, clinic: 'House Diagnostic Center' },
        { name: 'Dr. John Watson', specialty: 'General Physician', qual: 'MBBS, MD', fee: 550, clinic: 'Watson Clinic' },
        { name: 'Dr. Banner Bruce', specialty: 'Endocrinologist', qual: 'MD, PhD (Endocrine)', fee: 1000, clinic: 'Bruce Hormone Institute' },
        { name: 'Dr. Sigmund Freud', specialty: 'Psychiatrist', qual: 'MD, PhD', fee: 1300, clinic: 'Freud Psychiatric Clinic' },
        { name: 'Dr. Mary Campbell', specialty: 'Gynaecologist', qual: 'MBBS, MD, DGO', fee: 900, clinic: 'Campbell Women Care' },
        { name: 'Dr. Stephen Strange', specialty: 'Pulmonologist', qual: 'MD, FCCP', fee: 1200, clinic: 'Strange Lung Clinic' },
        { name: 'Dr. Tony Stark', specialty: 'Gastroenterologist', qual: 'MBBS, MD, DM (Gastro)', fee: 1100, clinic: 'Stark Gastro Clinic' },
        { name: 'Dr. Peter Parker', specialty: 'Orthopedician', qual: 'MBBS, MS (Ortho)', fee: 650, clinic: 'Parker Ortho Care' },
        { name: 'Dr. Clark Kent', specialty: 'Pediatrician', qual: 'MBBS, MD (Pediatrics)', fee: 700, clinic: 'Kent Kids Clinic' },
        { name: 'Dr. Diana Prince', specialty: 'ENT', qual: 'MBBS, MS (ENT)', fee: 800, clinic: 'Prince ENT Clinic' },
        { name: 'Dr. Matt Murdock', specialty: 'Ophthalmologist', qual: 'MBBS, MS (Ophthalmology)', fee: 650, clinic: 'Murdock Eye Center' },
        { name: 'Dr. Charles Xavier', specialty: 'Oncologist', qual: 'MD, PhD (Oncology)', fee: 1800, clinic: 'Xavier Cancer Institute' },
        { name: 'Dr. Reed Richards', specialty: 'Rheumatologist', qual: 'MD, DM (Rheumatology)', fee: 1200, clinic: 'Richards Arthritis Center' }
      ];

      const defaultDoctors = doctorSpecs.map((d, index) => ({
        name: d.name,
        specialty: d.specialty,
        qualification: d.qual,
        experience: 8 + (index % 12),
        consultationFee: d.fee,
        rating: 4.5 + ((index * 7) % 5) * 0.1,
        reviewCount: 50 + ((index * 23) % 300),
        clinicName: d.clinic,
        address: 'Banjara Hills, Road No. ' + (3 + index),
        city: 'Hyderabad',
        languages: index % 2 === 0 ? ['English', 'Hindi', 'Telugu'] : ['English', 'Hindi'],
        availableSlots: daysOfWeek.map(day => ({
          day,
          times: index % 2 === 0 ? standardSlots1 : standardSlots2
        })),
        avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(d.name)}&size=200&background=${index % 2 === 0 ? '10B981' : '3B82F6'}&color=fff`,
        isActive: true
      }));

      doctors = await Doctor.insertMany(defaultDoctors);
      logger.info(`Successfully seeded ${doctors.length} doctors.`);
    }

    return doctors;
  }

  async getDoctorById(id: string): Promise<IDoctor | null> {
    return Doctor.findById(id);
  }

  async getSpecialties(): Promise<string[]> {
    const doctors = await this.getDoctors({});
    return Array.from(new Set(doctors.map((d) => d.specialty)));
  }
}

export const doctorService = new DoctorService();
