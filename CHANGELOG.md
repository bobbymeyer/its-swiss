# Changelog

Semver. Consumers pin `~> 0.1`.

## Unreleased

### Fixed

- **A pinned specimen stopped existing.** Pages replaces the whole site on
  every deploy, so a version-stamped page survives only if the run writes it
  again. The step meant to carry them forward read them back off the live
  site, for released tags only — so it preserved nothing that a deploy had
  already dropped, and nothing at all for a version that was never tagged.
  `0.6.0.html`, which a published post points at, was gone the next time main
  moved; the deploy after it uploaded `index.html` and `0.6.1.html` and
  nothing else.

  Pinned versions are kept in `published/` and copied into the site each
  deploy, so what is published is reproducible from the repository rather than
  from itself. `0.6.0.html` is restored there, rendered from the 0.6.0 commit
  by that version's own `bin/specimen`.

## 0.7.0 — Unreleased

Every baseline on the grid, in every browser, whatever the font.

- **The type is set in faces the library declares.** A line box puts its
  baseline half the leading down and then the font's ascent, and the ascent
  is a number in the font file the library has never been told — so every
  line of type sat on a baseline the library could not move, and a page on
  the grid in one font was off it in the next. `faces.css` declares the
  machine's grotesque three times over `src: local()`, once per ratio of
  leading to size the ladder produces, each with `ascent-override` set to
  that ratio and `descent-override` and `line-gap-override` set to nothing.
  The baseline is then the under edge of the line box, in every line and in
  any browser that honours a `@font-face` descriptor. A register names its
  face — `font-family: var(--face-200), var(--font-family)` — and the tokens
  `--face-150`, `--face-200` and `--face-100` are the three. Chromium and
  Firefox honour the descriptors.
- **Safari does not, so there the trim is the grid.** WebKit loads the face
  and keeps the font's own metrics. Every text block is still trimmed to its
  cap and its baseline and padded back up — to its *own* leading now,
  `round(up, 1cap, 1lh)`, so a subhead set on two lines is no longer trimmed
  to one, and less the cap as WebKit trims it, which is rounded to a pixel —
  and only where it is needed: a trimmed box is a 64th short as
  often as not, which down a long column is a pixel, so one line of script
  ahead of the stylesheets marks the document `metric-overrides` where the
  faces are honoured and the trim stands down. `its_swiss_stylesheet_tags`
  writes it; anything linking the stylesheets by hand should too, and the
  README has the line. Buttons, cells and the copy button are trimmed as
  well now, with the correction in their own paddings. A control's own text
  is the one thing neither mechanism reaches in Safari.
- **Text lives in text elements.** A box that holds blocks is trimmed
  through its first and last child and would be corrected twice, so the trim
  is asked of headings, paragraphs, cells, labels, buttons and the like, and
  of list items and definitions only when they hold text. The shell puts
  the `:footer` slot's text in a paragraph.
- **Nothing inside a line changes the line.** `code`, `kbd`, `samp`, `small`,
  `sup` and `sub` are given no leading, so a second size on a line never
  asks it for room; the glyphs still sit on the strut's baseline.
- **No row asks the browser to find a baseline.** `.run` and `.field--inline`
  align on their over edge and `.choice` on its under edge, and a table cell
  on `top`: every box's baselines are whole lines below its own over edge,
  so starting items on one line puts their baselines on one line, without a
  question that a button, a form and a block of text answer three ways.
- **A button is a box, with its label centred in it.** Two lines tall, on
  the grid, and the label's baseline is the one baseline in the library that
  is not on a line, on purpose: a button is read as a shape, and a label set
  on the second line of a two-line box reads as a field with a rule under
  it. Centred by cap where the faces are honoured, since a face puts the
  label's baseline on the under edge of its line; by the font's own metrics
  otherwise. The keyline is an inset shadow rather than a border, so the box
  is the label's line and two paddings and nothing else. A table cell is a
  line the type is set on and a line the rule closes, with nothing above its
  type.
