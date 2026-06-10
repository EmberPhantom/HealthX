import storageService from '../../../services/storage.service';
import path from 'path';

// Mock fs module
jest.mock('fs', () => {
  const mockExistsSync = jest.fn();
  const mockReaddirSync = jest.fn();
  const mockStatSync = jest.fn();
  const mockMkdir = jest.fn((p, options, cb) => cb(null));
  const mockMkdirSync = jest.fn();
  const mockUnlink = jest.fn((p, cb) => cb(null));
  const mockReadFile = jest.fn((p, cb) => cb(null, Buffer.from('')));

  return {
    existsSync: mockExistsSync,
    readdirSync: mockReaddirSync,
    statSync: mockStatSync,
    mkdir: mockMkdir,
    mkdirSync: mockMkdirSync,
    unlink: mockUnlink,
    readFile: mockReadFile,
    appendFile: jest.fn((p, content, cb) => cb && cb(null)),
    promises: {
      writeFile: jest.fn().mockResolvedValue(undefined),
    },
  };
});

// Mock sharp module
jest.mock('sharp', () => {
  const mockSharpInstance = {
    resize: jest.fn().mockReturnThis(),
    webp: jest.fn().mockReturnThis(),
    toFile: jest.fn().mockResolvedValue(undefined),
  };
  return jest.fn(() => mockSharpInstance);
});

