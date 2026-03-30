# 2026-03-30 — v1.2.1 Release, Style Fix, Diversity Design

## Session Summary
Shipped v1.2.1 to Homebrew. Fixed art style not showing (WikiArt list endpoint doesn't return style — detail endpoint does). Designed and spec'd a full artwork diversity overhaul: replace MostViewedPaintings index with on-demand random artist sampling across all 5,756+ WikiArt artists.

## What Got Done
- [x] flutter build macos --release → codesign → notarise → staple → DMG
- [x] gh release create v1.2.1 at electricsheepco/ziba
- [x] Homebrew tap updated: version 1.2.1, SHA256 d778a5f5...
- [x] Root cause found: MostViewedPaintings returns no style/genre/technique — only detail endpoint does
- [x] Fix: `refresh()` now calls `getPaintingDetail()` after getRandomArtwork(), merges only style/genre/technique/galleryName (keeps artistName from list to avoid scrambling)
- [x] Bug: detail endpoint returns "da Vinci Leonardo" not "Leonardo da Vinci" — fixed by selective merge
- [x] Diversity design spec written and committed: docs/superpowers/specs/2026-03-30-diverse-artwork-pool-design.md
- [x] Session docs committed

## Key Decisions
- Style enrichment: selective merge (style/genre/technique/galleryName only from detail)
- Diversity approach: cache artist list (5,756 artists, 7-day TTL), pick random artist per refresh, filter min 1920px, retry up to 5 times, fall back to MostViewed
- Artist recency: exclude last 10 artist URLs in-memory (not persisted)
- Settings/About: add "Artworks sourced from 5,700+ artists across WikiArt"

## TODO (Next Session)
- [ ] Write implementation plan for diversity feature (writing-plans skill)
- [ ] Execute diversity plan (subagent-driven-development)
- [ ] Ship style fix + diversity as v1.2.2

## Key Files
- `lib/state/app_state.dart` — style enrichment fix (selective merge)
- `docs/superpowers/specs/2026-03-30-diverse-artwork-pool-design.md` — diversity spec
