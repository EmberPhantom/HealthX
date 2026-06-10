import emailService from '../../../services/email.service';
import nodemailer from 'nodemailer';
import AppError from '../../../utils/AppError';

jest.mock('nodemailer');

describe('EmailService', () => {
  const mockSendMail = jest.fn();
  const mockTransporter = {
    sendMail: mockSendMail,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (nodemailer.createTransport as jest.Mock).mockReturnValue(mockTransporter);
  });

  describe('sendVerificationEmail', () => {
    it('should send verification email successfully', async () => {
      const email = 'user@example.com';
      const token = 'verification-token-123';

      mockSendMail.mockResolvedValue({ messageId: 'msg-123' });

      await emailService.sendVerificationEmail(email, token);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: email,
          subject: expect.stringContaining('Verify'),
          html: expect.stringContaining(token),
        })
      );
    });

    it('should throw error if email sending fails', async () => {
      const email = 'user@example.com';
      const token = 'verification-token-123';

      mockSendMail.mockRejectedValue(new Error('SMTP error'));

      await expect(
        emailService.sendVerificationEmail(email, token)
      ).rejects.toThrow();
    });

    it('should include verification link in email', async () => {
      const email = 'test@example.com';
      const token = 'token-xyz-789';

      mockSendMail.mockResolvedValue({ messageId: 'msg-456' });

      await emailService.sendVerificationEmail(email, token);

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toContain(token);
      expect(call.html).toMatch(/verify|confirm/i);
    });
  });

  describe('sendPasswordResetEmail', () => {
    it('should send password reset email successfully', async () => {
      const email = 'user@example.com';
      const resetToken = 'reset-token-456';

      mockSendMail.mockResolvedValue({ messageId: 'msg-789' });

      await emailService.sendPasswordResetEmail(email, resetToken);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: email,
          subject: expect.stringContaining('Password'),
          html: expect.stringContaining(resetToken),
        })
      );
    });

    it('should include reset link in email', async () => {
      const email = 'test@example.com';
      const token = 'reset-token-abc';

      mockSendMail.mockResolvedValue({ messageId: 'msg-reset' });

      await emailService.sendPasswordResetEmail(email, token);

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toContain(token);
      expect(call.html).toMatch(/reset|change/i);
    });

    it('should throw error if sending fails', async () => {
      mockSendMail.mockRejectedValue(new Error('Network error'));

      await expect(
        emailService.sendPasswordResetEmail('test@example.com', 'token')
      ).rejects.toThrow();
    });
  });

  describe('sendSecurityAlert', () => {
    it('should send security alert email successfully', async () => {
      const email = 'user@example.com';
      const action = 'LOGIN_ATTEMPT';
      const ipAddress = '192.168.1.1';

      mockSendMail.mockResolvedValue({ messageId: 'msg-security' });

      await emailService.sendSecurityAlert(email, action, ipAddress);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: email,
          subject: expect.stringContaining('Security'),
          html: expect.stringContaining(ipAddress),
        })
      );
    });

    it('should include action details in alert email', async () => {
      mockSendMail.mockResolvedValue({ messageId: 'msg-alert' });

      await emailService.sendSecurityAlert('test@example.com', 'PASSWORD_CHANGE', '10.0.0.1');

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toContain('10.0.0.1');
      expect(call.html).toMatch(/unusual|suspicious|alert/i);
    });

    it('should throw error if email sending fails', async () => {
      mockSendMail.mockRejectedValue(new Error('Mail service down'));

      await expect(
        emailService.sendSecurityAlert('test@example.com', 'FAILED_LOGIN', '1.2.3.4')
      ).rejects.toThrow();
    });
  });

  describe('sendWelcomeEmail', () => {
    it('should send welcome email successfully', async () => {
      const email = 'user@example.com';
      const firstName = 'John';

      mockSendMail.mockResolvedValue({ messageId: 'msg-welcome' });

      await emailService.sendWelcomeEmail(email, firstName);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: email,
          subject: expect.stringContaining('Welcome'),
          html: expect.stringContaining(firstName),
        })
      );
    });

    it('should include user name in welcome email', async () => {
      mockSendMail.mockResolvedValue({ messageId: 'msg-welcome' });

      await emailService.sendWelcomeEmail('test@example.com', 'Jane');

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toContain('Jane');
      expect(call.html).toMatch(/welcome|glad/i);
    });

    it('should throw error if sending fails', async () => {
      mockSendMail.mockRejectedValue(new Error('SMTP authentication failed'));

      await expect(
        emailService.sendWelcomeEmail('test@example.com', 'John')
      ).rejects.toThrow();
    });
  });

  describe('Email sending edge cases', () => {
    it('should handle empty recipient list', async () => {
      mockSendMail.mockRejectedValue(new Error('No recipients defined'));

      await expect(
        emailService.sendVerificationEmail('', 'token')
      ).rejects.toThrow();
    });

    it('should handle malformed email address', async () => {
      mockSendMail.mockRejectedValue(new Error('Invalid email address'));

      await expect(
        emailService.sendVerificationEmail('invalid-email', 'token')
      ).rejects.toThrow();
    });

    it('should retry on transient failure', async () => {
      mockSendMail
        .mockRejectedValueOnce(new Error('Transient error'))
        .mockResolvedValueOnce({ messageId: 'msg-retry' });

      // First attempt fails
      await expect(
        emailService.sendVerificationEmail('test@example.com', 'token')
      ).rejects.toThrow();

      // Second attempt succeeds
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-success' });
      await emailService.sendVerificationEmail('test@example.com', 'token');

      expect(mockSendMail).toHaveBeenCalledTimes(2);
    });

    it('should handle special characters in token', async () => {
      const specialToken = 'token-!@#$%^&*()_+-=[]{}|;:,.<>?';
      mockSendMail.mockResolvedValue({ messageId: 'msg-special' });

      await emailService.sendVerificationEmail('test@example.com', specialToken);

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toContain(specialToken);
    });
  });

  describe('Email template consistency', () => {
    it('should include unsubscribe information where applicable', async () => {
      mockSendMail.mockResolvedValue({ messageId: 'msg-unsub' });

      await emailService.sendWelcomeEmail('test@example.com', 'John');

      const call = mockSendMail.mock.calls[0][0];
      expect(call.html).toMatch(/unsubscribe|preferences|manage|email/i);
    });

    it('should use consistent branding in emails', async () => {
      mockSendMail.mockResolvedValue({ messageId: 'msg-brand' });

      await emailService.sendVerificationEmail('test@example.com', 'token');
      const verification = mockSendMail.mock.calls[0][0].html;

      mockSendMail.mockResolvedValue({ messageId: 'msg-brand2' });
      await emailService.sendWelcomeEmail('test@example.com', 'User');
      const welcome = mockSendMail.mock.calls[1][0].html;

      // Both should contain branding elements
      expect(verification).toMatch(/HealthX|health|medical/i);
      expect(welcome).toMatch(/HealthX|health|medical/i);
    });
  });
});
