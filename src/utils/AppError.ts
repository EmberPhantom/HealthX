export class AppError extends Error {
    public readonly statusCode: number;
    public readonly isOperational: boolean;
    public details?: Array<{ field: string; message: string; code?: string }>;

    constructor(message: string, statusCode: number) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = true;

        Error.captureStackTrace(this, this.constructor);
    }
}
