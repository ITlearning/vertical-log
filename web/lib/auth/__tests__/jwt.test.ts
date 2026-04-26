import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { signSessionToken, verifySessionToken } from '../jwt';

const ORIGINAL_SECRET = process.env.JWT_SECRET;

beforeAll(() => {
  process.env.JWT_SECRET = 'test-secret-for-vitest-must-be-long-enough-1234567890';
});

afterAll(() => {
  if (ORIGINAL_SECRET === undefined) {
    delete process.env.JWT_SECRET;
  } else {
    process.env.JWT_SECRET = ORIGINAL_SECRET;
  }
});

describe('JWT round-trip', () => {
  it('sign + verify returns the original userId', async () => {
    const userId = 'user-abc-123';
    const token = await signSessionToken(userId);
    const verified = await verifySessionToken(token);
    expect(verified).toBe(userId);
  });

  it('rejects token signed with a different secret', async () => {
    const token = await signSessionToken('user-1');
    process.env.JWT_SECRET = 'a-different-secret-that-is-long-enough-9876543210';
    await expect(verifySessionToken(token)).rejects.toThrow();
    process.env.JWT_SECRET = 'test-secret-for-vitest-must-be-long-enough-1234567890';
  });

  it('rejects malformed tokens', async () => {
    await expect(verifySessionToken('not-a-jwt')).rejects.toThrow();
  });
});
