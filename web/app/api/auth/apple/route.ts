import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db, users } from '@/lib/db';
import { verifyAppleIdentityToken } from '@/lib/auth/apple';
import { signSessionToken } from '@/lib/auth/jwt';
import { eq } from 'drizzle-orm';

const SignInBody = z.object({
  identityToken: z.string().min(1),
  authorizationCode: z.string().optional(),
  fullName: z
    .object({
      givenName: z.string().nullable().optional(),
      familyName: z.string().nullable().optional(),
    })
    .optional(),
});

export async function POST(req: Request) {
  let body: z.infer<typeof SignInBody>;
  try {
    body = SignInBody.parse(await req.json());
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_request', message: error instanceof Error ? error.message : 'invalid' },
      { status: 400 }
    );
  }

  // 1. Verify Apple identity token against Apple JWKS
  let identity;
  try {
    identity = await verifyAppleIdentityToken(body.identityToken);
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_token', message: error instanceof Error ? error.message : 'apple verify failed' },
      { status: 401 }
    );
  }

  // 2. Build display name: prefer full name from first sign-in, fallback "친구"
  const displayName =
    [body.fullName?.givenName, body.fullName?.familyName]
      .filter((s): s is string => !!s && s.trim().length > 0)
      .join(' ')
      .trim() || '친구';

  // 3. Upsert user by apple_user_id
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.appleUserId, identity.appleUserId))
    .limit(1);

  let userId: string;
  if (existing.length > 0) {
    userId = existing[0].id;
  } else {
    const inserted = await db
      .insert(users)
      .values({
        appleUserId: identity.appleUserId,
        displayName,
      })
      .returning({ id: users.id });
    userId = inserted[0].id;
  }

  // 4. Sign our app's session JWT
  const jwt = await signSessionToken(userId);

  return NextResponse.json({
    jwt,
    user: {
      id: userId,
      displayName: existing[0]?.displayName ?? displayName,
    },
  });
}
