import { NextResponse } from 'next/server';
import { eq, and, desc, lt } from 'drizzle-orm';
import { db, clips, users, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';

const PAGE_SIZE = 50;

/**
 * GET /api/rooms/:id/feed[?before=ISO]
 *
 * Cursor-paginated clip timeline (member-only). snake_case JSON.
 */
export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  const { id: roomId } = await ctx.params;
  const url = new URL(req.url);
  const before = url.searchParams.get('before');
  const beforeDate = before ? new Date(before) : null;

  const [membership] = await db
    .select({ userId: roomMembers.userId })
    .from(roomMembers)
    .where(and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)))
    .limit(1);

  if (!membership) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const where = beforeDate
    ? and(eq(clips.roomId, roomId), lt(clips.capturedAt, beforeDate))
    : eq(clips.roomId, roomId);

  const result = await db
    .select({
      id: clips.id,
      room_id: clips.roomId,
      author_id: clips.authorId,
      author_display_name: users.displayName,
      blob_url: clips.blobUrl,
      duration_ms: clips.durationMs,
      captured_at: clips.capturedAt,
    })
    .from(clips)
    .innerJoin(users, eq(users.id, clips.authorId))
    .where(where)
    .orderBy(desc(clips.capturedAt))
    .limit(PAGE_SIZE);

  return NextResponse.json({
    clips: result,
    next_cursor: result.length === PAGE_SIZE ? result[result.length - 1].captured_at : null,
  });
}
