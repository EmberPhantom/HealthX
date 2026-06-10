import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { config } from './config';
import oauthService from '../services/oauth.service';
import User from '../models/User';

// NOTE: GitHub and Microsoft strategies have been removed.
// The app now only supports Google OAuth for social login.
// For mobile clients, we use ID token verification (not passport callbacks).
// Passport is kept only in case we add web OAuth callback routes in future.

if (config.google.clientId && config.google.clientSecret) {
  passport.use(
    new GoogleStrategy(
      {
        clientID: config.google.clientId,
        clientSecret: config.google.clientSecret,
        callbackURL: config.google.callbackUrl,
        passReqToCallback: true,
      },
      async (req, accessToken, refreshToken, profile, done) => {
        try {
          const result = await oauthService.handleOAuthLogin(
            'google',
            {
              id: profile.id,
              displayName: profile.displayName,
              emails: profile.emails,
              photos: profile.photos,
            },
            accessToken,
            refreshToken
          );
          return done(null, result.user);
        } catch (error) {
          return done(error as Error, undefined);
        }
      }
    )
  );
}

// We don't use sessions (JWT-based auth)
passport.serializeUser((user: any, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

export default passport;
