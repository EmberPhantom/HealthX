import path from 'path';
import fs from 'fs';
import { config } from '../config/config';

// Define log levels
type LogLevel = 'error' | 'warn' | 'info' | 'http' | 'debug';

const levels: Record<LogLevel, number> = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

class Logger {
  private logDir = path.join(process.cwd(), 'logs');

  constructor() {
    this.ensureLogDir();
  }

  private ensureLogDir(): void {
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  private formatMessage(level: LogLevel, ...args: any[]): string {
    const timestamp = new Date().toISOString();
    const message = args
      .map((arg: any) => {
        if (typeof arg === 'string') return arg;
        if (arg instanceof Error) return arg.message + '\n' + arg.stack;
        return JSON.stringify(arg, null, 2);
      })
      .join(' ');
    return `${timestamp} [${level.toUpperCase()}]: ${message}`;
  }

  private writeToFile(level: LogLevel, ...args: any[]): void {
    const formatted = this.formatMessage(level, ...args);
    const dateStr = new Date().toISOString().split('T')[0];
    
    // Non-blocking async write to daily combined log
    const combinedLogPath = path.join(this.logDir, `combined-${dateStr}.log`);
    fs.appendFile(combinedLogPath, formatted + '\n', (err) => {
      if (err) console.error('Failed to write to combined log:', err);
    });

    // Non-blocking async write to daily error log
    if (level === 'error') {
      const errorLogPath = path.join(this.logDir, `error-${dateStr}.log`);
      fs.appendFile(errorLogPath, formatted + '\n', (err) => {
        if (err) console.error('Failed to write to error log:', err);
      });
    }
  }

  private log(level: LogLevel, ...args: any[]): void {
    const configLevel = config.logLevel as LogLevel;
    if (levels[level] > levels[configLevel]) {
      return;
    }

    const formatted = this.formatMessage(level, ...args);

    // Console output
    const colors: Record<LogLevel, string> = {
      error: '\x1b[31m', // Red
      warn: '\x1b[33m', // Yellow
      info: '\x1b[32m', // Green
      http: '\x1b[35m', // Magenta
      debug: '\x1b[37m', // White
    };
    const reset = '\x1b[0m';

    if (config.env === 'development') {
      const color = colors[level];
      console.log(`${color}${formatted}${reset}`);
    } else {
      console.log(formatted);
    }

    // Write to files
    this.writeToFile(level, ...args);
  }

  error(...args: any[]): void {
    this.log('error', ...args);
  }

  warn(...args: any[]): void {
    this.log('warn', ...args);
  }

  info(...args: any[]): void {
    this.log('info', ...args);
  }

  http(...args: any[]): void {
    this.log('http', ...args);
  }

  debug(...args: any[]): void {
    this.log('debug', ...args);
  }
}

const logger = new Logger();

export default logger;
