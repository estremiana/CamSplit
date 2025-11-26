-- Migration: Add assignment_type column to assignments table
-- Purpose: Distinguish between simple (quick) and advanced (custom) assignments
-- Date: 2025-01-XX

-- Add assignment_type column with default value 'simple' for backward compatibility
ALTER TABLE assignments 
ADD COLUMN IF NOT EXISTS assignment_type VARCHAR(20) DEFAULT 'simple';

-- Add CHECK constraint to ensure only valid values
ALTER TABLE assignments 
ADD CONSTRAINT check_assignment_type 
CHECK (assignment_type IN ('simple', 'advanced'));

-- Update existing records to have 'simple' type (if any are NULL)
UPDATE assignments 
SET assignment_type = 'simple' 
WHERE assignment_type IS NULL;

-- Make the column NOT NULL after setting defaults
ALTER TABLE assignments 
ALTER COLUMN assignment_type SET NOT NULL;

-- Add index for performance on assignment_type queries
CREATE INDEX IF NOT EXISTS idx_assignments_assignment_type 
ON assignments(assignment_type);

-- Add comment to document the column
COMMENT ON COLUMN assignments.assignment_type IS 
'Type of assignment: simple (quick equal split) or advanced (custom quantity assignment)';

