-- =================================================================
-- SUPABASE STORAGE BUCKET POLICIES
-- =================================================================
-- This file contains all RLS policies for Supabase Storage buckets
-- to ensure secure file access and uploads.

-- =================================================================
-- USER FILES BUCKET CONFIGURATION
-- =================================================================

-- Create the userfiles bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'userfiles',
    'userfiles',
    true, -- Public access for viewing (controlled by RLS)
    52428800, -- 50MB file size limit
    ARRAY[
        'image/jpeg',
        'image/png', 
        'image/webp',
        'image/gif',
        'application/pdf',
        'text/plain',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
) ON CONFLICT (id) DO UPDATE SET
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =================================================================
-- STORAGE OBJECTS RLS POLICIES
-- =================================================================

-- Enable RLS on storage objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy for viewing objects: Users can view their own files, admins can view all
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
CREATE POLICY "Users can view their own files"
ON storage.objects FOR SELECT
USING (
    auth.uid()::text = (storage.foldername(name))[1] OR
    auth.jwt()->>'role' = 'admin'
);

-- Policy for uploading files: Users can upload to their own folder only
DROP POLICY IF EXISTS "Users can upload to their own folder" ON storage.objects;
CREATE POLICY "Users can upload to their own folder"
ON storage.objects FOR INSERT
WITH CHECK (
    auth.uid()::text = (storage.foldername(name))[1] AND
    bucket_id = 'userfiles'
);

-- Policy for updating files: Users can update their own files only
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
USING (
    auth.uid()::text = (storage.foldername(name))[1] OR
    auth.jwt()->>'role' = 'admin'
)
WITH CHECK (
    auth.uid()::text = (storage.foldername(name))[1] OR
    auth.jwt()->>'role' = 'admin'
);

-- Policy for deleting files: Users can delete their own files only
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
USING (
    auth.uid()::text = (storage.foldername(name))[1] OR
    auth.jwt()->>'role' = 'admin'
);

-- =================================================================
-- STORAGE BUCKETS RLS POLICIES
-- =================================================================

-- Enable RLS on buckets table
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view bucket information
DROP POLICY IF EXISTS "Bucket access for authenticated users" ON storage.buckets;
CREATE POLICY "Bucket access for authenticated users"
ON storage.buckets FOR SELECT
TO authenticated, anon
USING (true);

-- Only admins can modify bucket settings
DROP POLICY IF EXISTS "Admin bucket management" ON storage.buckets;
CREATE POLICY "Admin bucket management"
ON storage.buckets FOR ALL
TO authenticated
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- ADDITIONAL SECURITY MEASURES
-- =================================================================

-- Function to validate file paths (called by triggers)
CREATE OR REPLACE FUNCTION validate_file_path()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Ensure user ID in path matches authenticated user
    IF NEW.bucket_id = 'userfiles' THEN
        IF auth.uid()::text != (storage.foldername(NEW.name))[1] THEN
            RAISE EXCEPTION 'File path must start with your user ID';
        END IF;
        
        -- Validate subfolder structure
        IF (storage.foldername(NEW.name))[2] NOT IN ('card-images', 'content-images', 'verification-documents') THEN
            RAISE EXCEPTION 'Invalid subfolder. Allowed: card-images, content-images, verification-documents';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to validate file paths on upload
DROP TRIGGER IF EXISTS validate_file_path_trigger ON storage.objects;
CREATE TRIGGER validate_file_path_trigger
    BEFORE INSERT OR UPDATE ON storage.objects
    FOR EACH ROW
    EXECUTE FUNCTION validate_file_path();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA storage TO authenticated, anon;
GRANT SELECT ON storage.objects TO authenticated, anon;
GRANT SELECT ON storage.buckets TO authenticated, anon;

-- Instructions for applying these policies:
-- 1. Use Supabase CLI with service role key
-- 2. Apply through Supabase dashboard under Storage > Policies
-- 3. Or run with superuser permissions in local development 