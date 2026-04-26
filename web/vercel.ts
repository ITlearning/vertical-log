import { type VercelConfig, routes } from '@vercel/config/v1';

export const config: VercelConfig = {
  framework: 'nextjs',
  buildCommand: 'next build',
  installCommand: 'npm install',
  // Sprint 2: enable cron job for daily compile pipeline (00:00 KST)
  // crons: [{ path: '/api/cron/compile', schedule: '0 15 * * *' }],  // 15:00 UTC = 00:00 KST
  headers: [
    routes.cacheControl('/api/(.*)', {
      public: false,
      noStore: true,
    }),
  ],
};
