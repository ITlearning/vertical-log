export default function Page() {
  return (
    <main
      style={{
        display: 'flex',
        minHeight: '100vh',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 8,
        fontFamily: 'system-ui, -apple-system, sans-serif',
        backgroundColor: '#0A0A0A',
        color: '#DDDDDD',
      }}
    >
      <h1 style={{ fontSize: 32, fontWeight: 700 }}>vertical-log</h1>
      <p style={{ color: '#888888' }}>일상은 세로로.</p>
      <p style={{ marginTop: 24, fontSize: 12, color: '#555555' }}>
        Sprint 1 in progress · iOS TestFlight only
      </p>
    </main>
  );
}
