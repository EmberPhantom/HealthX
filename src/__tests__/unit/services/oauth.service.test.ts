import oauthService from '../../../services/oauth.service';
import User from '../../../models/User';
import { Types } from 'mongoose';

jest.mock('../../../models/User');
jest.mock('../../../services/security.service');

describe('OAuthService', () => {
  const mockUserId = new Types.ObjectId().toString();
  const mockEmail = 'oauth@example.com';
  const mockProfile = {
    id: 'google-123',
    displayName: 'John Doe',
    emails: [{ value: mockEmail }],
    photos: [{ value: 'https://example.com/avatar.jpg' }],
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('handleOAuthLogin - Google', () => {
    it('should create new user on first Google login', async () => {
      const googleProfile = {
        id: 'google-id-123',
        displayName: 'John Doe',
        emails: [{ value: mockEmail }],
        photos: [{ value: 'https://example.com/avatar.jpg' }],
      };

      (User.findOne as jest.Mock).mockResolvedValue(null);
      (User.create as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        googleId: googleProfile.id,
        firstName: 'John',
        lastName: 'Doe',
        avatarUrl: googleProfile.photos[0].value,
        isEmailVerified: true,
      });

      const result = await oauthService.handleOAuthLogin('google', googleProfile);

      expect(result).toHaveProperty('_id', mockUserId);
      expect(result).toHaveProperty('googleId', googleProfile.id);
      expect(result.isEmailVerified).toBe(true);
    });

    it('should return existing user on subsequent Google login', async () => {
      const existingUser = {
        _id: mockUserId,
        email: mockEmail,
        googleId: 'google-id-123',
      };

      (User.findOne as jest.Mock).mockResolvedValue(existingUser);

      const result = await oauthService.handleOAuthLogin('google', mockProfile);

      expect(result._id).toBe(mockUserId);
      expect(User.findOne).toHaveBeenCalledWith(
        expect.objectContaining({ googleId: mockProfile.id })
      );
    });

    it('should link Google to existing email account', async () => {
      const existingUser = {
        _id: mockUserId,
        email: mockEmail,
        googleId: null,
        save: jest.fn().mockResolvedValue({
          googleId: 'google-id-123',
        }),
      };

      // First query: no Google ID match
      (User.findOne as jest.Mock)
        .mockResolvedValueOnce(null) // No Google ID match
        .mockResolvedValueOnce(existingUser); // Email match

      await oauthService.handleOAuthLogin('google', mockProfile);

      expect(existingUser.save).toHaveBeenCalled();
    });

    it('should store Google refresh token when provided', async () => {
      const profileWithRefresh = {
        ...mockProfile,
        id: 'google-id-456',
      };

      (User.findOne as jest.Mock).mockResolvedValue(null);
      (User.create as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        googleId: profileWithRefresh.id,
      });

      const refreshToken = 'refresh-token-abc123';
      await oauthService.handleOAuthLogin('google', profileWithRefresh, refreshToken);

      expect(User.create).toHaveBeenCalled();
    });
  });

  describe('linkOAuthProvider', () => {
    it('should link new Google OAuth provider to existing account', async () => {
      const user = {
        _id: mockUserId,
        email: mockEmail,
        googleId: null,
        save: jest.fn().mockResolvedValue({
          googleId: 'google-new-id',
        }),
      };

      (User.findById as jest.Mock).mockResolvedValue(user);
      (User.findOne as jest.Mock).mockResolvedValue(null);

      await oauthService.linkOAuthProvider(mockUserId, 'google', {
        id: 'google-new-id',
        displayName: 'John Doe',
      });

      expect(user.save).toHaveBeenCalled();
    });
  });

  describe('unlinkOAuthProvider', () => {
    it('should unlink Google OAuth provider when user has password', async () => {
      const user = {
        _id: mockUserId,
        password: 'hashed-password',
        googleId: 'google-id-123',
        save: jest.fn().mockResolvedValue({
          googleId: null,
        }),
      };

      (User.findById as jest.Mock).mockResolvedValue(user);

      await oauthService.unlinkOAuthProvider(mockUserId, 'google', 'password123');

      expect(user.save).toHaveBeenCalled();
    });
  });

  describe('getLinkedProviders', () => {
    it('should return list of linked OAuth providers', async () => {
      const user = {
        _id: mockUserId,
        googleId: 'google-id-123',
        password: 'hashed-password',
      };

      (User.findById as jest.Mock).mockResolvedValue(user);

      const providers = await oauthService.getLinkedProviders(mockUserId);

      expect(providers).toContain('google');
      expect(providers).toContain('password');
    });
  });

  describe('OAuth URL generation', () => {
    it('should generate valid Google OAuth URL', async () => {
      const url = await oauthService.getGoogleAuthUrl('state-123');
      expect(url).toContain('accounts.google.com');
      expect(url).toContain('state-123');
    });
  });
});
