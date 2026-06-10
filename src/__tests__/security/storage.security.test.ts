import storageService from '../../services/storage.service';
import { AppError } from '../../utils/AppError';

describe('Storage Security & File Validation Tests', () => {
  describe('Path Traversal Prevention', () => {
    it('should reject file deletion paths outside the uploads directory', async () => {
      const traversalPath = '../../../../etc/passwd';
      
      await expect(
        storageService.deleteFile(traversalPath)
      ).rejects.toThrow(
        expect.objectContaining({
          statusCode: 400,
          message: 'Invalid file path',
        })
      );
    });
  });

  describe('File Validation Integrity', () => {
    it('should reject files exceeding the maximum size limit', () => {
      const mockFile = {
        fieldname: 'file',
        originalname: 'test.png',
        encoding: '7bit',
        mimetype: 'image/png',
        buffer: Buffer.alloc(10 * 1024 * 1024), // 10MB
        size: 10 * 1024 * 1024,
      } as Express.Multer.File;

      const result = storageService.validateFile(mockFile, {
        maxSize: 5 * 1024 * 1024, // 5MB limit
      });

      expect(result.valid).toBe(false);
      expect(result.error).toContain('exceeds limit');
    });

    it('should reject files with double extensions like .jpg.exe', () => {
      const mockFile = {
        fieldname: 'file',
        originalname: 'malicious.jpg.exe',
        encoding: '7bit',
        mimetype: 'image/jpeg',
        buffer: Buffer.alloc(100),
        size: 100,
      } as Express.Multer.File;

      const result = storageService.validateFile(mockFile, {
        allowedExtensions: ['.jpg', '.jpeg', '.png'],
      });

      expect(result.valid).toBe(false);
      expect(result.error).toContain('Invalid file extension');
    });

    it('should reject MIME type and extension mismatch', () => {
      const mockFile = {
        fieldname: 'file',
        originalname: 'fake_image.png',
        encoding: '7bit',
        mimetype: 'application/x-msdownload', // actually an exe
        buffer: Buffer.alloc(100),
        size: 100,
      } as Express.Multer.File;

      const result = storageService.validateFile(mockFile, {
        allowedMimes: ['image/png'],
        allowedExtensions: ['.png'],
      });

      expect(result.valid).toBe(false);
      expect(result.error).toContain('Invalid file type');
    });
  });
});
