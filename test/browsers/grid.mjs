// The published specimen, in every engine there is.
//
// The Ruby suite measures the page in Chromium, and for a long time the grid
// was a claim about Chromium: three of the ways the column came apart in
// 0.6.1 were invisible in the one browser it was checked in, and the fix
// that made the baseline real in 0.5.0 was a property only one engine had.
// The faces are supposed to hold in any browser that honours a @font-face
// descriptor, and this is where that is checked rather than believed.
//
//   bin/specimen tmp/specimen
//   node test/browsers/grid.mjs tmp/specimen/index.html            # chromium, webkit, firefox
//   node test/browsers/grid.mjs tmp/specimen/index.html firefox    # one of them
//
// It asks each engine exactly the question the Ruby suite asks Chromium —
// the one function in test/support/on_the_grid.js — and fails if any box or
// any baseline is off the grid in any of them. Playwright is the one
// dependency, and it is not in the Gemfile because it is not a gem:
//
//   npm install --no-save --no-package-lock playwright
//   npx playwright install --with-deps chromium webkit firefox
//
// CHROME_BINARY, the same variable the Ruby suite reads, points the Chromium
// run at a browser already on the machine instead of the one Playwright
// would download.
//
// The faces each engine loaded are reported rather than asserted: Firefox
// lists none of them in document.fonts and lays the page out on them all
// the same, and WebKit lists them and keeps the font's own metrics. What
// counts is the grid, and which of the two mechanisms an engine is on is
// read off the document: the script ahead of the stylesheets marks it when
// the engine honours a face's metrics, and the trim is doing the work
// otherwise.
import { chromium, webkit, firefox } from "playwright"
import { readFileSync } from "node:fs"
import { resolve } from "node:path"

const [file, ...named] = process.argv.slice(2)
if (!file) {
  console.error("usage: node test/browsers/grid.mjs <specimen.html> [chromium|webkit|firefox ...]")
  process.exit(2)
}

const engines = { chromium, webkit, firefox }
const onTheGrid = readFileSync(new URL("../support/on_the_grid.js", import.meta.url), "utf8")
let failed = false

for (const name of named.length ? named : Object.keys(engines)) {
  const executablePath = name === "chromium" ? process.env.CHROME_BINARY : undefined
  const browser = await engines[name].launch(executablePath ? { executablePath } : {})
  const page = await browser.newPage({ viewport: { width: 1400, height: 1400 } })
  await page.goto("file://" + resolve(file))
  await page.evaluate(() => document.fonts.ready)

  const unit = await page.evaluate(() => parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5)
  const faces = await page.evaluate(() =>
    Array.from(document.fonts).filter((face) => face.family.startsWith("its-swiss") && face.status === "loaded")
      .map((face) => `${face.family}/${face.weight}`))
  const { boxes, type } = await page.evaluate(`(${onTheGrid})(${unit})`)

  const mechanism = await page.evaluate(() => document.documentElement.classList.contains("metric-overrides") ? "on the faces" : "trimmed")
  const verdict = boxes.length || type.length ? "off the grid" : "on the grid"
  console.log(`${name}: ${verdict}, ${mechanism} — ${boxes.length} boxes, ${type.length} runs of type; faces loaded: ${faces.join(" ") || "none"}`)
  for (const line of [ ...boxes, ...type ].slice(0, 20)) console.log(`  ${line}`)

  await browser.close()
  if (boxes.length || type.length) failed = true
}

process.exit(failed ? 1 : 0)
