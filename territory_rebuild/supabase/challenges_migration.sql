CREATE TABLE IF NOT EXISTS challenges (
  id              TEXT PRIMARY KEY,
  challenger_id   UUID NOT NULL REFERENCES profiles(id),
  challenger_name TEXT NOT NULL,
  challenged_id   UUID NOT NULL REFERENCES profiles(id),
  challenged_name TEXT NOT NULL,
  status          TEXT DEFAULT 'pending',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "challenges_all" ON challenges FOR ALL USING (
  auth.uid() = challenger_id OR auth.uid() = challenged_id
);
CREATE POLICY "challenges_insert" ON challenges FOR INSERT WITH CHECK (
  auth.uid() = challenger_id
);
