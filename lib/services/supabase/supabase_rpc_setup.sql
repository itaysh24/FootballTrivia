-- ============================================================================
-- SUPABASE RPC SETUP FOR FUZZY PLAYER SEARCH
-- ============================================================================
-- This SQL script sets up the necessary database functions and indexes
-- for the fuzzy player search feature in the Football Trivia app.
-- ============================================================================

-- Step 1: Enable the pg_trgm extension for trigram similarity matching
-- This extension provides fuzzy string matching capabilities
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Step 2: Create the search_players RPC function
-- This function performs fuzzy search on player names using trigram similarity
CREATE OR REPLACE FUNCTION search_players(
  query_text TEXT,
  limit_count INT DEFAULT 10
)
RETURNS TABLE (
  id INT,
  firstname TEXT,
  lastname TEXT,
  answer TEXT,
  career_path TEXT,
  Category TEXT,
  similarity FLOAT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.firstname,
    p.lastname,
    p.answer,
    p.career_path,
    p.Category,
    similarity(LOWER(p.answer), LOWER(query_text)) as similarity
  FROM players p
  WHERE 
    -- Use trigram similarity for fuzzy matching
    similarity(LOWER(p.answer), LOWER(query_text)) > 0.1
    OR LOWER(p.answer) LIKE LOWER('%' || query_text || '%')
    OR LOWER(p.firstname) LIKE LOWER('%' || query_text || '%')
    OR LOWER(p.lastname) LIKE LOWER('%' || query_text || '%')
  ORDER BY 
    -- Order by similarity score (highest first)
    similarity(LOWER(p.answer), LOWER(query_text)) DESC,
    p.answer ASC
  LIMIT limit_count;
END;
$$;

-- Step 3: Create GIN indexes for better performance
-- These indexes speed up trigram similarity searches significantly

-- Index on the answer field (primary search field)
CREATE INDEX IF NOT EXISTS players_answer_trgm_idx 
  ON players 
  USING gin (LOWER(answer) gin_trgm_ops);

-- Index on firstname for partial name searches
CREATE INDEX IF NOT EXISTS players_firstname_trgm_idx 
  ON players 
  USING gin (LOWER(firstname) gin_trgm_ops);

-- Index on lastname for partial name searches
CREATE INDEX IF NOT EXISTS players_lastname_trgm_idx 
  ON players 
  USING gin (LOWER(lastname) gin_trgm_ops);

-- Step 4: Grant execute permission on the function (if using RLS)
-- Uncomment the next line if you're using Row Level Security
-- GRANT EXECUTE ON FUNCTION search_players TO anon, authenticated;

-- ============================================================================
-- TESTING QUERIES
-- ============================================================================
-- Use these queries to test the fuzzy search functionality

-- Test 1: Exact match
SELECT * FROM search_players('Lionel Messi', 5);

-- Test 2: Typo (missing letters)
SELECT * FROM search_players('Linel Mesi', 5);

-- Test 3: Partial name
SELECT * FROM search_players('Ronaldo', 5);

-- Test 4: First name only
SELECT * FROM search_players('Cristiano', 5);

-- Test 5: Common misspelling
SELECT * FROM search_players('Messy', 5);

-- ============================================================================
-- ADDITIONAL HELPER FUNCTIONS (OPTIONAL)
-- ============================================================================

-- Function to search by category
CREATE OR REPLACE FUNCTION search_players_by_category(
  query_text TEXT,
  category_filter TEXT,
  limit_count INT DEFAULT 10
)
RETURNS TABLE (
  id INT,
  firstname TEXT,
  lastname TEXT,
  answer TEXT,
  career_path TEXT,
  Category TEXT,
  similarity FLOAT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.firstname,
    p.lastname,
    p.answer,
    p.career_path,
    p.Category,
    similarity(LOWER(p.answer), LOWER(query_text)) as similarity
  FROM players p
  WHERE 
    p.Category = category_filter
    AND (
      similarity(LOWER(p.answer), LOWER(query_text)) > 0.1
      OR LOWER(p.answer) LIKE LOWER('%' || query_text || '%')
    )
  ORDER BY 
    similarity(LOWER(p.answer), LOWER(query_text)) DESC,
    p.answer ASC
  LIMIT limit_count;
END;
$$;

-- Function to get player suggestions (autocomplete)
-- Returns only player names for lightweight autocomplete
CREATE OR REPLACE FUNCTION get_player_suggestions(
  query_text TEXT,
  limit_count INT DEFAULT 5
)
RETURNS TABLE (
  id INT,
  name TEXT,
  category TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.answer as name,
    p.Category as category
  FROM players p
  WHERE 
    LENGTH(query_text) > 0
    AND (
      LOWER(p.answer) LIKE LOWER(query_text || '%')
      OR similarity(LOWER(p.answer), LOWER(query_text)) > 0.3
    )
  ORDER BY 
    -- Prioritize starts-with matches
    CASE 
      WHEN LOWER(p.answer) LIKE LOWER(query_text || '%') THEN 0
      ELSE 1
    END,
    similarity(LOWER(p.answer), LOWER(query_text)) DESC
  LIMIT limit_count;
END;
$$;

-- ============================================================================
-- MAINTENANCE
-- ============================================================================

-- View index usage statistics
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'players'
ORDER BY idx_scan DESC;

-- Analyze table for query optimization
ANALYZE players;

-- ============================================================================
-- NOTES
-- ============================================================================
-- 
-- Similarity Threshold Recommendations:
-- - 0.1: Very lenient (allows many typos and variations)
-- - 0.3: Moderate (good balance for most use cases)
-- - 0.5: Strict (requires close match)
-- - 0.7: Very strict (almost exact match)
--
-- Performance Considerations:
-- - GIN indexes improve search speed significantly
-- - Regular ANALYZE updates help query planner
-- - Consider partitioning if table grows very large (>1M rows)
-- - Monitor index usage with pg_stat_user_indexes
--
-- Adjusting for Your Data:
-- - If your player names are in different languages, you may need
--   to adjust the LOWER() function or add unaccent extension
-- - Customize the similarity threshold based on your needs
-- - Add additional indexes on other searchable fields
-- ============================================================================

