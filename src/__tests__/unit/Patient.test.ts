import Patient from '../../models/Patient';
import User from '../../models/User';
import { testUsers } from '../fixtures/test.fixtures';
import { Types } from 'mongoose';

describe('Patient Model Tests', () => {
  let userId: string;

  beforeEach(async () => {
    const user = await User.create(testUsers.validUser);
    userId = user._id.toString();
  });

  afterEach(async () => {
    await Patient.deleteMany({});
    await User.deleteMany({});
  });

  describe('Patient Creation', () => {
    test('UNIT-Patient-001: Should create patient with valid userId', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      expect(patient).toBeDefined();
      expect(patient.userId.toString()).toBe(userId);
    });

    test('UNIT-Patient-002: Should create patient with medical history', async () => {
      const medicalHistory = 'Diabetes, Hypertension';
      const patient = await Patient.create({
        userId,
        medicalHistory,
        allergies: [],
        medications: [],
      });

      expect(patient.medicalHistory).toBe(medicalHistory);
    });

    test('UNIT-Patient-003: Should create patient with allergies array', async () => {
      const allergies = ['Peanuts', 'Shellfish', 'Penicillin'];
      const patient = await Patient.create({
        userId,
        allergies,
        medications: [],
      });

      expect(patient.allergies).toEqual(allergies);
    });

    test('UNIT-Patient-004: Should create patient with medications array', async () => {
      const medications = ['Metformin', 'Lisinopril'];
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications,
      });

      expect(patient.medications).toEqual(medications);
    });

    test('UNIT-Patient-005: Should create patient with emergency contact', async () => {
      const emergencyContact = {
        name: 'John Doe',
        phone: '+1234567890',
        relation: 'Brother',
      };

      const patient = await Patient.create({
        userId,
        emergencyContact,
        allergies: [],
        medications: [],
      });

      expect(patient.emergencyContact?.name).toBe(emergencyContact.name);
      expect(patient.emergencyContact?.phone).toBe(emergencyContact.phone);
      expect(patient.emergencyContact?.relation).toBe(emergencyContact.relation);
    });

    test('UNIT-Patient-006: Should create patient with insurance info', async () => {
      const patient = await Patient.create({
        userId,
        insuranceProvider: 'Blue Cross',
        insurancePolicyNo: 'BC123456789',
        allergies: [],
        medications: [],
      });

      expect(patient.insuranceProvider).toBe('Blue Cross');
      expect(patient.insurancePolicyNo).toBe('BC123456789');
    });

    test('UNIT-Patient-007: Should set default allergies array', async () => {
      const patient = await Patient.create({
        userId,
        medications: [],
      });

      expect(Array.isArray(patient.allergies)).toBe(true);
      expect(patient.allergies.length).toBe(0);
    });

    test('UNIT-Patient-008: Should set default medications array', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
      });

      expect(Array.isArray(patient.medications)).toBe(true);
      expect(patient.medications.length).toBe(0);
    });
  });

  describe('userId Constraint', () => {
    test('UNIT-Patient-009: Should enforce unique userId constraint', async () => {
      await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      await expect(Patient.create({
        userId,
        allergies: [],
        medications: [],
      })).rejects.toThrow();
    });

    test('UNIT-Patient-010: Should require userId field', async () => {
      await expect(Patient.create({
        allergies: [],
        medications: [],
      })).rejects.toThrow();
    });

    test('UNIT-Patient-011: Should reference User model', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const populated = await patient.populate('userId');
      expect(populated.userId).toBeDefined();
    });
  });

  describe('Array Operations', () => {
    test('UNIT-Patient-012: Should add allergen to allergies array', async () => {
      const patient = await Patient.create({
        userId,
        allergies: ['Peanuts'],
        medications: [],
      });

      patient.allergies.push('Shellfish');
      await patient.save();

      const updated = await Patient.findById(patient._id);
      expect(updated!.allergies).toContain('Shellfish');
      expect(updated!.allergies.length).toBe(2);
    });

    test('UNIT-Patient-013: Should remove allergen from array', async () => {
      const patient = await Patient.create({
        userId,
        allergies: ['Peanuts', 'Shellfish'],
        medications: [],
      });

      patient.allergies = patient.allergies.filter(a => a !== 'Shellfish');
      await patient.save();

      const updated = await Patient.findById(patient._id);
      expect(updated!.allergies).not.toContain('Shellfish');
      expect(updated!.allergies.length).toBe(1);
    });

    test('UNIT-Patient-014: Should add medication', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: ['Metformin'],
      });

      patient.medications.push('Lisinopril');
      await patient.save();

      const updated = await Patient.findById(patient._id);
      expect(updated!.medications).toContain('Lisinopril');
      expect(updated!.medications.length).toBe(2);
    });

    test('UNIT-Patient-015: Should handle empty arrays', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      expect(patient.allergies.length).toBe(0);
      expect(patient.medications.length).toBe(0);
    });
  });

  describe('Timestamps', () => {
    test('UNIT-Patient-016: Should set createdAt', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      expect(patient.createdAt).toBeDefined();
      expect(patient.createdAt).toBeInstanceOf(Date);
    });

    test('UNIT-Patient-017: Should set updatedAt', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      expect(patient.updatedAt).toBeDefined();
      expect(patient.updatedAt).toBeInstanceOf(Date);
    });

    test('UNIT-Patient-018: Should update updatedAt on save', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const originalTime = patient.updatedAt;
      await new Promise(resolve => setTimeout(resolve, 100));

      patient.medicalHistory = 'Updated history';
      await patient.save();

      expect(patient.updatedAt.getTime()).toBeGreaterThan(originalTime.getTime());
    });
  });

  describe('Query Operations', () => {
    test('UNIT-Patient-019: Should find patient by userId', async () => {
      await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const patient = await Patient.findOne({ userId });
      expect(patient).toBeDefined();
      expect(patient!.userId.toString()).toBe(userId);
    });

    test('UNIT-Patient-020: Should find patient by id', async () => {
      const created = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const patient = await Patient.findById(created._id);
      expect(patient).toBeDefined();
      expect(patient!._id.toString()).toBe(created._id.toString());
    });

    test('UNIT-Patient-021: Should return null for non-existent patient', async () => {
      const patient = await Patient.findById(new Types.ObjectId());
      expect(patient).toBeNull();
    });
  });

  describe('Update Operations', () => {
    test('UNIT-Patient-022: Should update medical history', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      await Patient.findByIdAndUpdate(patient._id, {
        medicalHistory: 'Updated history',
      });

      const updated = await Patient.findById(patient._id);
      expect(updated!.medicalHistory).toBe('Updated history');
    });

    test('UNIT-Patient-023: Should update insurance info', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      await Patient.findByIdAndUpdate(patient._id, {
        insuranceProvider: 'Aetna',
        insurancePolicyNo: 'AET987654321',
      });

      const updated = await Patient.findById(patient._id);
      expect(updated!.insuranceProvider).toBe('Aetna');
      expect(updated!.insurancePolicyNo).toBe('AET987654321');
    });

    test('UNIT-Patient-024: Should update emergency contact', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const newContact = {
        name: 'Jane Doe',
        phone: '+9876543210',
        relation: 'Sister',
      };

      await Patient.findByIdAndUpdate(patient._id, {
        emergencyContact: newContact,
      });

      const updated = await Patient.findById(patient._id);
      expect(updated!.emergencyContact?.name).toBe(newContact.name);
      expect(updated!.emergencyContact?.phone).toBe(newContact.phone);
      expect(updated!.emergencyContact?.relation).toBe(newContact.relation);
    });
  });

  describe('Delete Operations', () => {
    test('UNIT-Patient-025: Should delete patient', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      await Patient.findByIdAndDelete(patient._id);

      const deleted = await Patient.findById(patient._id);
      expect(deleted).toBeNull();
    });

    test('UNIT-Patient-026: Should delete multiple patients', async () => {
      const user1 = await User.create({
        ...testUsers.validUser,
        email: 'patient_test_user1@example.com',
        phone: '+1234567801',
      });
      const user2 = await User.create({
        ...testUsers.anotherValidUser,
        email: 'patient_test_user2@example.com',
        phone: '+1234567802',
      });

      await Patient.create({
        userId: user1._id,
        allergies: [],
        medications: [],
      });

      await Patient.create({
        userId: user2._id,
        allergies: [],
        medications: [],
      });

      await Patient.deleteMany({});

      const count = await Patient.countDocuments();
      expect(count).toBe(0);
    });
  });

  describe('Relationship Integrity', () => {
    test('UNIT-Patient-027: Should maintain userId reference', async () => {
      const patient = await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const user = await User.findById(userId);
      expect(user).toBeDefined();

      expect(patient.userId.toString()).toBe(user!._id.toString());
    });

    test('UNIT-Patient-028: Should allow patient lookup via userId', async () => {
      await Patient.create({
        userId,
        allergies: [],
        medications: [],
      });

      const patient = await Patient.findOne({ userId });
      expect(patient).toBeDefined();
      expect(patient!.userId.toString()).toBe(userId);
    });
  });
});
