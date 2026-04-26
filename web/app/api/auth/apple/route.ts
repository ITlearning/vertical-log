import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db, users } from '@/lib/db';
import { verifyAppleIdentityToken } from '@/lib/auth/apple';
import { signSessionToken } from '@/lib/auth/jwt';
import { eq } from 'drizzle-orm';

// API JSON convention: snake_case (matches iOS APIClient encoder/decoder
// which is configured with convertToSnakeCase / convertFromSnakeCase).
const SignInBody = z.object({
  identity_token: z.string().min(1),
  authorization_code: z.string().optional(),
  full_name: z
    .object({
      given_name: z.string().nullable().optional(),
      family_name: z.string().nullable().optional(),
    })
    .optional(),
});

export async function POST(req: Request) {
  let parsed: z.infer<typeof SignInBody>;
  try {
    parsed = SignInBody.parse(await req.json());
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_request', message: error instanceof Error ? error.message : 'invalid' },
      { status: 400 }
    );
  }

  let identity;
  try {
    identity = await verifyAppleIdentityToken(parsed.identity_token);
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_token', message: error instanceof Error ? error.message : 'apple verify failed' },
      { status: 401 }
    );
  }

  // Display name: prefer full name from first sign-in, fallback "친구"
  const displayName =
    [parsed.full_name?.given_name, parsed.full_name?.family_name]
      .filter((s): s is string => !!s && s.trim().length > 0)
      .join(' ')
      .trim() || '친구';

  // Upsert user by apple_user_id
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.appleUserId, identity.appleUserId))
    .limit(1);

  let userId: string;
  let resolvedDisplayName: string;
  if (existing.length > 0) {
    userId = existing[0].id;
    resolvedDisplayName = existing[0].displayName;
  } else {
    const inserted = await db
      .insert(users)
      .values({
        appleUserId: identity.appleUserId,
        displayName,
      })
      .returning({ id: users.id, displayName: users.displayName });
    userId = inserted[0].id;
    resolvedDisplayName = inserted[0].displayName;
  }

  const jwt = await signSessionToken(userId);

  return NextResponse.json({
    jwt,
    user: {
      id: userId,
      display_name: resolvedDisplayName,
    },
  });
}
