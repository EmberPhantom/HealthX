import path from 'path';
import fs from 'fs';
import { promisify } from 'util';
import sharp from 'sharp';
import { AppError } from '../utils/AppError';
import logger from '../utils/logger';

const mkdir = promisify(fs.mkdir);
const unlink = promisify(fs.unlink);
const readFile = promisify(fs.readFile);

/**
 * File Upload Service
 * Handles file validation, storage, and image processing
 */
class FileUploadService {
  private uploadDir = path.join(process.cwd(), 'uploads');
  private avatarDir = path.join(this.uploadDir, 'avatars');

  constructor() {
    this.ensureUploadDirs();
  }

  /**
   * Ensure upload directories exist
   */
  private async ensureUploadDirs() {
    try {
      if (!fs.existsSync(this.uploadDir)) {
        await mkdir(this.uploadDir, { recursive: true });
      }
      if (!fs.existsSync(this.avatarDir)) {
        await mkdir(this.avatarDir, { recursive: true });
      }
    } catch (error) {
      logger.error('Error creating upload directories:', error);
    }
  }

  /**
   * Validate uploaded file
   */
  validateFile(
    file: Express.Multer.File,
    options: {
      maxSize?: number; // in bytes
      allowedMimes?: string[];
      allowedExtensions?: string[];
    } = {}
  ): { valid: boolean; error?: string } {
    const {
      maxSize = 5 * 1024 * 1024, // 5MB default
      allowedMimes = ['image/jpeg', 'image/png', 'image/webp'],
      allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'],
    } = options;

    // Check file existence
    if (!file) {
      return { valid: false, error: 'No file provided' };
    }

    // Check file size
    if (file.size > maxSize) {
      return {
        valid: false,
        error: `File size exceeds limit of ${maxSize / 1024 / 1024}MB`,
      };
    }

    // Check MIME type
    if (!allowedMimes.includes(file.mimetype)) {
      return {
        valid: false,
        error: `Invalid file type. Allowed types: ${allowedMimes.join(', ')}`,
      };
    }

    // Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    if (!allowedExtensions.includes(ext)) {
      return {
        valid: false,
        error: `Invalid file extension. Allowed: ${allowedExtensions.join(', ')}`,
      };
    }

