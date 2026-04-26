import { NextResponse } from 'next/server';
import { eq, and, desc, lt } from 'drizzle-orm';
import { db, clips, users, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';

const PAGE_SIZE = 50;

/**
 * GET /api/rooms/:id/feed
 *
 * Returns clips for a room sorted by captured_at DESC. Caller must be a member.
 * Pagination: pass `?before=<iso-timestamp>` to fetch the next page.
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

  // Membership check
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
      roomId: clips.roomId,
      authorId: clips.authorId,
      authorDisplayName: users.displayName,
      blobUrl: clips.blobUrl,
      durationMs: clips.durationMs,
      capturedAt: clips.capturedAt,
    })
    .from(clips)
    .innerJoin(users, eq(users.id, clips.authorId))
    .where(where)
    .orderBy(desc(clips.capturedAt))
    .limit(PAGE_SIZE);

  return NextResponse.json({
    clips: result,
    nextCursor: result.length === PAGE_SIZE ? result[result.length - 1].capturedAt : null,
  });
}
