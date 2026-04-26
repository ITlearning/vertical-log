/**
 * Invite code generation. 6 characters, uppercase + digits, with ambiguous
 * characters (0, O, 1, I, L) removed for human readability.
 *
 * Alphabet size: 32 → 6 chars = 32^6 ≈ 1.07 billion combinations.
 * UNIQUE index on rooms.invite_code catches the rare collision; caller retries.
 */

const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // 31 chars (also dropped L)
const DEFAULT_LENGTH = 6;
const DEFAULT_MAX_ATTEMPTS = 5;

export function generateInviteCode(length: number = DEFAULT_LENGTH): string {
  if (length <= 0) throw new Error('invite code length must be positive');

  const bytes = crypto.getRandomValues(new Uint8Array(length));
  let code = '';
  for (let i = 0; i < length; i++) {
    code += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return code;
}

/**
 * Generate a unique invite code by retrying on collision. The `isAvailable`
 * predicate should query the database (e.g. `SELECT 1 WHERE invite_code=$1`).
 */
export async function generateUniqueInviteCode(
  isAvailable: (code: string) => Promise<boolean>,
  options: { length?: number; maxAttempts?: number } = {}
): Promise<string> {
  const length = options.length ?? DEFAULT_LENGTH;
  const max = options.maxAttempts ?? DEFAULT_MAX_ATTEMPTS;

  for (let attempt = 0; attempt < max; attempt++) {
    const code = generateInviteCode(length);
    if (await isAvailable(code)) return code;
  }
  throw new Error(`failed to generate unique invite code after ${max} attempts`);
}

export const INVITE_CODE_ALPHABET = ALPHABET;
export const INVITE_CODE_LENGTH = DEFAULT_LENGTH;
