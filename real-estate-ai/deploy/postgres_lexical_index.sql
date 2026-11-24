CREATE INDEX CONCURRENTLY IF NOT EXISTS chatbot_parents_lexical_idx
    ON chatbot_index.parents USING GIN (to_tsvector('simple', document::jsonb ->> 'text'))
    WHERE public = 1;
