import { NextResponse } from 'next/server';
import { verifySessionToken } from './jwt';

export class UnauthorizedError extends Error {
  constructor(message = 'unauthorized') {
    super(message);
    this.name = 'UnauthorizedError';
  }
}

/**
 * Resolve the current user ID from the Authorization header, or throw
 * UnauthorizedError if missing/invalid.
 */
export async function requireUserId(req: Request): Promise<string> {
  const auth = req.headers.get('authorization') ?? req.headers.get('Authorization');
  if (!auth?.startsWith('Bearer ')) {
    throw new UnauthorizedError('missing bearer token');
  }
  const token = auth.slice('Bearer '.length).trim();
  if (!token) throw new UnauthorizedError('empty bearer token');

  try {
    return await verifySessionToken(token);
  } catch (error) {
    throw new UnauthorizedError(
      error instanceof Error ? `invalid token: ${error.message}` : 'invalid token'
    );
  }
}

/**
 * Helper for route handlers: returns 401 NextResponse on unauth, otherwise
 * resolves with the userId.
 */
export async function authOr401(
  req: Request
): Promise<{ userId: string } | NextResponse> {
  try {
    const userId = await requireUserId(req);
    return { userId };
  } catch (error) {
    return NextResponse.json(
      {
        error: 'unauthorized',
        message: error instanceof Error ? error.message : 'unauthorized',
      },
      { status: 401 }
    );
  }
}
