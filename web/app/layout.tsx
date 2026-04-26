import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'vertical-log',
  description: '일상은 세로로.',
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