- **Each bold face names the regular ones after its own.** A face whose
  every `local()` fails does not load, and the browser goes on to the next
  family — the grotesque stack, with its own metrics — for every heading on
  the page while the body stays on the grid. Falling through to the regular
  file keeps the metrics and loses the weight.
- **The specimen measures itself.** A third button asks the page the
  question the suite asks: which mechanism this browser is on, which faces
  it loaded, and every box and run of type off the grid, printed on the
  page to be read or pasted.
- **`its_swiss_typeface`** writes an application's own font under the
  library's face names with the library's descriptors, from a regular and a
  bold file or one variable file, and a monospace if there is one.
- **The guards measure type, not boxes standing in for it.** Every run of
  text on the page has its baseline on a line: the under edge of a trimmed
  block less its padding, or the under edge of the rectangle the engine
  reports for an untrimmed run, which with no descent is the baseline and
  with the font's own is a descent off it. The question is one function; a
  Playwright job asks it of the published specimen in Chromium, WebKit and
  Firefox, and the Chromium suite asks it again with the faces taken away,
  which is Safari's page. A page that trims is measured box by box rather
  than from the top, so the 64ths are let go and every whole pixel is not.

Why: 0.5.0 made the baseline real with a property one engine had, and 0.6.1
found three ways the page came apart in the others and fixed the three. The
faces replace the font's metrics with the ladder's, which is the only thing
that was ever going to hold in a browser nobody had checked.

A consumer that set a register of its own with a size and a leading should
add the face for their ratio; a consumer that declared `--font-family` and
nothing else keeps a readable page in step, and adds `its_swiss_typeface` to
register it.

## 0.6.1 — 2026-09-02

Three ways the column came apart in a browser that was not Chromium.

- **`.footer` and `.field__error` take their leading from `--line`.** The
  footer was led on `--space-3` and the field error on `--space-2`. The first
  happens to be twenty-four pixels and so was only wrong to read; the second
  is sixteen, and put eight pixels into the column that everything below it
  then carried.
- **The leading guard is asked of every stylesheet, not only `type.css`.** It
  passed for as long as it did because a register can be declared in any file
  and it was only ever looking in one.
- **The masthead, the nav and the pagination align on their under edge
  rather than on a baseline.** A trimmed block's under edge *is* the baseline
  of its last line, and every child of those three rows is one line — so
  aligning the edges aligns the baselines by construction, instead of asking
  the browser to find a baseline. Browsers do not agree on that answer once
  trimming is involved, and the masthead is where it shows: it puts a block
  beside a flex container, and a browser that synthesizes those two a few
  pixels apart grows the row past its three lines and carries the difference
  down every section below it. The rows that keep `baseline` are the ones
  that need it, where a line of type sits beside something taller — `.run`,
  `.field--inline`, `.choice`.
- **The grid is measured without `text-box-trim` as well as with it,** and the
  published page is measured at all. A trimmed box is its cap rounded up to a
  whole line whatever the leading under it says, so trimming hides exactly
  this class of error; a browser without it got a page that came apart from
  the form down. The check now runs twice, and the file `bin/specimen` writes
  is loaded in a browser over `file://` rather than only read as text.

Why: the vertical grid was a claim about Chromium. All three were in
`components.css`, none was visible to the guard that exists to catch it, and
none was visible on screen in the one browser everything was checked in —
which is three ways of saying the same thing, and the reason the fix is
mostly test. The baseline one is the sharpest version of it: the box check
exempts an item placed by a baseline row, on the grounds that a row is where
a short thing legitimately sits off the line. So for as long as the masthead
asked for a baseline, nothing measured where its two halves landed. It does
not ask any more, and now they are measured like anything else.

## 0.6.0 — 2026-09-02

The specimen is published, so nothing has to keep a copy of it.

- **`bin/specimen`** writes the page as one static file: the six stylesheets
  inlined verbatim, the engine's own markup, and the accent and the baseline
  as buttons rather than as a second rendering. It needs nothing to display —
  no Rails, no network, no stylesheet it has to go and fetch.
