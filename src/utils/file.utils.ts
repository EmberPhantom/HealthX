import path from 'path';
import fs from 'fs';
import crypto from 'crypto';

/**
 * File utility functions
 */

/**
 * Generate unique filename
 */
export function generateUniqueFilename(
  originalname: string,
  prefix: string = ''
): string {
  const ext = path.extname(originalname);
  const name = path.basename(originalname, ext);
  const hash = crypto.randomBytes(8).toString('hex');
  const timestamp = Date.now();

  if (prefix) {
    return `${prefix}_${timestamp}_${hash}${ext}`;
  }

  return `${timestamp}_${hash}${ext}`;
}

/**
 * Get file extension
 */
export function getFileExtension(filename: string): string {
  return path.extname(filename).toLowerCase();
}

/**
 * Get file MIME type from extension
 */
export function getMimeType(filename: string): string {
  const ext = getFileExtension(filename);

  const mimeTypes: Record<string, string> = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.txt': 'text/plain',
    '.csv': 'text/csv',
  };

  return mimeTypes[ext] || 'application/octet-stream';
}

/**
 * Format file size for display
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Validate filename for security
 */
export function isValidFilename(filename: string): boolean {
  // Prevent directory traversal
  if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
    return false;
  }

  // Prevent special characters that could cause issues
  const invalidChars = /[<>:"|?*\x00-\x1f]/g;
  if (invalidChars.test(filename)) {
    return false;
  }

  // Check length
  if (filename.length > 255) {
    return false;
  }

  return true;
}

/**
 * Check if file exists
 */
export function fileExists(filePath: string): boolean {
  return fs.existsSync(filePath);
}

/**
 * Get file size in bytes
 */
export function getFileSize(filePath: string): number {
  try {
    const stats = fs.statSync(filePath);
    return stats.size;
  } catch (error) {
    return 0;
  }
}

/**
 * Get file creation date
 */
export function getFileCreatedDate(filePath: string): Date | null {
  try {
    const stats = fs.statSync(filePath);
    return stats.birthtime;
  } catch (error) {
    return null;
  }
}

/**
 * Delete file safely
 */
export async function deleteFileSafely(filePath: string): Promise<boolean> {
  try {
    // Validate filename
    const filename = path.basename(filePath);
    if (!isValidFilename(filename)) {
      return false;
    }

    // Check if file exists
    if (!fileExists(filePath)) {
      return true;
    }

    // Delete file
    await fs.promises.unlink(filePath);
    return true;
  } catch (error) {
    console.error('Error deleting file:', error);
    return false;
  }
}

/**
 * Copy file safely
 */
export async function copyFileSafely(
  sourcePath: string,
  destPath: string
): Promise<boolean> {
  try {
    // Validate filenames
    const sourceFilename = path.basename(sourcePath);
    const destFilename = path.basename(destPath);

    if (!isValidFilename(sourceFilename) || !isValidFilename(destFilename)) {
      return false;
    }

    // Copy file
    await fs.promises.copyFile(sourcePath, destPath);
    return true;
  } catch (error) {
    console.error('Error copying file:', error);
    return false;
  }
}

/**
 * Create directory structure
 */
export async function createDirectory(dirPath: string): Promise<boolean> {
  try {
    await fs.promises.mkdir(dirPath, { recursive: true });
    return true;
  } catch (error) {
    console.error('Error creating directory:', error);
    return false;
  }
}
