-- ============================================================
-- TerritoryApp — Hotspots + Batalhas de Temporada
-- Execute no SQL Editor do Supabase
-- ============================================================

-- 1. HOTSPOTS
CREATE TABLE IF NOT EXISTS hotspots (
  id                    TEXT PRIMARY KEY,
  name                  TEXT NOT NULL,
  lat                   FLOAT NOT NULL,
  lng                   FLOAT NOT NULL,
  type                  TEXT NOT NULL DEFAULT 'doublePoints',
  expires_at            TIMESTAMPTZ NOT NULL,
  radius_meters         FLOAT DEFAULT 200,
  captured_by_user_id   UUID REFERENCES profiles(id),
  captured_by_name      TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hotspots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotspots_select" ON hotspots FOR SELECT USING (true);
CREATE POLICY "hotspots_update" ON hotspots FOR UPDATE USING (true);
CREATE POLICY "hotspots_insert" ON hotspots FOR INSERT WITH CHECK (true);

-- 2. BATALHAS DE TEMPORADA
CREATE TABLE IF NOT EXISTS season_battles (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  region_name  TEXT NOT NULL,
  starts_at    TIMESTAMPTZ NOT NULL,
  ends_at      TIMESTAMPTZ NOT NULL,
  leader_id    UUID REFERENCES profiles(id),
  leader_name  TEXT,
  leader_area  FLOAT DEFAULT 0,
  badge_emoji  TEXT DEFAULT '🏅',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE season_battles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "battles_select" ON season_battles FOR SELECT USING (true);
CREATE POLICY "battles_update" ON season_battles FOR UPDATE USING (true);
CREATE POLICY "battles_insert" ON season_battles FOR INSERT WITH CHECK (true);

-- 3. HOTSPOTS DE EXEMPLO (Brasília)
INSERT INTO hotspots (id, name, lat, lng, type, expires_at, radius_meters) VALUES
  ('hs-001', 'Parque da Cidade', -15.7942, -47.9292, 'doublePoints', NOW() + INTERVAL '6 hours', 300),
  ('hs-002', 'Praça dos Três Poderes', -15.7998, -47.8645, 'megaTerritory', NOW() + INTERVAL '3 hours', 250),
  ('hs-003', 'Parque Olhos D''Água', -15.7392, -47.8935, 'rareItem', NOW() + INTERVAL '12 hours', 200)
ON CONFLICT (id) DO NOTHING;

-- 4. BATALHA DE EXEMPLO
INSERT INTO season_battles (id, name, region_name, starts_at, ends_at, badge_emoji) VALUES
  ('sb-001', 'Batalha do Plano Piloto', 'Plano Piloto - Brasília', NOW(), NOW() + INTERVAL '2 days', '🏛️')
ON CONFLICT (id) DO NOTHING;
