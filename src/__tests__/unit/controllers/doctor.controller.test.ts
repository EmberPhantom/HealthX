import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Doctor from '../../../models/Doctor';
import { authService } from '../../../services/auth.service';

describe('Doctor Controller Tests', () => {
  let accessToken: string;
  let doctorId: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});

    const user = await authService.signup('Doctor Test User', 'doctor.test@example.com', 'Password123!', '+19999999999');
    accessToken = user.accessToken;

    // Create a test doctor
    const doctor = await Doctor.create({
      name: 'Dr. Test',
      specialty: 'General Physician',
      qualification: 'MBBS, MD',
      experience: 10,
      consultationFee: 500,
      rating: 4.5,
      reviewCount: 100,
      clinicName: 'Test Clinic',
      address: 'Test Address',
      city: 'Hyderabad',
      languages: ['English', 'Hindi'],
      availableSlots: [
        { day: 'Monday', times: ['09:00 AM', '10:00 AM', '11:00 AM'] },
        { day: 'Tuesday', times: ['09:00 AM', '10:00 AM'] },
      ],
      isActive: true,
    });
    doctorId = doctor._id.toString();
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
  });

  describe('GET /api/v1/doctors', () => {
    it('should list all doctors', async () => {
      const res = await request(app).get('/api/v1/doctors');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should filter doctors by specialty', async () => {
      const res = await request(app)
        .get('/api/v1/doctors')
        .query({ specialty: 'General Physician' });

      expect(res.status).toBe(200);
      expect(res.body.data.every((d: any) => d.specialty === 'General Physician')).toBe(true);
    });

    it('should return empty array for non-existent specialty', async () => {
      const res = await request(app)
        .get('/api/v1/doctors')
        .query({ specialty: 'NonexistentSpecialty' });

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  describe('GET /api/v1/doctors/:id', () => {
    it('should get doctor by id', async () => {
      const res = await request(app).get(`/api/v1/doctors/${doctorId}`);

      expect(res.status).toBe(200);
      expect(res.body.data.name).toBe('Dr. Test');
      expect(res.body.data.specialty).toBe('General Physician');
    });

    it('should return 404 for non-existent doctor', async () => {
      const res = await request(app).get('/api/v1/doctors/507f1f77bcf86cd799439999');

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/v1/doctors/:id/slots', () => {
    it('should get available slots for a doctor', async () => {
      const monday = new Date('2026-06-08'); // Monday
      const res = await request(app)
        .get(`/api/v1/doctors/${doctorId}/slots`)
        .set('Authorization', `Bearer ${accessToken}`)
        .query({ date: monday.toISOString() });

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data).toEqual(['09:00 AM', '10:00 AM', '11:00 AM']);
    });

    it('should return 400 when date is missing', async () => {
      const res = await request(app)
        .get(`/api/v1/doctors/${doctorId}/slots`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(400);
    });

    it('should return empty array for a day with no slots', async () => {
      const wednesday = new Date('2026-06-10'); // Wednesday
      const res = await request(app)
        .get(`/api/v1/doctors/${doctorId}/slots`)
        .set('Authorization', `Bearer ${accessToken}`)
        .query({ date: wednesday.toISOString() });

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });
});