    return { valid: true };
  }

  /**
   * Process and save avatar image
   */
  async saveAvatar(file: Express.Multer.File, userId: string): Promise<string> {
    try {
      // Validate file
      const validation = this.validateFile(file, {
        maxSize: 2 * 1024 * 1024, // 2MB for avatars
        allowedMimes: ['image/jpeg', 'image/png', 'image/webp'],
      });

      if (!validation.valid) {
        throw new AppError(validation.error || 'Invalid file', 400);
      }

      // Generate filename
      const timestamp = Date.now();
      const filename = `avatar_${userId}_${timestamp}.webp`;
      const filepath = path.join(this.avatarDir, filename);

      // Compress and convert to webp
      await sharp(file.buffer)
        .resize(256, 256, {
          fit: 'cover',
          position: 'center',
        })
        .webp({ quality: 80 })
        .toFile(filepath);

      // Return relative URL path
      return `/uploads/avatars/${filename}`;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Error processing image', 500);
    }
  }

  /**
   * Process and save general image
   */
  async saveImage(file: Express.Multer.File, category: string): Promise<string> {
    try {
      // Validate file
      const validation = this.validateFile(file, {
        maxSize: 5 * 1024 * 1024, // 5MB
        allowedMimes: ['image/jpeg', 'image/png', 'image/webp'],
      });

      if (!validation.valid) {
        throw new AppError(validation.error || 'Invalid file', 400);
      }

      // Create target directory if needed
      const targetDir = path.join(this.uploadDir, category);
      if (!fs.existsSync(targetDir)) {
        await fs.promises.mkdir(targetDir, { recursive: true });
      }

      // Generate filename
      const timestamp = Date.now();
      const filename = `${category}_${timestamp}.webp`;
      const filepath = path.join(targetDir, filename);

      // Compress and convert to webp
      await sharp(file.buffer)
        .resize(800, 800, {
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 80 })
        .toFile(filepath);

      // Return relative URL path
      return `/uploads/${category}/${filename}`;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error('Error saving image:', error);
      throw new AppError('Error processing image', 500);
    }
  }

  /**
   * Process and save document file
   */
  async saveDocument(
    file: Express.Multer.File,
    userId: string,
    docType: string
  ): Promise<string> {
    try {
      // Validate file
      const validation = this.validateFile(file, {
        maxSize: 10 * 1024 * 1024, // 10MB for documents
        allowedMimes: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ],
        allowedExtensions: ['.pdf', '.doc', '.docx'],
      });

      if (!validation.valid) {
        throw new AppError(validation.error || 'Invalid file', 400);
      }

      // Create document directory if needed
      const docDir = path.join(this.uploadDir, 'documents', docType);
      if (!fs.existsSync(docDir)) {
        await mkdir(docDir, { recursive: true });
      }

      // Generate filename
      const timestamp = Date.now();
      const ext = path.extname(file.originalname);
      const filename = `doc_${userId}_${timestamp}${ext}`;
      const filepath = path.join(docDir, filename);

      // Save file
      await fs.promises.writeFile(filepath, file.buffer);

      // Return relative URL path
      return `/uploads/documents/${docType}/${filename}`;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Error saving document', 500);
    }
  }

  /**
   * Process and save a health record file (image or PDF)
   */
  async saveHealthRecordFile(file: Express.Multer.File, userId: string): Promise<string> {
    try {
      if (!file) {
        throw new AppError('No file provided', 400);
      }

      // Create target directory
      const recordDir = path.join(this.uploadDir, 'health-records');
      if (!fs.existsSync(recordDir)) {
        await fs.promises.mkdir(recordDir, { recursive: true });
      }

      const timestamp = Date.now();
      const ext = path.extname(file.originalname).toLowerCase();
      const originalNameClean = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9]/g, '_');
      
      if (ext === '.pdf') {
        const filename = `record_${userId}_${timestamp}_${originalNameClean}.pdf`;
        const filepath = path.join(recordDir, filename);
        await fs.promises.writeFile(filepath, file.buffer);
        return `/uploads/health-records/${filename}`;
      } else {
        const filename = `record_${userId}_${timestamp}_${originalNameClean}.webp`;
        const filepath = path.join(recordDir, filename);
        await sharp(file.buffer)
          .resize(1200, 1200, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .webp({ quality: 85 })
          .toFile(filepath);
        return `/uploads/health-records/${filename}`;
      }
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error('Error saving health record file:', error);
      throw new AppError('Error processing file upload', 500);
    }
  }

  /**
   * Delete file
   */
  async deleteFile(filePath: string): Promise<void> {
    try {
      const fullPath = path.isAbsolute(filePath) ? filePath : path.join(process.cwd(), filePath);

      // Security check: ensure file is within uploads directory
      if (!fullPath.startsWith(this.uploadDir)) {
        throw new AppError('Invalid file path', 400);
      }

      await unlink(fullPath);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error('Error deleting file:', error);
      throw error;
    }
  }

  /**
   * Get file serving URL
   */
  getFileUrl(filename: string, type: 'avatar' | 'document'): string {
    if (type === 'avatar') {
      return `/uploads/avatars/${filename}`;
    }
    return `/uploads/documents/${filename}`;
  }

  /**
   * Cleanup old files (for maintenance)
   */
  async cleanupOldFiles(daysOld: number = 30): Promise<number> {
    try {
      let deletedCount = 0;
      const now = Date.now();
      const maxAge = daysOld * 24 * 60 * 60 * 1000;

      const files = fs.readdirSync(this.uploadDir, { recursive: true });

      for (const file of files) {
        const filePath = path.join(this.uploadDir, file as string);
        const stats = fs.statSync(filePath);

        if (now - stats.mtimeMs > maxAge) {
          await unlink(filePath);
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (error) {
      logger.error('Error cleaning up old files:', error);
      return 0;
    }
  }

  /**
   * Get upload statistics
   */
  async getUploadStats(): Promise<{
    totalFiles: number;
    totalSize: number;
    byType: Record<string, { count: number; size: number }>;
  }> {
    try {
      let totalFiles = 0;
      let totalSize = 0;
      const byType: Record<string, { count: number; size: number }> = {
        avatar: { count: 0, size: 0 },
        document: { count: 0, size: 0 },
        other: { count: 0, size: 0 },
      };

      const files = fs.readdirSync(this.uploadDir, { recursive: true });

      for (const file of files) {
        const filePath = path.join(this.uploadDir, file as string);
        if (fs.statSync(filePath).isFile()) {
          const stats = fs.statSync(filePath);
          totalFiles++;
          totalSize += stats.size;

          if ((file as string).includes('avatar')) {
            byType.avatar.count++;
            byType.avatar.size += stats.size;
          } else if ((file as string).includes('doc')) {
            byType.document.count++;
            byType.document.size += stats.size;
          } else {
            byType.other.count++;
            byType.other.size += stats.size;
          }
        }
      }

      return { totalFiles, totalSize, byType };
    } catch (error) {
      logger.error('Error getting upload statistics:', error);
      return { totalFiles: 0, totalSize: 0, byType: {} };
    }
  }
}

export default new FileUploadService();
