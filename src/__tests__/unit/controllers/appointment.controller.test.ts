import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Doctor from '../../../models/Doctor';
import Appointment from '../../../models/Appointment';
import Notification from '../../../models/Notification';
import { authService } from '../../../services/auth.service';

describe('Appointment Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;
  let doctorId: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await Notification.deleteMany({});

    const user = await authService.signup('Appt Test User', 'appt.test@example.com', 'Password123!', '+19999999985');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('Appt Other', 'appt.other@example.com', 'Password123!', '+19999999984');
    otherToken = other.accessToken;

    const doctor = await Doctor.create({
      name: 'Dr. Appointment Test',
      specialty: 'General Physician',
      qualification: 'MBBS, MD',
      experience: 10,
      consultationFee: 500,
      rating: 4.5,
      reviewCount: 50,
      clinicName: 'Test Clinic',
      address: 'Test Address',
      city: 'Hyderabad',
      languages: ['English'],
      availableSlots: [{ day: 'Monday', times: ['10:00 AM', '11:00 AM'] }],
      isActive: true,
    });
    doctorId = doctor._id.toString();
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await Notification.deleteMany({});
  });

  describe('POST /api/v1/appointments', () => {
    beforeEach(async () => {
      await Appointment.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should book an appointment successfully', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          doctorId,
          appointmentDate: '2026-06-08',
          timeSlot: '10:00 AM',
          type: 'in-person',
          symptoms: 'Headache',
          notes: 'First visit',
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.doctorId).toBeDefined();
      expect(res.body.data.timeSlot).toBe('10:00 AM');
    });

    it('should return 404 for non-existent doctor', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          doctorId: '507f1f77bcf86cd799439999',
          appointmentDate: '2026-06-08',
          timeSlot: '10:00 AM',
        });

      expect(res.status).toBe(404);
    });

    it('should reject missing required fields', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ doctorId });

      expect(res.status).toBe(400);
    });

    it('should reject invalid appointment type', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          doctorId,
          appointmentDate: '2026-06-08',
          timeSlot: '10:00 AM',
          type: 'invalid',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/appointments', () => {
    beforeEach(async () => {
      await Appointment.deleteMany({});
    });

    it('should return user appointments', async () => {
      await Appointment.create({
        userId,
        doctorId,
        appointmentDate: new Date('2026-06-08'),
        timeSlot: '10:00 AM',
        type: 'in-person',
        consultationFee: 500,
        isPaid: false,
      });

      const res = await request(app)
        .get('/api/v1/appointments')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
    });

    it('should return empty array when no appointments', async () => {
      const res = await request(app)
        .get('/api/v1/appointments')
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  describe('GET /api/v1/appointments/:id', () => {
    beforeEach(async () => {
      await Appointment.deleteMany({});
    });

    it('should get appointment by id', async () => {
      const appt = await Appointment.create({
        userId,
        doctorId,
        appointmentDate: new Date('2026-06-08'),
        timeSlot: '10:00 AM',
        type: 'in-person',
        consultationFee: 500,
        isPaid: false,
      });

      const res = await request(app)
        .get(`/api/v1/appointments/${appt._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.timeSlot).toBe('10:00 AM');
    });

    it('should return 404 for other user appointment', async () => {
      const appt = await Appointment.create({
        userId,
        doctorId,
        appointmentDate: new Date('2026-06-08'),
        timeSlot: '10:00 AM',
        type: 'in-person',
        consultationFee: 500,
        isPaid: false,
      });

      const res = await request(app)
        .get(`/api/v1/appointments/${appt._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /api/v1/appointments/:id', () => {
    beforeEach(async () => {
      await Appointment.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should cancel own appointment', async () => {
      const appt = await Appointment.create({
        userId,
        doctorId,
        appointmentDate: new Date('2026-06-08'),
        timeSlot: '10:00 AM',
        type: 'in-person',
        consultationFee: 500,
        isPaid: false,
      });

      const res = await request(app)
        .delete(`/api/v1/appointments/${appt._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('cancelled');
    });

    it('should return 404 for other user appointment', async () => {
      const appt = await Appointment.create({
        userId,
        doctorId,
        appointmentDate: new Date('2026-06-08'),
        timeSlot: '10:00 AM',
        type: 'in-person',
        consultationFee: 500,
        isPaid: false,
      });

      const res = await request(app)
        .delete(`/api/v1/appointments/${appt._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });
});
