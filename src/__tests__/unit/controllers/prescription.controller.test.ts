import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Doctor from '../../../models/Doctor';
import Appointment from '../../../models/Appointment';
import Prescription from '../../../models/Prescription';
import { authService } from '../../../services/auth.service';

describe('Prescription Controller Tests', () => {
  let patientToken: string;
  let adminToken: string;
  let unauthorizedToken: string;
  let appointmentId: string;
  let patientId: string;
  let doctorId: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await Prescription.deleteMany({});

    // Create patient
    const patientUser = await authService.signup('Patient User', 'patient@example.com', 'Password123!', '+19998887777');
    patientToken = patientUser.accessToken;
    patientId = patientUser.user.id;

    // Create admin
    const adminUser = await authService.signup('Admin User', 'admin@example.com', 'Password123!', '+19998887778');
    // Set admin role manually
    await User.findByIdAndUpdate(adminUser.user.id, { role: 'admin' });
    const tokens = authService.generateTokens(adminUser.user.id, 'admin');
    adminToken = tokens.accessToken;

    // Create unauthorized user
    const unauthorizedUser = await authService.signup('Other User', 'other@example.com', 'Password123!', '+19998887779');
    unauthorizedToken = unauthorizedUser.accessToken;

    // Create doctor
    const doctor = await Doctor.create({
      name: 'Dr. Test Doctor',
      specialty: 'Cardiologist',
      qualification: 'MBBS, MD',
      experience: 10,
      consultationFee: 500,
      clinicName: 'Cardio Clinic',
      address: 'Test Street 1',
      city: 'Hyderabad',
      isActive: true,
    });
    doctorId = doctor._id.toString();

    // Create appointment
    const appointment = await Appointment.create({
      userId: patientId,
      doctorId: doctor._id,
      appointmentDate: new Date(),
      timeSlot: '10:00 AM',
      type: 'in-person',
      status: 'confirmed',
      consultationFee: 500,
      isPaid: true,
    });
    appointmentId = appointment._id.toString();
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await Prescription.deleteMany({});
  });

  describe('POST /api/v1/prescriptions', () => {
    it('should reject prescription creation from a patient user', async () => {
      const res = await request(app)
        .post('/api/v1/prescriptions')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          appointmentId,
          doctorNotes: 'Take rest',
          medications: [{ name: 'Paracetamol', dosage: '500mg', frequency: 'twice daily', duration: '3 days' }]
        });

      expect(res.status).toBe(403);
    });

    it('should successfully create a prescription from an admin/provider', async () => {
      const res = await request(app)
        .post('/api/v1/prescriptions')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          appointmentId,
          doctorNotes: 'Take rest',
          medications: [{ name: 'Paracetamol', dosage: '500mg', frequency: 'twice daily', duration: '3 days' }]
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.doctorNotes).toBe('Take rest');
      expect(res.body.data.medications.length).toBe(1);
    });
  });

  describe('GET /api/v1/prescriptions/:appointmentId', () => {
    it('should retrieve prescription details for the authorized patient', async () => {
      const res = await request(app)
        .get(`/api/v1/prescriptions/${appointmentId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.doctorNotes).toBe('Take rest');
      expect(res.body.data.medications.length).toBe(1);
    });

    it('should reject prescription access for unauthorized user', async () => {
      const res = await request(app)
        .get(`/api/v1/prescriptions/${appointmentId}`)
        .set('Authorization', `Bearer ${unauthorizedToken}`);

      expect(res.status).toBe(403);
    });
  });
});
