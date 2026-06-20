import crypto from 'crypto';

console.log('================================================================');
console.log('🔒 SECURE SECRET KEY GENERATOR FOR PRODUCTION');
console.log('================================================================\n');

const jwtSecret = crypto.randomBytes(64).toString('hex');
const jwtRefreshSecret = crypto.randomBytes(64).toString('hex');

console.log('🔑 JWT_SECRET:');
console.log(jwtSecret);
console.log('\n🔄 JWT_REFRESH_SECRET:');
console.log(jwtRefreshSecret);
console.log('\n================================================================');
console.log('⚠️  ACTION REQUIRED:');
console.log('Copy these values into your production environment config (.env).');
console.log('Keep these keys highly confidential and secure!');
console.log('================================================================');