describe('StorageService', () => {
  const mockFile: any = {
    buffer: Buffer.from('fake image data'),
    originalname: 'test.jpg',
    mimetype: 'image/jpeg',
    size: 1024,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    const fs = require('fs');
    fs.existsSync.mockReturnValue(true);
  });

  describe('saveAvatar', () => {
    it('should save and compress avatar successfully', async () => {
      const sharp = require('sharp');
      const fs = require('fs');

      const result = await storageService.saveAvatar(mockFile, 'user-123');

      expect(typeof result).toBe('string');
      expect(result).toContain('/uploads/avatars/avatar_user-123_');
      expect(sharp).toHaveBeenCalledWith(mockFile.buffer);
      expect(sharp().resize).toHaveBeenCalledWith(256, 256, {
        fit: 'cover',
        position: 'center',
      });
      expect(sharp().webp).toHaveBeenCalledWith({ quality: 80 });
      expect(sharp().toFile).toHaveBeenCalled();
    });

    it('should throw error if file size exceeds 2MB', async () => {
      const largeFile = {
        ...mockFile,
        size: 3 * 1024 * 1024, // 3MB
      };

      await expect(
        storageService.saveAvatar(largeFile, 'user-123')
      ).rejects.toThrow('File size exceeds limit');
    });

    it('should throw error for invalid file type', async () => {
      const invalidFile = {
        ...mockFile,
        mimetype: 'application/pdf',
        originalname: 'test.pdf',
      };

      await expect(
        storageService.saveAvatar(invalidFile, 'user-123')
      ).rejects.toThrow('Invalid file type');
    });

    it('should throw error if compression fails', async () => {
      const sharp = require('sharp');
      sharp.mockImplementationOnce(() => {
        throw new Error('Sharp compression error');
      });

      await expect(
        storageService.saveAvatar(mockFile, 'user-123')
      ).rejects.toThrow('Error processing image');
    });
  });

  describe('saveDocument', () => {
    it('should save document successfully', async () => {
      const docFile = {
        ...mockFile,
        mimetype: 'application/pdf',
        originalname: 'document.pdf',
      };

      const result = await storageService.saveDocument(docFile, 'user-123', 'medical');

      expect(typeof result).toBe('string');
      expect(result).toContain('/uploads/documents/medical/doc_user-123_');
    });

    it('should throw error if file size exceeds 10MB', async () => {
      const largeDoc = {
        ...mockFile,
        size: 15 * 1024 * 1024,
        mimetype: 'application/pdf',
        originalname: 'document.pdf',
      };

      await expect(
        storageService.saveDocument(largeDoc, 'user-123', 'medical')
      ).rejects.toThrow('File size exceeds limit');
    });

    it('should support PDF and Word documents', async () => {
      const wordDoc = {
        ...mockFile,
        mimetype: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        originalname: 'document.docx',
      };

      const result = await storageService.saveDocument(wordDoc, 'user-123', 'insurance');
      expect(result).toContain('/uploads/documents/insurance/doc_user-123_');
    });

    it('should throw error for invalid document type', async () => {
      const invalidDoc = {
        ...mockFile,
        mimetype: 'text/plain',
        originalname: 'test.txt',
      };

      await expect(
        storageService.saveDocument(invalidDoc, 'user-123', 'medical')
      ).rejects.toThrow('Invalid file type');
    });
  });

  describe('deleteFile', () => {
    it('should delete file successfully', async () => {
      const filePath = 'uploads/test.jpg';
      const fs = require('fs');

      await storageService.deleteFile(filePath);

      expect(fs.unlink).toHaveBeenCalled();
    });

    it('should throw error if file not found / unlink fails', async () => {
      const filePath = 'uploads/nonexistent.jpg';
      const fs = require('fs');
      fs.unlink.mockImplementationOnce((p: any, cb: any) => cb(new Error('ENOENT')));

      await expect(
        storageService.deleteFile(filePath)
      ).rejects.toThrow();
    });

    it('should prevent directory traversal attacks', async () => {
      const maliciousPath = 'uploads/../../sensitive.txt';

      await expect(
        storageService.deleteFile(maliciousPath)
      ).rejects.toThrow('Invalid file path');
    });
  });

  describe('getFileUrl', () => {
    it('should return correct file URL', () => {
      const filename = 'avatar-123.webp';
      const url = storageService.getFileUrl(filename, 'avatar');

      expect(url).toContain('/uploads/avatars/');
      expect(url).toContain(filename);
    });

    it('should handle document URLs', () => {
      const filename = 'doc-456.pdf';
      const url = storageService.getFileUrl(filename, 'document');

      expect(url).toContain('/uploads/documents/');
      expect(url).toContain(filename);
    });
  });

  describe('cleanupOldFiles', () => {
    it('should delete files older than specified days', async () => {
      const fs = require('fs');
      fs.readdirSync.mockReturnValue(['old-file.jpg']);
      fs.statSync.mockReturnValue({
        mtimeMs: Date.now() - 40 * 24 * 60 * 60 * 1000,
        isFile: () => true,
      });

      const count = await storageService.cleanupOldFiles(30);

      expect(fs.unlink).toHaveBeenCalled();
      expect(count).toBe(1);
    });

    it('should not delete recent files', async () => {
      const fs = require('fs');
      fs.readdirSync.mockReturnValue(['recent-file.jpg']);
      fs.statSync.mockReturnValue({
        mtimeMs: Date.now() - 1 * 24 * 60 * 60 * 1000,
        isFile: () => true,
      });

      const count = await storageService.cleanupOldFiles(30);

      expect(fs.unlink).not.toHaveBeenCalled();
      expect(count).toBe(0);
    });
  });

  describe('getUploadStats', () => {
    it('should return upload statistics', async () => {
      const fs = require('fs');
      fs.readdirSync.mockReturnValue(['avatar_file1.jpg', 'doc_file2.jpg']);
      fs.statSync.mockImplementation((filePath: string) => ({
        isFile: () => true,
        size: filePath.includes('avatar') ? 1024 : 2048,
      }));

      const stats = await storageService.getUploadStats();

      expect(stats).toEqual({
        totalFiles: 2,
        totalSize: 3072,
        byType: {
          avatar: { count: 1, size: 1024 },
          document: { count: 1, size: 2048 },
          other: { count: 0, size: 0 },
        },
      });
    });

    it('should handle empty upload directory', async () => {
      const fs = require('fs');
      fs.readdirSync.mockReturnValue([]);

      const stats = await storageService.getUploadStats();

      expect(stats.totalFiles).toBe(0);
    });
  });
});