- **A Pages workflow publishes it on every push to `main`**, keeping every
  released version alongside the current one:

  | | |
  | --- | --- |
  | `bobbymeyer.github.io/its-swiss/` | the current specimen |
  | `bobbymeyer.github.io/its-swiss/0.6.0.html` | the one a post can pin |

  Point a post or a release note at the version-stamped copy. A page that
  silently changes what it depicts is worse than one a little behind.

Why: the specimen is ERB rendered by Rails, so anything that cannot run Rails
has had to keep a copy made by hand. Two did, and both drifted — one declared
a `--baseline` the library had renamed and a `--measure` it never had. A copy
made by hand is a copy that will be wrong; the fix is to publish the real one.

The page also broadcasts its own height by `postMessage`, so an iframe can
size itself rather than have a height guessed at one width and wrong at every
other.

## 0.5.0 — 2026-09-02

Asking the specimen to show everything found that it did not, and that one
rule had quietly stopped doing anything.

- **`.micro--tap` is gone**, with the rule it led. It gave micro type a taller
  line box so a 14px tap target cleared 24px — and 0.4.0 put `.micro` on a
  whole line, which made every selector in that rule a restatement of what
  the body already said. Nothing caught it: the guards ask whether a leading
  is a whole number of lines, and a redundant rule answers yes.
- **`.stack`, `.form--inline`, `.field--inline`, `.pairs--stacked` and
  `.figure--cover` are on the specimen**, which is where a component the
  library ships is documented and guarded. They were shipped and shown
  nowhere.
- **A label beside a control opts out of trimming**, as `.choice label`
  already did. A row that aligns on the baseline cannot align a trimmed box
  against an untrimmed one: it lands on a half pixel and takes the column
  with it, which is what the new inline field did.

### Guards

- **Every class the library defines appears on the specimen.** Two documented
  exceptions: `button_to`, which is Rails' wrapper, and `visually-hidden`,
  which is offered to applications and has nothing to show. This is the guard
  that would have caught `.micro--tap`, and it is what makes the specimen a
  claim about coverage rather than a page that happens to be long.
- The box test exempts a flex item in a baseline-aligned row from the
  column check, as it already exempted an inline-block: both are placed by
  something other than the column. The row itself is still measured, so a row
  that breaks the column still fails.

## 0.4.0 — 2026-08-31

**Breaking.** The baseline is now the line, not a third of it. Applications
setting `--baseline` need to set `--line` instead; everything else follows.

### The grid

0.3.0 put the type on a baseline grid and then registered it to eight pixels —
a third of the body line. A block could be a whole number of thirds and still
land every line of type after it somewhere new, which is what a label on a
sixteen-pixel leading and a section head on thirty-two did, all the way down a
column. A third of a line is a spacing unit. It is not a baseline.

- **`--line` (24px) replaces `--baseline` (8px)** as the interval everything
  vertical registers to. It is also the body leading, because in a baseline
  grid those are one number.
- **Every leading is a whole number of lines.** `h1` and `h2` move from 40 and
  32 to 48; the page title from 48 to 72; labels and captions from 16 to 24.
  The page is airier, and that is what the convention looks like.
- **`--line-2`, `--line-3`, `--line-4`, `--line-6`** for whole-line spacing.
  `--space-*` survives, renamed at its root to `--space-unit`, as the
  **horizontal** step: an inline gap has no baseline to miss.
- **`--half-line` and `.subgrid`**, the one subgrid, for a block of small
  type. It halves `--line` for the block's *children* — the block's own
  margins belong to the column outside it and are owed whole lines. Declaring
  it on the block itself halved the gap above it and landed the column half a
  line out, which the specimen caught.

### Pictures, rules, controls

- **`.figure` puts a picture on the line at any width.** Its box is the
  natural height taken up to the next whole line with `round()`, recomputed as
  the container resizes; the picture is fitted inside with `contain`, so
  nothing of it is lost. `.figure--cover` crops instead. `--ratio` is the
  application's to declare. Tested at four widths.
