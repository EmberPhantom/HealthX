import request from 'supertest';
import express from 'express';
import { Types } from 'mongoose';
import authRoutes from "../../routes/auth.routes";
import oauthService from "../../services/oauth.service";
import { authService } from "../../services/auth.service";
import User from "../../models/User";

jest.mock('../../services/oauth.service', () => ({
  __esModule: true,
  default: {
    handleOAuthLogin: jest.fn(),
    linkOAuthProvider: jest.fn(),
    unlinkOAuthProvider: jest.fn(),
    getLinkedProviders: jest.fn(),
    verifyOAuthState: jest.fn(),
    unlinkProvider: jest.fn(),
  }
}));
jest.mock('../../services/auth.service', () => ({
  __esModule: true,
  authService: {
    generateTokens: jest.fn(),
    verifyPassword: jest.fn(),
  }
}));
jest.mock("../../models/User");

describe.skip('OAuth Integration Workflow Tests', () => {
  let app: express.Application;
  const mockUserId = new Types.ObjectId().toString();
  const mockEmail = 'oauth@example.com';

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/auth', authRoutes);
    jest.clearAllMocks();
  });

  describe('Google OAuth Complete Flow', () => {
    it('should complete Google OAuth login flow', async () => {
      const googleProfile = {
        id: 'google-123',
        displayName: 'John Doe',
        emails: [{ value: mockEmail }],
        photos: [{ value: 'https://google.com/avatar.jpg' }],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        googleId: googleProfile.id,
        firstName: 'John',
        lastName: 'Doe',
      });

      (authService.generateTokens as jest.Mock).mockResolvedValue({
        accessToken: 'access-token-123',
        refreshToken: 'refresh-token-456',
      });

      const res = await request(app)
        .post('/auth/google')
        .send({ profile: googleProfile, accessToken: 'google-access-token' })
        .expect(200);

      expect(res.body).toHaveProperty('user');
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body.user.googleId).toBe(googleProfile.id);
    });

    it('should handle Google OAuth with refresh token', async () => {
      const googleRefreshToken = 'google-refresh-token';

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
      });

      await request(app)
        .post('/auth/google')
        .send({
          profile: { id: 'google-123', emails: [{ value: mockEmail }] },
          refreshToken: googleRefreshToken,
        })
        .expect(200);

      expect(oauthService.handleOAuthLogin).toHaveBeenCalledWith(
        'google',
        expect.any(Object),
        googleRefreshToken
      );
    });

    it('should handle existing Google account login', async () => {
      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        googleId: 'existing-google-id',
        isEmailVerified: true,
      });

      const res = await request(app)
        .post('/auth/google')
        .send({ profile: { id: 'existing-google-id' } })
        .expect(200);

      expect(res.body.user).toHaveProperty('isEmailVerified', true);
    });
  });

  describe('GitHub OAuth Complete Flow', () => {
    it('should complete GitHub OAuth login flow', async () => {
      const githubProfile = {
        id: 'github-456',
        username: 'johndoe',
        displayName: 'John Doe',
        emails: [{ value: mockEmail }],
        photos: [{ value: 'https://github.com/avatar.jpg' }],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        githubId: githubProfile.id,
      });

      const res = await request(app)
        .post('/auth/github')
        .send({ profile: githubProfile })
        .expect(200);

      expect(res.body.user).toHaveProperty('githubId', githubProfile.id);
    });

    it('should handle GitHub profile without email', async () => {
      const githubProfile = {
        id: 'github-789',
        username: 'johndoe',
        emails: [],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockRejectedValue(
        new Error('Email required for GitHub OAuth')
      );

      await request(app)
        .post('/auth/github')
        .send({ profile: githubProfile })
        .expect(400);
    });
  });

  describe('Microsoft OAuth Complete Flow', () => {
    it('should complete Microsoft OAuth login flow', async () => {
      const microsoftProfile = {
        id: 'microsoft-789',
        displayName: 'John Doe',
        emails: [{ value: mockEmail }],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        microsoftId: microsoftProfile.id,
      });

      const res = await request(app)
        .post('/auth/microsoft')
        .send({ profile: microsoftProfile })
        .expect(200);

      expect(res.body.user).toHaveProperty('microsoftId', microsoftProfile.id);
    });
  });

  describe('OAuth Account Linking', () => {
    it('should link Google to existing account', async () => {
      (oauthService.linkOAuthProvider as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        googleId: 'new-google-id',
        githubId: 'existing-github-id',
      });

      const res = await request(app)
        .post('/auth/link')
        .send({
          provider: 'google',
          profile: { id: 'new-google-id' },
        })
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body).toHaveProperty('message', expect.stringContaining('linked'));
    });

    it('should prevent linking already linked provider', async () => {
      (oauthService.linkOAuthProvider as jest.Mock).mockRejectedValue(
        new Error('Provider already linked to another account')
      );

      await request(app)
        .post('/auth/link')
        .send({ provider: 'google', profile: { id: 'google-123' } })
        .set('Authorization', `Bearer token`)
        .expect(400);
    });

    it('should handle linking to existing provider on same account', async () => {
      (oauthService.linkOAuthProvider as jest.Mock).mockRejectedValue(
        new Error('Provider already linked to this account')
      );

      await request(app)
        .post('/auth/link')
        .send({ provider: 'google', profile: { id: 'google-existing' } })
        .set('Authorization', `Bearer token`)
        .expect(400);
    });
  });

  describe('OAuth Account Unlinking', () => {
    it('should unlink OAuth provider from account', async () => {
      (oauthService.unlinkOAuthProvider as jest.Mock).mockResolvedValue({
        message: 'Provider unlinked',
        remainingProviders: ['github', 'password'],
      });

      const res = await request(app)
        .post('/auth/unlink')
        .send({ provider: 'google', password: 'user-password' })
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body).toHaveProperty('message', expect.stringContaining('unlinked'));
    });

    it('should prevent unlinking last authentication method', async () => {
      (oauthService.unlinkOAuthProvider as jest.Mock).mockRejectedValue(
        new Error('Cannot unlink - no other authentication methods available')
      );

      await request(app)
        .post('/auth/unlink')
        .send({ provider: 'google' })
        .set('Authorization', `Bearer token`)
        .expect(400);
    });

    it('should verify password before unlinking', async () => {
      (authService.verifyPassword as jest.Mock).mockRejectedValue(
        new Error('Invalid password')
      );

      await request(app)
        .post('/auth/unlink')
        .send({ provider: 'google', password: 'wrong-password' })
        .set('Authorization', `Bearer token`)
        .expect(401);
    });

    it('should allow unlinking if multiple providers exist', async () => {
      (oauthService.unlinkOAuthProvider as jest.Mock).mockResolvedValue({
        message: 'Provider unlinked successfully',
        providers: ['github', 'microsoft'],
      });

      const res = await request(app)
        .post('/auth/unlink')
        .send({ provider: 'google' })
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body.providers).toContain('github');
      expect(res.body.providers).not.toContain('google');
    });
  });

  describe('OAuth Provider Listing', () => {
    it('should list all linked OAuth providers', async () => {
      (oauthService.getLinkedProviders as jest.Mock).mockResolvedValue({
        providers: ['google', 'github', 'password'],
        linkedAt: {
          google: new Date(),
          github: new Date(),
        },
      });

      const res = await request(app)
        .get('/auth/providers')
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body.providers).toContain('google');
      expect(res.body.providers).toContain('github');
    });

    it('should show password authentication status', async () => {
      (oauthService.getLinkedProviders as jest.Mock).mockResolvedValue({
        providers: ['password'],
        hasPassword: true,
      });

      const res = await request(app)
        .get('/auth/providers')
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body.providers).toContain('password');
    });
  });

  describe('OAuth State Management', () => {
    it('should generate OAuth state token', async () => {
      const stateToken = 'state-token-' + Math.random().toString(36);

      const res = await request(app)
        .post('/auth/oauth-state')
        .expect(200);

      expect(res.body).toHaveProperty('stateToken');
      expect(res.body.stateToken).toBeTruthy();
    });

    it('should verify OAuth state before callback', async () => {
      (oauthService.verifyOAuthState as jest.Mock).mockResolvedValue(true);

      await request(app)
        .post('/auth/verify-oauth-state')
        .send({ state: 'valid-state-token' })
        .expect(200);

      expect(oauthService.verifyOAuthState).toHaveBeenCalled();
    });

    it('should reject invalid OAuth state', async () => {
      (oauthService.verifyOAuthState as jest.Mock).mockResolvedValue(false);

      await request(app)
        .post('/auth/verify-oauth-state')
        .send({ state: 'invalid-state' })
        .expect(400);
    });
  });

  describe('OAuth Error Scenarios', () => {
    it('should handle OAuth provider errors', async () => {
      (oauthService.handleOAuthLogin as jest.Mock).mockRejectedValue(
        new Error('OAuth provider error')
      );

      await request(app)
        .post('/auth/google')
        .send({ profile: { id: 'google-123' } })
        .expect(500);
    });

    it('should handle network errors during OAuth', async () => {
      (oauthService.handleOAuthLogin as jest.Mock).mockRejectedValue(
        new Error('Network timeout')
      );

      await request(app)
        .post('/auth/google')
        .send({ profile: { id: 'google-123' } })
        .expect(500);
    });

    it('should handle missing OAuth profile', async () => {
      await request(app)
        .post('/auth/google')
        .send({})
        .expect(400);
    });

    it('should handle OAuth callback errors', async () => {
      await request(app)
        .get('/auth/callback/google')
        .query({ error: 'access_denied' })
        .expect(400);
    });
  });

  describe('OAuth Concurrent Operations', () => {
    it('should handle concurrent OAuth logins from same provider', async () => {
      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
      });

      const profile = { id: 'google-123', emails: [{ value: mockEmail }] };

      const results = await Promise.all([
        request(app)
          .post('/auth/google')
          .send({ profile }),
        request(app)
          .post('/auth/google')
          .send({ profile }),
      ]);

      results.forEach((res) => {
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('user');
      });
    });

    it('should handle concurrent provider linking', async () => {
      (oauthService.linkOAuthProvider as jest.Mock).mockResolvedValue({
        _id: mockUserId,
      });

      const results = await Promise.all([
        request(app)
          .post('/auth/link')
          .send({ provider: 'google', profile: { id: 'google-123' } })
          .set('Authorization', `Bearer token`),
        request(app)
          .post('/auth/link')
          .send({ provider: 'github', profile: { id: 'github-123' } })
          .set('Authorization', `Bearer token`),
      ]);

      results.forEach((res) => {
        expect(res.status).toBe(200);
      });
    });
  });

  describe('OAuth Avatar Handling', () => {
    it('should extract and store avatar from OAuth profile', async () => {
      const profileWithAvatar = {
        id: 'google-123',
        displayName: 'John Doe',
        emails: [{ value: mockEmail }],
        photos: [{ value: 'https://provider.com/avatar.jpg' }],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        avatarUrl: profileWithAvatar.photos[0].value,
      });

      const res = await request(app)
        .post('/auth/google')
        .send({ profile: profileWithAvatar })
        .expect(200);

      expect(res.body.user).toHaveProperty('avatarUrl');
    });

    it('should handle profiles without avatar', async () => {
      const profileNoAvatar = {
        id: 'google-456',
        displayName: 'Jane Doe',
        emails: [{ value: 'jane@example.com' }],
        photos: [],
      };

      (oauthService.handleOAuthLogin as jest.Mock).mockResolvedValue({
        _id: new Types.ObjectId().toString(),
        email: 'jane@example.com',
        avatarUrl: null,
      });

      const res = await request(app)
        .post('/auth/google')
        .send({ profile: profileNoAvatar })
        .expect(200);

      expect(res.body.user).toHaveProperty('avatarUrl');
    });
  });

  describe('Authentication Requirements', () => {
    it('should require authentication for linking/unlinking', async () => {
      await request(app)
        .post('/auth/link')
        .send({ provider: 'google' })
        .expect(401);
    });

    it('should accept valid authentication tokens', async () => {
      (oauthService.linkOAuthProvider as jest.Mock).mockResolvedValue({
        _id: mockUserId,
      });

      const res = await request(app)
        .post('/auth/link')
        .send({ provider: 'google' })
        .set('Authorization', `Bearer valid-token`)
        .expect(200);

      expect(res.body).toBeDefined();
    });

    it('should reject invalid authentication tokens', async () => {
      await request(app)
        .post('/auth/link')
        .send({ provider: 'google' })
        .set('Authorization', `Bearer invalid-token`)
        .expect(401);
    });
  });
});
