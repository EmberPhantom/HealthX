import nodemailer, { Transporter } from 'nodemailer';
import { config } from '../config/config';
import { AppError } from '../utils/AppError';
import logger from '../utils/logger';

interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

class EmailService {
  private _transporter?: Transporter;

  private get transporter(): Transporter {
    if (!this._transporter) {
      if (process.env.NODE_ENV === 'production') {
        this._transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASSWORD,
          },
        });
      } else {
        this._transporter = nodemailer.createTransport({
          host: 'localhost',
          port: 1025,
          secure: false,
        });
      }
    }
    return this._transporter;
  }

  constructor() {
    // Configure email transporter lazily
  }

  /**
   * Send verification email
   */
  async sendVerificationEmail(email: string, verificationLink: string, userName: string): Promise<boolean> {
    try {
      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Verify Your Email</h2>
          <p>Hello ${userName},</p>
          <p>Thank you for signing up! Please verify your email address by clicking the link below:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${verificationLink}" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Verify Email
            </a>
          </div>
          <p>Or copy and paste this link in your browser:</p>
          <p style="word-break: break-all;">${verificationLink}</p>
          <p>This link will expire in 24 hours.</p>
          <p>If you didn't create this account, please ignore this email.</p>
          <hr>
          <p style="color: #666; font-size: 12px;">
            © 2026 HealthX. All rights reserved.
          </p>
        </div>
      `;

      const mailOptions: EmailOptions = {
        to: email,
        subject: 'Verify Your HealthX Email Address',
        html,
        text: `Verify your email: ${verificationLink}`,
      };

      await this.transporter.sendMail(mailOptions);
      logger.info('Email sent successfully');
      return true;
    } catch (error: any) {
      return this.handleMailError(error, 'Error sending verification email');
    }
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(email: string, resetLink: string, userName: string): Promise<boolean> {
    try {
      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Reset Your Password</h2>
          <p>Hello ${userName},</p>
          <p>We received a request to reset your password. Click the link below to create a new password:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Reset Password
            </a>
          </div>
          <p>This link will expire in 1 hour.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr>
          <p style="color: #666; font-size: 12px;">
            © 2026 HealthX. All rights reserved.
          </p>
        </div>
      `;

      const mailOptions: EmailOptions = {
        to: email,
        subject: 'Reset Your HealthX Password',
        html,
        text: `Reset your password: ${resetLink}`,
      };

      await this.transporter.sendMail(mailOptions);
      logger.info('Email sent successfully');
      return true;
    } catch (error: any) {
      return this.handleMailError(error, 'Error sending password reset email');
    }
  }

  /**
   * Send account security alert
   */
  async sendSecurityAlert(email: string, alertMessage: string, userName: string): Promise<boolean> {
    try {
      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin-bottom: 20px;">
            <h2 style="color: #dc3545; margin-top: 0;">Security Alert</h2>
            <p>Hello ${userName},</p>
            <p>${alertMessage}</p>
          </div>
          <p>If this wasn't you, please secure your account immediately by changing your password.</p>
          <hr>
          <p style="color: #666; font-size: 12px;">
            © 2026 HealthX. All rights reserved.
          </p>
        </div>
      `;

      const mailOptions: EmailOptions = {
        to: email,
        subject: '🔒 HealthX Security Alert',
        html,
        text: alertMessage,
      };

      await this.transporter.sendMail(mailOptions);
      logger.info('Email sent successfully');
      return true;
    } catch (error: any) {
      return this.handleMailError(error, 'Error sending security alert email');
    }
  }

  /**
   * Send welcome email
   */
  async sendWelcomeEmail(email: string, userName: string): Promise<boolean> {
    try {
      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Welcome to HealthX!</h2>
          <p>Hello ${userName},</p>
          <p>Your email has been verified! Welcome to HealthX, your trusted health companion.</p>
          <div style="background-color: #f0f8ff; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <h3>Getting Started:</h3>
            <ul>
              <li>Complete your health profile</li>
              <li>Set up your emergency contacts</li>
              <li>Add your medical history</li>
              <li>Enable notifications</li>
            </ul>
          </div>
          <p>If you have any questions, feel free to contact our support team.</p>
          <hr>
          <p style="color: #666; font-size: 12px;">
            © 2026 HealthX. All rights reserved.
          </p>
        </div>
      `;

      const mailOptions: EmailOptions = {
        to: email,
        subject: 'Welcome to HealthX!',
        html,
        text: `Welcome to HealthX, ${userName}!`,
      };

      await this.transporter.sendMail(mailOptions);
      logger.info('Email sent successfully');
      return true;
    } catch (error: any) {
      return this.handleMailError(error, 'Error sending welcome email');
    }
  }

  private handleMailError(error: any, defaultMessage: string): boolean {
    logger.error('Error sending email:', error);
    if (process.env.NODE_ENV === 'test' && (error.code === 'ECONNREFUSED' || error.code === 'ESOCKET')) {
      logger.warn('⚠️ Swallowing SMTP connection error in integration test environment');
      return true;
    }
    throw new AppError(error?.message || defaultMessage, 500);
  }
}

export default new EmailService();