- `hr` is a line-tall box rather than a rule with margins either side.
- A text control is two lines of box: one the text sits on, one the rule
  closes. A checkbox is reset out of that, since the browser draws it at a
  size of its own.

### Guards

- The box test measures in lines, and honours `.subgrid` — a block that
  declares a half-line may use one; the block itself still owes whole lines.
- A picture is measured at 1400, 1100, 903 and 712 pixels wide.
- `--baseline` may not reappear in the library. A token that no longer means
  what it says is worse than one that is gone.

## 0.3.0 — 2026-09-01

The vertical rhythm, twice: once to put every box on the baseline, and again
to put the type on it. Found from outside, in a page that embedded the
specimen and turned the baseline overlay on — the grid was drawn correctly and
nothing sat on it.

Rendering moves. Every ruled component is a pixel or two shorter, and where a
browser can trim a text box the leading comes out of the block, so a page is
tighter than 0.2.0 by a few pixels per block. Read this section before
upgrading.

### Fixed

- **The vertical rhythm was decorative.** Every line box was a whole number of
  baselines and the page was still off the grid, because a line box is not a
  box: wherever a rule sat on a padded edge, its width was *added* to a box
  whose padding was already whole baselines. A hairline is a pixel, so each
  one moved everything below it by a pixel — and since the masthead, the
  footer, `hr`, every table row, every field control, every button, the
  pagination and the errors block all did it, the error accumulated down the
  column rather than showing up once. On the specimen the page was one pixel
  out by the first heading and seven by the footer.

  Every rule now comes out of the padding it sits on — `calc(var(--space-1) -
  var(--rule-hair))` — and `hr` draws its rule on the top edge of a box one
  baseline tall instead of compensating in a margin, because a margin
  compensation collapses away exactly where a rule leads or precedes a
  section. Boxes that change height: a button and a table row are 40px rather
  than 42 and 41, a field control 32 rather than 33, a `select` 32 rather than
  29.
- **A token in a line of prose grew the line.** `code`, `kbd` and `samp` set
  in the mono stack are a second font on the line, with an ascent and a
  descent of their own that the line box had to hold — a pixel at body size,
  four under the page title, and only on the lines that happened to mention a
  token. Their leading is now zero, which leaves the line box to the strut;
  the glyphs are untouched.
- **`select` ignored its leading.** `font: inherit` hands a control the family
  and the size and puts its line box back to `normal`, so a select stood 29px
  where every other control stood 32. It is now given the height the rest of
  the ladder produces.
- **A checkbox row was 20px.** The label beside a checkbox took the micro
  register's 16px line box, which is not the row a 13px control sits on. It
  now takes the same 24px line the library already gives the micro type you
  can tap.
- **Table rows landed on half pixels.** With `border-collapse: collapse` the
  shared rule belongs to the boundary rather than to either cell, and the
  browser splits it: every row sat at `x.5` and the header row was half a
  pixel short. Nothing in the library draws a border two cells could share, so
  borders are separate — with the spacing still zero — and a row is exactly as
  tall as the ladder says.

### Added

- **The type sits on the baseline now, not merely in step with it.** Boxes in
  step are not a baseline grid. Where a line's baseline falls inside its line
  box depends on the font's ascent and the leading either side of it, so at
  0.2.0 a paragraph's baselines sat a pixel off the grid, a caption's four,
  and the two were three pixels out of register with each other — every
  register keeping its own grid, none of them the page's.

  Every text register is now trimmed — `text-box: trim-both cap alphabetic` —
  which makes a block's over edge the cap of its first line and its under edge
  the baseline of its last. What then separates the box from the grid is the
  cap height, and one padding rounds it up: `calc(round(up, 1cap,
  var(--baseline)) - 1cap)`, measured by the browser in cap units, so a
  library that leaves the typeface to the application still never has to be
  told the font's metrics. It is published as `--cap-correction`, which any
  component setting its own padding adds to it — `calc(var(--space-1) +
  var(--cap-correction))` is the right padding in both paths.

  Behind `@supports`, and the fallback is the box rhythm below: Chromium and
  Safari trim, Firefox does not yet. **The two do not render identically.**
  Trimming takes the leading out of a block's own box, so the spacing you
  declare is the spacing you see; a trimmed page is a few pixels tighter per
  block than the same page in Firefox, and the ladder means what it says
  rather than what it says plus half a line. Both stay on the grid.

  Controls opt out — a button is five baselines of box with its label centred,
  and trimming the label would take the box with it — as does any block whose
  content is not type. `text-box: normal; padding-block-start: 0` is how.

