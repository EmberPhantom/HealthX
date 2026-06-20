export default async function globalTeardown() {
  const mongod = (global as any).__MONGOD_INSTANCE__;
  if (mongod) {
    await mongod.stop();
  }
}
