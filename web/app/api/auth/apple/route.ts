import { NextResponse } from 'next/server';
import { z } from 'zod';

// TODO(sprint-1): full Sign in with Apple verification
// 1. Receive { identityToken, authorizationCode, fullName? } from iOS client
// 2. Verify identityToken against Apple JWKS (https://appleid.apple.com/auth/keys)
//    - Validate audience (APPLE_CLIENT_ID), issuer, expiry
//    - Use jose library: jose.jwtVerify with JWKSet
// 3. Extract sub (Apple user ID — stable per app+team)
// 4. Upsert into users table by apple_user_id
// 5. Sign our own JWT (jose.SignJWT with JWT_SECRET) for the iOS client
// 6. Return { jwt, user: { id, displayName } }

const SignInBody = z.object({
  identityToken: z.string(),
  authorizationCode: z.string().optional(),
  fullName: z
    .object({
      givenName: z.string().nullable(),
      familyName: z.string().nullable(),
    })
    .optional(),
});

export async function POST(req: Request) {
  const parsed = SignInBody.safeParse(await req.json());
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_request', issues: parsed.error.format() },
      { status: 400 }
    );
  }

  // STUB — wire to Apple JWKS + DB upsert in sprint 1
  return NextResponse.json(
    { error: 'not_implemented' },
    { status: 501 }
  );
}
