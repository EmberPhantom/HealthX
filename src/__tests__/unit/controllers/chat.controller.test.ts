import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Doctor from '../../../models/Doctor';
import Appointment from '../../../models/Appointment';
import ChatMessage from '../../../models/ChatMessage';
import { authService } from '../../../services/auth.service';

describe('Chat Controller Tests', () => {
  let patientToken: string;
  let unauthorizedToken: string;
  let appointmentId: string;
  let patientId: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await ChatMessage.deleteMany({});

    // Create a patient user
    const patientUser = await authService.signup('Patient User', 'patient@example.com', 'Password123!', '+19998887777');
    patientToken = patientUser.accessToken;
    patientId = patientUser.user.id;

    // Create an unauthorized user
    const unauthorizedUser = await authService.signup('Other User', 'other@example.com', 'Password123!', '+19998887778');
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

    // Create an appointment for patient
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

    // Create initial chat message
    await ChatMessage.create({
      appointmentId: appointment._id,
      senderId: patientId,
      content: 'Hello doctor!',
    });
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Doctor.deleteMany({});
    await Appointment.deleteMany({});
    await ChatMessage.deleteMany({});
  });

  describe('GET /api/v1/chats/:appointmentId/messages', () => {
    it('should retrieve chat messages for authorized patient', async () => {
      const res = await request(app)
        .get(`/api/v1/chats/${appointmentId}/messages`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].text).toBe('Hello doctor!');
      expect(res.body.data[0].senderName).toBe('Patient User');
    });

    it('should reject retrieval for unauthorized user', async () => {
      const res = await request(app)
        .get(`/api/v1/chats/${appointmentId}/messages`)
        .set('Authorization', `Bearer ${unauthorizedToken}`);

      expect(res.status).toBe(403);
      expect(res.body.status).toBe('fail');
    });
  });

  describe('POST /api/v1/chats/:appointmentId/messages', () => {
    it('should successfully send a message from authorized patient', async () => {
      const res = await request(app)
        .post(`/api/v1/chats/${appointmentId}/messages`)
        .set('Authorization', `Bearer ${patientToken}`)
        .send({ text: 'I have some symptoms to discuss' });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.text).toBe('I have some symptoms to discuss');
      expect(res.body.data.senderName).toBe('Patient User');
    });

    it('should reject sending message from unauthorized user', async () => {
      const res = await request(app)
        .post(`/api/v1/chats/${appointmentId}/messages`)
        .set('Authorization', `Bearer ${unauthorizedToken}`)
        .send({ text: 'Hello!' });

      expect(res.status).toBe(403);
    });

    it('should reject empty messages', async () => {
      const res = await request(app)
        .post(`/api/v1/chats/${appointmentId}/messages`)
        .set('Authorization', `Bearer ${patientToken}`)
        .send({ text: '' });

      expect(res.status).toBe(400);
    });
  });
});
