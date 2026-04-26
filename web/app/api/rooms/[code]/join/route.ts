import { NextResponse } from 'next/server';

// TODO(sprint-1):
// - Verify Authorization: Bearer <jwt>
// - Look up room by invite_code (case-insensitive lookup)
// - If not found: 404
// - If member_cap exceeded: 409
// - If already member: 200 (idempotent)
// - Insert room_members row, return { room_id, member_count }

export async function POST(
  _req: Request,
  ctx: { params: Promise<{ code: string }> }
) {
  const { code } = await ctx.params;
  if (code.length !== 6) {
    return NextResponse.json({ error: 'invalid_code_length' }, { status: 400 });
  }
  return NextResponse.json({ error: 'not_implemented' }, { status: 501 });
}
