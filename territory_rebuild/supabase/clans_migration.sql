-- TerritoryApp — Clãs e Times
-- Execute no SQL Editor do Supabase

CREATE TABLE IF NOT EXISTS clans (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  tag           TEXT NOT NULL,
  color         TEXT DEFAULT '#FF5722',
  leader_id     UUID NOT NULL REFERENCES profiles(id),
  leader_name   TEXT NOT NULL,
  member_count  INT DEFAULT 1,
  total_area_m2 FLOAT DEFAULT 0,
  description   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clan_members (
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  clan_id    TEXT NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  role       TEXT DEFAULT 'member',
  nickname   TEXT,
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, clan_id)
);

-- Adiciona colunas de clã no perfil
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS clan_id TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS clan_tag TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS clan_color TEXT;

-- RLS
ALTER TABLE clans ENABLE ROW LEVEL SECURITY;
ALTER TABLE clan_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clans_select" ON clans FOR SELECT USING (true);
CREATE POLICY "clans_insert" ON clans FOR INSERT WITH CHECK (auth.uid() = leader_id);
CREATE POLICY "clans_update" ON clans FOR UPDATE USING (true);

CREATE POLICY "clan_members_select" ON clan_members FOR SELECT USING (true);
CREATE POLICY "clan_members_insert" ON clan_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "clan_members_delete" ON clan_members FOR DELETE USING (auth.uid() = user_id);

-- Trigger: atualiza member_count ao entrar/sair
CREATE OR REPLACE FUNCTION update_clan_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE clans SET member_count = member_count + 1 WHERE id = NEW.clan_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE clans SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.clan_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_clan_member_change ON clan_members;
CREATE TRIGGER on_clan_member_change
  AFTER INSERT OR DELETE ON clan_members
  FOR EACH ROW EXECUTE FUNCTION update_clan_member_count();
