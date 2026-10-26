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
- Use **Chrome or Edge**. Safari does not currently work (see Notes).
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
- **Safari is not supported.** In Safari (normal and private windows) the page
  frame loads but the plot cards stay empty, and the Web Inspector console shows
  `RangeError: Maximum call stack size exceeded` from `runRAsync` in
  shinylive.js. This looks like a shinylive/webR problem in Safari
  (posit-dev/r-shinylive issue #204, open when this was written). A
  `renderImage()` workaround suggested in that issue was tried (2026-10-24) and
  did not help this app, so it was removed again. Use Chrome or Edge (tested:
  Chrome). Firefox is untested. The plain Shiny app (`shiny::runApp("app-source")`)
  works in any browser.
- A shinylive page is served with a service worker (`shinylive-sw.js`). The
  first visit may be slower, or reload once, while it installs.

## Browser test log

| Date | Browser | Result |
|---|---|---|
| 2026-10-24 | Chrome (headless), live GitHub Pages page, fresh profile | Works. All four plots appear after 12.4 s on a first visit, no reload, no errors. N = 1000 about 2 s |
| 2026-10-24 | Chrome and Chrome Incognito (user) | Works; buttons work |
| 2026-10-24 | Safari, normal and private window (user), `renderPlot()` version | Page frame loads, plot cards stay empty (issue #204) |
| 2026-10-24 | Safari (user), `renderImage()` workaround version, confirmed live | **Still fails.** Plot cards stay empty. Web Inspector: `RangeError: Maximum call stack size exceeded` thrown from `runRAsync` in shinylive.js, then an unhandled promise rejection. So the workaround does not help this app |
| 2026-10-24 | (change) | The `renderImage()` workaround was removed again; `app-source/app.R` is identical to the project's `app.R` |
| 2026-10-26 | Chrome (headless), live page after the revert was pushed | Works. All four plots appear after 20.4 s on a first visit (12.4 s on 2026-10-24: varies with the network), no reload, no output errors. N = 1000 about 2.3 s. Live `app.R` is identical to the project's `app.R` |