### Fixed

- **`rake release` did not exist.** The release workflow runs
  `bundle exec rake release`, which is Bundler's task and arrives with
  `require "bundler/gem_tasks"` — which the Rakefile did not have. So a
  release passed every check it makes, minted its credentials over OIDC, and
  stopped at *Don't know how to build task 'release'*. 0.2.0 never reached
  RubyGems for this reason, and 0.1.0 only did because it was pushed by hand
  before the workflow existed, which the "already published" guard then read
  as nothing to do. Guarded now, along with the workflow's own tag-versus-
  gemspec check.
- **Every browser test was skipping in CI.** The suite looks for a browser and
  a driver, and a candidate found on the `PATH` came back as the bare name it
  was looked up by. Selenium wants a file — given `"chromedriver"` it raises
  *not a file* — so the harness caught that, fell back to `rack_test` and
  skipped, on a runner that had just installed a driver for it. The job was
  green and had checked nothing: 12 runs, 12 skips. Candidates now resolve to
  where they actually are, and the CI job now names the browser and the driver
  the same step installed — the runner image ships a chromedriver of its own,
  and a driver a major version ahead of the browser refuses to start a session
  at all — and sets `REQUIRE_BROWSER`, which turns a skip into a failure — a skipped browser test is invisible in a passing
  job, and the assertions that need a browser are the ones about what the
  cascade and the box model actually did.
- **The `:head` slot rendered before the library's own stylesheets**, so a
  layer named there took its place in the order ahead of every layer the
  library declares and lost to all of them. The specimen's own furniture is
  one such stylesheet, and it could not override the library it documents. The
  slot now comes after.

### Guards added

- **Every register's last baseline is on a baseline**, measured in the
  browser. Under `trim-both … alphabetic` a block's under edge *is* that
  baseline, so measuring the box measures the type — and it is measured rather
  than probed on purpose: inserting a span to read a baseline re-lays out a
  trimmed page and moves the thing it was measuring. Skips where the browser
  cannot trim.
- **The correction is zero where the browser cannot trim**, read from the
  source, so the enhancement can never become a requirement.
- **Every box on the specimen starts on a baseline and is a whole number of
  them tall**, measured in the browser on the page that holds one of
  everything. The suite already asserted that every *line box* was a whole
  number of baselines, which was true throughout and is what let all of the
  above through.
- The leading guard now admits `0`, the one value that is not a measurement:
  an inline box that takes no part in the line it sits on.

## 0.2.0 — 2026-08-31 · never published

**This version is tagged but is not on RubyGems, and will not be.** Its
release run passed the tag check, Rubocop and the suite, then failed at
`rubygems/release-gem`, which runs `bundle exec rake release` — a task the
Rakefile did not define until 0.3.0 added `require "bundler/gem_tasks"`. By
the time that was fixed, 0.3.0 was the next release, and publishing an older
version after two newer ones is worse than the gap.

Nothing here is lost: 0.3.0 was cut from a `main` that already contained all
of it, so every published version since carries these fixes. Only the version
number is missing — `~> 0.2.0` resolves to nothing, and `~> 0.1` skips over
it. Everything below shipped in 0.3.0.

Everything here was found by the second consumer inside a day of building on
0.1.0, which is roughly the point of having one.

### Fixed

- **The pagination partial printed its own source.** Its opening comment held
  a worked example written in ERB; the example's own closing delimiter ended
  the comment, and the two lines after it were emitted as page content. On
  every page that rendered it — including the specimen, the library's own
  documentation and regression fixture, for the whole of 0.1.0. The example
  now lives in the README, where it can be quoted.
