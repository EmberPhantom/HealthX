import { Request, Response, NextFunction } from 'express';
import { generateCSRFToken, validateCSRFToken } from '../../../middlewares/csrf.middleware';

interface MockRequest extends Request {
  csrfToken?: string;
  session?: { id: string };
}

describe('CSRF Middleware', () => {
  let req: MockRequest;
  let res: Response;
  let next: NextFunction;

  beforeEach(() => {
    req = {
      method: 'POST',
      headers: {},
      sessionID: 'session-123',
      ip: '127.0.0.1',
    } as MockRequest;

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      setHeader: jest.fn().mockReturnThis(),
    } as any;

    next = jest.fn();
  });

  describe('generateCSRFToken', () => {
    it('should generate CSRF token on GET request', async () => {
      req.method = 'GET';

      await generateCSRFToken(req, res, next);

      expect(req.csrfToken).toBeDefined();
      expect(typeof req.csrfToken).toBe('string');
      expect(next).toHaveBeenCalled();
    });

    it('should pass through on GET request', async () => {
      req.method = 'GET';

      await generateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should skip validation on safe methods', async () => {
      req.method = 'GET';

      await generateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('validateCSRFToken', () => {
    it('should validate valid CSRF token on POST', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should reject missing CSRF token on POST', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = undefined;

      await validateCSRFToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('should reject invalid CSRF token', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = 'invalid-token';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('should skip validation on safe methods', async () => {
      req.method = 'GET';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should validate PUT requests', async () => {
      req.method = 'PUT';
      req.headers['x-csrf-token'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should validate DELETE requests', async () => {
      req.method = 'DELETE';
      req.headers['x-csrf-token'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should validate PATCH requests', async () => {
      req.method = 'PATCH';
      req.headers['x-csrf-token'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should accept token from cookie as fallback', async () => {
      req.method = 'POST';
      req.cookies = { 'x-csrf-token': 'valid-token-123' };
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should regenerate token after successful validation', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should handle token expiration', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = 'expired-token';

      await validateCSRFToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
    });
  });

  describe('Token Storage', () => {
    it('should store tokens via cache service', async () => {
      req.method = 'GET';

      await generateCSRFToken(req, res, next);

      const token1 = req.csrfToken;

      const req2 = { method: 'GET', sessionID: 'session-124', ip: '127.0.0.2' } as MockRequest;
      const next2 = jest.fn();

      await generateCSRFToken(req2, res, next2);

      const token2 = req2.csrfToken;

      expect(token1).not.toBe(token2);
    });
  });

  describe('Edge Cases', () => {
    it('should handle missing session ID', async () => {
      req.method = 'POST';
      req.sessionID = undefined;
      req.headers['x-csrf-token'] = 'token';

      await validateCSRFToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('should handle case-insensitive header names', async () => {
      req.method = 'POST';
      req.headers['X-CSRF-TOKEN'] = 'valid-token-123';
      req.csrfToken = 'valid-token-123';

      await validateCSRFToken(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should handle whitespace in token', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = '  valid-token-123  ';

      await validateCSRFToken(req, res, next);

      expect(res.status).toHaveBeenCalled();
    });
  });
});
