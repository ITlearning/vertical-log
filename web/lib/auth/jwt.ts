import { SignJWT, jwtVerify, type JWTPayload } from 'jose';

const ISSUER = 'vertical-log';
const SESSION_TTL = '30d';

function getSecret(): Uint8Array {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET is not set');
  return new TextEncoder().encode(secret);
}

/**
 * Sign a session JWT for our app. The iOS client stores this in Keychain
 * and sends it in `Authorization: Bearer <jwt>` headers.
 */
export async function signSessionToken(userId: string): Promise<string> {
  return new SignJWT({})
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setIssuer(ISSUER)
    .setSubject(userId)
    .setExpirationTime(SESSION_TTL)
    .sign(getSecret());
}

/**
 * Verify a session JWT. Throws on invalid/expired/wrong-issuer tokens.
 * Returns the user ID (`sub` claim).
 */
export async function verifySessionToken(token: string): Promise<string> {
  const { payload } = await jwtVerify<JWTPayload>(token, getSecret(), {
    issuer: ISSUER,
  });
  if (typeof payload.sub !== 'string') {
    throw new Error('JWT missing sub claim');
  }
  return payload.sub;
}
