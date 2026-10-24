# Sampling variability: our dataset versus H0 and HA

An interactive teaching demonstration for null-hypothesis significance testing
of a correlation. It compares ONE simulated dataset's r and t with two
representations of sampling variability: six more datasets from the same
population, and two piles of 100 simulated studies (H0 true and HA true).

It is a Shiny app that runs **entirely in the browser** (shinylive / webR), so
this repository is a static website: there is no R server.

Live page (once GitHub Pages is switched on):
`https://<github-user>.github.io/<this-repo-name>/`

## Using the page

- The first visit downloads about 60 MB (the R engine and packages), so allow
  several seconds to a minute, depending on the connection. Later visits load
  from the browser's cache and are much faster.
- Open it before a lecture and keep the tab open.
- Controls: sample size N, population correlation r, a seed, "Draw new
  samples" (new focal dataset and six-grid; the piles stay fixed), "Redraw the
  piles", and "Zoom to piles".

## What is in this folder

| Path | What it is |
|---|---|
| `index.html`, `app.json`, `shinylive/`, `edit/`, `shinylive-sw.js` | The exported site (generated; do not edit by hand) |
| `app-source/` | The app's source: `app.R` plus the three helper scripts it loads. **Edit these, then rebuild** |
| `rebuild-site.R` | Regenerates the site from `app-source/` |
| `.nojekyll` | Tells GitHub Pages not to run Jekyll over the files |

`app-source/` holds copies of files from the `teaching-critical-thinking`
project (`nhst-sampling-variability-app/app.R`, `psych-battery-dgp.R`,
`nhst-fisher-neyman-pearson-demo.R`, `nhst-sampling-variability.R`), copied on
2026-10-24. The copies here are not linked to the originals: re-copy them if
the originals change.

## Updating the site

1. Replace the files in `app-source/` with the new versions.
2. From this folder run `Rscript rebuild-site.R` (needs the R package
   `shinylive`).
3. Test locally: `httpuv::runStaticServer(".")` in R, then open the address
   it prints. A page like this cannot be opened as a plain file.
4. Commit and push. After a push, a browser may keep showing the old version:
   do a hard refresh (Cmd+Shift+R) or use a private window.

## Notes

- Everything in `app-source/` ends up publicly readable on the published page
  (the source is inside `app.json`). Do not put anything private there.
- The app needs `cache = "session"` in its `bindCache()` calls, because
  shinylive does not set up shiny's default app-level cache.
- A shinylive page is served with a service worker (`shinylive-sw.js`). The
  first visit may be slower, or reload once, while it installs.
