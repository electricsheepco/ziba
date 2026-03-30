# Design: Diverse Artwork Pool via On-Demand Artist Sampling

**Date:** 2026-03-30
**Status:** Approved

---

## Problem

Ziba currently sources all artworks from WikiArt's `MostViewedPaintings` endpoint — a pool of ~600 paintings from ~98 artists dominated by canonical Western art history. Artists like Edwin Lord Weeks (113 paintings on WikiArt) are completely invisible.

WikiArt has 5,756+ artists across all movements, periods, and geographies. The goal is to expose that full breadth.

---

## Approach: On-Demand Artist Sampling

Replace the painting index with a **cached artist list**. On each refresh, pick a random artist and fetch one of their paintings. No pre-built index. No background loading. Nothing to tell the user.

This mirrors how Muzei, Pap.er, and Unsplash for macOS work — fetch on demand, cache the lookup table.

---

## Architecture

### Artist List Cache
- Source: `GET /App/Artist/AlphabetJson?v=new` — returns all 5,756+ artists in one response
- Cached to disk as `ziba_artists.json` alongside existing `ziba_index.json`
- TTL: 7 days (same as current painting index)
- Size: ~500KB JSON — acceptable for local storage

### Refresh Flow (per artwork)

```
1. Load artist list from disk (or fetch + cache if stale/missing)
2. Pick a random artist (excluding the last 10 artist URLs shown — tracked in-memory, not persisted)
3. Call PaintingsByArtist → filter: max(width, height) >= 1920px
4. If no usable paintings → retry with a new random artist (max 5 attempts)
5. If all 5 attempts fail → fall back to MostViewedPaintings (existing behaviour)
6. Pick a random painting from the filtered list
7. Call getPaintingDetail → enrich with style, genre, technique, galleryName
8. Download image → save to DB → set as wallpaper
```

### Resolution Filter
- Minimum: `max(width, height) >= 1920`
- Applied client-side after fetching artist paintings
- Rationale: 1920px (1080HD width) is the minimum usable wallpaper resolution

---

## Changes Required

### `WikiArtService`
- **Add** `getArtistList()` — fetches AlphabetJson, caches to `ziba_artists.json`, returns `List<ArtistSummary>`
- **Add** `_loadArtistDiskCache()` / `_saveArtistDiskCache()` — mirrors existing painting cache helpers
- **Rewrite** `getRandomArtwork()` — artist-sampled flow replaces painting-index flow
- `getMostViewedPaintings()` retained as fallback only

### `AppState`
- No changes to `refresh()` — already calls `getRandomArtwork()` and handles detail enrichment

### Settings Screen (minor UI)
- Add a subtitle line in the About/Credits section: "Artworks sourced from 5,700+ artists across WikiArt"

---

## Error Handling

| Scenario | Behaviour |
|----------|-----------|
| Artist list fetch fails | Use stale cache if available; fall back to MostViewed if not |
| Artist has no paintings ≥ 1920px | Retry with new random artist (up to 5 attempts) |
| All 5 retries exhausted | Fall back to MostViewedPaintings pool |
| Detail enrichment fails | Already handled with `catchError` — style shows as null |
| Image download fails | Existing error handling in `refresh()` surfaces to UI |

---

## Out of Scope
- Artist search / browse by name
- Filter by movement or period (separate future feature)
- Offline mode / pre-fetching
- Any UI beyond the single Settings line