- **`.table .numeric` zeroed the end padding of every numeric cell**, not just
  one in the final column, because it set the padding with the `padding-inline`
  shorthand. Anywhere else in a table the next column's text began exactly
  where the number ended. Now sets only `padding-inline-start`, and leaves the
  final column to the `:last-child` rule that already handled it.

### Changed

- **`its_swiss:install` generates a nested layout** — `app/views/layouts/
  application.html.erb` ending in `render template: "layouts/its_swiss/shell"`
  — instead of injecting `layout "its_swiss/shell"` into `ApplicationController`.
  The shell is filled through `content_for`, which has to run while a view is
  rendering; naming it on the controller rendered the shell but left nowhere
  to fill it once, so an application wrote its masthead into every view. The
  generated layout also **links `theme.css`**, which nothing did before: an
  application that followed the README exactly got no accent and no grid, with
  no error anywhere.

  Existing installs keep working. To move: delete the `layout` line from
  `ApplicationController` and add the layout, or re-run the generator.

### Guards added

Three of the four findings were in views, a generator and a form builder —
surfaces a CSS library's tests do not reach. Two new ones, both of which fail
on the bugs above:

- The rendered specimen contains no template delimiters. Every other assertion
  in that file was about markup that should be present; none about output that
  should not be.
- No view's comment quotes ERB. A comment ends at the first closing delimiter
  it meets, so an example inside one is an example that truncates it.

The specimen's table now has a numeric column that is not last, and a browser
test measures its end padding — the case that broke.

## 0.1.0 — 2026-08-31

The first extraction, from Pandatone, which ships on it.

One consumer, not two, which is what the leading zero is for: the boundary was
drawn from one real application and the second has not been built yet. Expect
the surface to move — see "Unproven" below. Pin `~> 0.1` and read this file
before upgrading.

### Core

- Six-step OKLCH value scale, paper to ink, neutral as shipped and warmed by
  two slots. An unset `--accent` falls back to ink.
- A reset, five type sizes on an alternating 1.33/1.5 ratio, and one vertical
  ladder used for leading as much as for space.
- Grid primitives — `.page`, `.grid`, `.measure`, `.fields`, `.run`, `.stack` —
  and never a grid. A child says its width with `--span`.
- Components: masthead and nav, footer, table, form and field, buttons,
  definition list, pagination, errors and hints, copy, skip link.
- View transition names and durations, with `prefers-reduced-motion` honoured.
- Everything inside a cascade layer, so an application's own unlayered CSS
  outranks it without out-specifying anything.

### Engine

- `its_swiss/shell` layout with `:title`, `:head`, `:mark`, `:nav`,
  `:main_class` and `:footer` slots.
- Partials: masthead, flash, errors, pagination.
- `ItsSwiss::FormBuilder` — one field shape, with `for`, `aria-describedby`,
  `aria-invalid` and the refused state wired every time.
- Helpers: `its_swiss_stylesheet_tags`, `nav_link_to`, `copy_button`,
  `its_swiss_form_with`, `its_swiss_page_numbers`.
- One Stimulus controller, pinned by the engine rather than by the installer.
- `its_swiss:install` generator: the theme file, the layout, the specimen route.
- `/its-swiss/specimen`, rendered twice — accent unset and accent set.

### Not in it, deliberately

- No typeface, no palette, no hue.
- No fixed grid, no `.span-N` classes, no utility classes.
- `.tag`, `.swatch` and the filter block stay in Pandatone until a second
  application asks for them.

### Unproven

`.table` and `.pagination` have **no consumer at all**. Pandatone's migration
used neither, so the only thing that has ever rendered them is the specimen.
They are in the boundary the handoff drew and they break the library's own
rule about two applications; they are the two components most likely to move
when Stripeclub lands.

*(Both of them shipped broken. See 0.2.0.)*

`.footer` is the same shape of guess — the shell has the slot and Pandatone
does not fill it.
