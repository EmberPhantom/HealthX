import mongoose from 'mongoose';
import * as fs from 'fs';
import * as path from 'path';

const CONFIG_PATH = path.join(__dirname, 'globalConfig.json');

function getMongoUri(): string {
  if (process.env.MONGO_URI) {
    return process.env.MONGO_URI;
  }
  if (fs.existsSync(CONFIG_PATH)) {
    const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
    return config.uri;
  }
  throw new Error(
    'MONGO_URI not set and globalConfig.json not found. ' +
    'Ensure globalSetup runs before tests.'
  );
}

let connected = false;

beforeAll(async () => {
  if (!connected) {
    const uri = getMongoUri();
    await mongoose.connect(uri);
    connected = true;
  }
});

afterAll(async () => {
  await mongoose.disconnect();
  connected = false;
});

afterEach(() => {
  jest.clearAllMocks();
});
