-- V17: Add index on refresh_tokens(token_hash) for O(1) rotation lookups (Plan 020)

CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);
