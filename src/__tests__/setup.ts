import { MongoMemoryServer } from 'mongodb-memory-server';
import { connect, disconnect } from 'mongoose';
import User from '../models/User';
import Patient from '../models/Patient';
import AuditLog from '../models/AuditLog';
import LoginAttempt from '../models/LoginAttempt';

let mongod: MongoMemoryServer;

// Silence console in tests (keep console.error for test debugging)
global.console.log = jest.fn();
global.console.warn = jest.fn();

beforeAll(async () => {
  mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  await connect(uri);
  await Promise.all([
    User.deleteMany({}),
    Patient.deleteMany({}),
    AuditLog.deleteMany({}),
    LoginAttempt.deleteMany({}),
  ]);
  await User.syncIndexes();
});

afterAll(async () => {
  await Promise.all([
    User.deleteMany({}),
    Patient.deleteMany({}),
    AuditLog.deleteMany({}),
    LoginAttempt.deleteMany({}),
  ]);
  await disconnect();
  await mongod.stop();
});

afterEach(() => {
  jest.clearAllMocks();
});
