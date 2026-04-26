import { describe, it, expect } from 'vitest';
import {
  generateInviteCode,
  generateUniqueInviteCode,
  INVITE_CODE_ALPHABET,
  INVITE_CODE_LENGTH,
} from '../inviteCode';

describe('generateInviteCode', () => {
  it('returns a string of the requested length', () => {
    const code = generateInviteCode();
    expect(code).toHaveLength(INVITE_CODE_LENGTH);
  });

  it('uses only allowed alphabet characters', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateInviteCode();
      for (const ch of code) {
        expect(INVITE_CODE_ALPHABET).toContain(ch);
      }
    }
  });

  it('does not contain ambiguous characters (0, O, 1, I, L)', () => {
    expect(INVITE_CODE_ALPHABET).not.toMatch(/[0O1IL]/);
  });

  it('produces non-trivially different outputs', () => {
    const codes = new Set<string>();
    for (let i = 0; i < 100; i++) codes.add(generateInviteCode());
    // 100 random 6-char codes should almost never repeat (entropy ~32^6).
    expect(codes.size).toBeGreaterThanOrEqual(99);
  });

  it('throws on non-positive length', () => {
    expect(() => generateInviteCode(0)).toThrow();
    expect(() => generateInviteCode(-1)).toThrow();
  });
});

describe('generateUniqueInviteCode', () => {
  it('returns the first available code', async () => {
    const code = await generateUniqueInviteCode(async () => true);
    expect(code).toHaveLength(INVITE_CODE_LENGTH);
  });

  it('retries on collision and eventually returns a unique code', async () => {
    let calls = 0;
    const code = await generateUniqueInviteCode(async () => {
      calls += 1;
      return calls >= 3; // first 2 codes "taken", 3rd available
    });
    expect(calls).toBe(3);
    expect(code).toHaveLength(INVITE_CODE_LENGTH);
  });

  it('throws after maxAttempts of collisions', async () => {
    await expect(
      generateUniqueInviteCode(async () => false, { maxAttempts: 3 })
    ).rejects.toThrow(/3 attempts/);
  });
});
