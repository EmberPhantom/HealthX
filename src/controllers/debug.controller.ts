import { Request, Response } from 'express';
import mongoose from 'mongoose';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';

export const getDbInfo = catchAsync(async (req: AuthRequest, res: Response) => {
  const conn = mongoose.connection;
  const collections = await conn.db?.listCollections().toArray();
  const collectionNames = collections?.map((c: { name: string }) => c.name) || [];

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      host: conn.host,
      port: conn.port,
      databaseName: conn.name,
      readyState: conn.readyState,
      models: Object.keys(mongoose.models).length,
      collections: collectionNames,
    },
  });
});
