import { createRemoteJWKSet, jwtVerify } from 'jose';

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_JWKS_URL = new URL('https://appleid.apple.com/auth/keys');

// Module-level cache: jose's createRemoteJWKSet caches keys with sane TTL.
const jwks = createRemoteJWKSet(APPLE_JWKS_URL);

export interface AppleIdentity {
  /** Apple's stable per-app user ID. Use as users.apple_user_id. */
  appleUserId: string;
  email?: string;
  emailVerified?: boolean;
  isPrivateRelay?: boolean;
}

/**
 * Verify a Sign in with Apple identity token (JWT) from the iOS client.
 *
 * Validates: signature against Apple JWKS, issuer, audience (our bundle ID),
 * and expiry. Throws on any failure.
 */
export async function verifyAppleIdentityToken(token: string): Promise<AppleIdentity> {
  const audience = process.env.APPLE_CLIENT_ID;
  if (!audience) throw new Error('APPLE_CLIENT_ID is not set');

  const { payload } = await jwtVerify(token, jwks, {
    issuer: APPLE_ISSUER,
    audience,
  });

  if (typeof payload.sub !== 'string') {
    throw new Error('Apple identity token missing sub claim');
  }

  const email = typeof payload.email === 'string' ? payload.email : undefined;
  const emailVerified =
    payload.email_verified === true || payload.email_verified === 'true';
  const isPrivateRelay =
    payload.is_private_email === true || payload.is_private_email === 'true';

  return {
    appleUserId: payload.sub,
    email,
    emailVerified,
    isPrivateRelay,
  };
}
