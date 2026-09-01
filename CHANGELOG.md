# Changelog

Semver. Consumers pin `~> 0.1`.

## Unreleased

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

- **Every browser test was skipping in CI.** The suite looks for a browser and
  a driver, and a candidate found on the `PATH` came back as the bare name it
  was looked up by. Selenium wants a file — given `"chromedriver"` it raises
  *not a file* — so the harness caught that, fell back to `rack_test` and
  skipped, on a runner that had just installed a driver for it. The job was
  green and had checked nothing: 12 runs, 12 skips. Candidates now resolve to
  where they actually are, and the CI job sets `REQUIRE_BROWSER`, which turns
  a skip into a failure — a skipped browser test is invisible in a passing
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

## 0.2.0 — 2026-08-31

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
