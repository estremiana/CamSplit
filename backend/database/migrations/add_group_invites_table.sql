-- Migration: Add group_invites table
-- Date: 2025-01-27
-- Description: Creates table for managing group invite links

-- Create sequence for group_invites
CREATE SEQUENCE IF NOT EXISTS group_invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create group_invites table
CREATE TABLE IF NOT EXISTS group_invites (
  id integer NOT NULL DEFAULT nextval('group_invites_id_seq'::regclass),
  group_id integer NOT NULL,
  invite_code character varying(255) UNIQUE NOT NULL,
  created_by integer NOT NULL,
  expires_at timestamp with time zone,
  max_uses integer DEFAULT 1,
  current_uses integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT group_invites_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
  CONSTRAINT group_invites_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_group_invites_group_id ON group_invites (group_id);
CREATE INDEX IF NOT EXISTS idx_group_invites_invite_code ON group_invites (invite_code);
CREATE INDEX IF NOT EXISTS idx_group_invites_created_by ON group_invites (created_by);
CREATE INDEX IF NOT EXISTS idx_group_invites_expires_at ON group_invites (expires_at);
CREATE INDEX IF NOT EXISTS idx_group_invites_is_active ON group_invites (is_active);

-- Add comments
COMMENT ON TABLE group_invites IS 'Invite links for joining groups';
COMMENT ON COLUMN group_invites.invite_code IS 'Unique invite code for the link';
COMMENT ON COLUMN group_invites.expires_at IS 'When the invite expires (NULL = never expires)';
COMMENT ON COLUMN group_invites.max_uses IS 'Maximum number of times this invite can be used';
COMMENT ON COLUMN group_invites.current_uses IS 'Number of times this invite has been used';
COMMENT ON COLUMN group_invites.is_active IS 'Whether this invite is currently active'; 