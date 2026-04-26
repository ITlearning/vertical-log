import { NextResponse } from 'next/server';
import { z } from 'zod';

// TODO(sprint-1):
// - Verify Authorization: Bearer <jwt>
// - POST: create room { name } -> generate 6-char invite_code, insert rooms + room_members (owner)
// - Return { id, name, invite_code, member_count: 1 }

const CreateRoomBody = z.object({
  name: z.string().min(1).max(64),
});

export async function POST(req: Request) {
  const parsed = CreateRoomBody.safeParse(await req.json());
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_request', issues: parsed.error.format() },
      { status: 400 }
    );
  }

  return NextResponse.json({ error: 'not_implemented' }, { status: 501 });
}
