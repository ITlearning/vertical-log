import { NextResponse } from 'next/server';
import { eq, and, count } from 'drizzle-orm';
import { db, rooms, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';

/**
 * GET /api/rooms/:id — room detail (member-only). snake_case JSON.
 */
export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  const { id: roomId } = await ctx.params;

  const [membership] = await db
    .select({ role: roomMembers.role })
    .from(roomMembers)
    .where(and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)))
    .limit(1);

  if (!membership) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const [room] = await db.select().from(rooms).where(eq(rooms.id, roomId)).limit(1);
  if (!room) {
    return NextResponse.json({ error: 'not_found' }, { status: 404 });
  }

  const [{ value: memberCount }] = await db
    .select({ value: count() })
    .from(roomMembers)
    .where(eq(roomMembers.roomId, roomId));

  return NextResponse.json({
    id: room.id,
    name: room.name,
    invite_code: room.inviteCode,
    member_cap: room.memberCap,
    member_count: memberCount,
    role: membership.role,
    created_at: room.createdAt,
  });
}
