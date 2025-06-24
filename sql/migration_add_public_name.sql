-- Migration to update user_profiles schema for separate profile and verification
-- Run this to update existing database

-- Add new columns
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;

-- Rename status column to verification_status
ALTER TABLE public.user_profiles 
RENAME COLUMN status TO verification_status;

-- Reorder columns logically (PostgreSQL doesn't support column reordering directly)
-- But we can document the intended structure:
-- 1. Basic profile fields: public_name, bio, company_name
-- 2. Verification fields: full_name, verification_status, supporting_documents, admin_feedback, verified_at

-- Update existing data: Set verified_at for approved profiles
UPDATE public.user_profiles 
SET verified_at = updated_at 
WHERE verification_status = 'APPROVED' AND verified_at IS NULL;

-- Optional: If you want to clear verification data for non-submitted profiles
-- UPDATE public.user_profiles 
-- SET full_name = NULL, supporting_documents = NULL, admin_feedback = NULL
-- WHERE verification_status = 'NOT_SUBMITTED';

-- Migration: Add public_name field to user_profiles table
-- Run this if you have existing data and need to add the new column

-- Add the public_name column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS public_name TEXT;

-- Add a comment to clarify the purpose of each name field
COMMENT ON COLUMN public.user_profiles.full_name IS 'Legal name for verification purposes';
COMMENT ON COLUMN public.user_profiles.public_name IS 'Display name shown to the public';

-- Optional: Copy full_name to public_name for existing records if needed
-- UPDATE public.user_profiles 
-- SET public_name = full_name 
-- WHERE public_name IS NULL AND full_name IS NOT NULL; 