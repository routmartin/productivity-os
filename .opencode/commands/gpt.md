# /gpt

Generate a context snapshot for pasting into GPT/Claude conversations.

## Steps

1. Run `scripts/gpt-context.sh` to generate the snapshot.
2. Read `gpt/current.md`.
3. Output the contents — it is ready to paste.

## What it produces

- Full file listing (user module, task module, config, migrations)
- Database tables
- API endpoints (public + protected)
- Error handling map
- Build status (compileKotlin + compileTestKotlin)
- Local run commands

The snapshot is timestamped and saved to `gpt/context-YYYYMMDD-HHMMSS.md`.
`gpt/current.md` always points to the latest.
