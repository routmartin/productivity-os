CREATE TABLE qr_auth_challenges (
    id UUID PRIMARY KEY,
    challenge VARCHAR(255) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_qr_auth_challenges_challenge ON qr_auth_challenges(challenge);
