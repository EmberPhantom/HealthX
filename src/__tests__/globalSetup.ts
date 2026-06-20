import { MongoMemoryServer } from 'mongodb-memory-server';
import * as fs from 'fs';
import * as path from 'path';

const CONFIG_PATH = path.join(__dirname, 'globalConfig.json');

export default async function globalSetup() {
  if (fs.existsSync(CONFIG_PATH)) {
    fs.unlinkSync(CONFIG_PATH);
  }

  const mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();

  fs.writeFileSync(CONFIG_PATH, JSON.stringify({ uri, pid: process.pid }));
  (global as any).__MONGOD_INSTANCE__ = mongod;
}
