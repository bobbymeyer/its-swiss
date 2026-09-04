# its-swiss

A Swiss typographic style for Rails applications, in two layers.

The **core** is plain CSS and one small piece of JavaScript: tokens, faces, a
reset, typography, grid primitives, components and view transition rules. It
needs nothing but a `<link>` tag.

The **engine** ships that core through `app/assets`, plus a base layout shell,
partials, a form builder, helpers and an install generator.

It is monochrome. A six-step value scale does the work and the one accent is
the consuming application's to set — it is not a theme with the colour left
out, it is a style whose argument is that the values are enough.

```ruby
gem "its-swiss", "~> 0.1"
```

```sh
bin/rails generate its_swiss:install
```

Then open `/its-swiss/specimen`.

The current specimen is also published, for anywhere that cannot run Rails:
**[bobbymeyer.github.io/its-swiss](https://bobbymeyer.github.io/its-swiss/)**.
`bin/specimen out` writes it as one static file, and a Pages workflow does
that on every push to `main`, keeping each released version alongside the
current one at `/<version>.html` for anything that needs to pin.

## What is in the gem, and what stays in the application

| In the gem | Stays in the application |
| --- | --- |
| Tokens, reset, base typography | The grid itself — which blocks span which fields |
| Masthead, nav, footer, table, form, button, definition list, pagination | Domain components |
| A base layout shell with `content_for` slots | Page layouts beyond the shell |
| View transition names and durations | Which pages transition to which |
| The value scale and the accent slot | Any hue, any palette knowledge |
| The machine's grotesque, declared to sit on the baseline | The typeface |

A pattern enters the gem after it appears in two applications, not before.

### The boundary is the cascade, not a convention

Everything the gem ships is inside a cascade layer. An application's own CSS is
unlayered, and an unlayered rule beats every layered one whatever its
specificity — so the application always wins, without having to out-specify
anything or reach for `!important`.

```
@layer its-swiss.tokens, its-swiss.faces, its-swiss.reset, its-swiss.type,
       its-swiss.grid, its-swiss.components, its-swiss.transitions;
```

Each file declares its own layer, so linking the seven files individually (what
`its_swiss_stylesheet_tags` does) and linking the single `its-swiss.css` that
imports them resolve identically.

## The slots an application fills

`bin/rails generate its_swiss:install` writes `app/assets/stylesheets/theme.css`
holding all of them. Nothing here has a default the gem could pick honestly.

| Slot | What it is |
| --- | --- |
| `--accent`, `--accent-ink` | State and emphasis only. Unset, the accent is ink |
| `--font-family` | The typeface. The gem ships none — declare yours with `its_swiss_typeface`, and this is what a machine without it falls through to |
| `--value-chroma`, `--value-hue` | Warms the whole value scale together. Neutral as shipped |
| `--columns`, `--gutter` | How many fields this problem has |
| `--line` | The baseline: the interval everything vertical registers to |
| `--ratio` | A picture's aspect ratio, per figure — the library cannot read one |
| `--face-150`, `--face-200`, `--face-100` | Read, not set: the face a register names for its ratio of leading to size |

### The baseline

`--line` (24px) is the interval everything vertical registers to, and the
leading of the body text. In this style those are one number, because that is
what a baseline grid is: Müller-Brockmann's horizontal lines are one line of
text apart and a field is a whole number of them.

Every leading is `var(--line)` or a whole multiple of it — `--line-2`,
`--line-3`, `--line-4`, `--line-6`. Every margin, padding and gap on the
vertical axis is too. `--space-*` survives as the **horizontal** step: an
inline gap has no baseline to miss.

Boxes in step are only the easy half. Where a line's baseline falls inside its
line box is the font's decision: half the leading down, then the font's own
ascent, and the ascent is a number in the font file that the library has never
been told. A caption and a paragraph can both be in step and still be out of
register with each other, and a page on the grid in one font is off it in the
next. 0.5.0 trimmed every register to its type with `text-box-trim`, which
registered the page in the one browser that trims and left the rest to their
fonts.

So the library sets every register in a face of its own. `faces.css` declares
the machine's grotesque three times over `src: local()`, each time with its
ascent set to a ratio of leading to size and its descent and line gap set to
nothing:

```css
@font-face {
  font-family: "its-swiss-150";
  src: local("Helvetica Neue"), local("Arial"), local("Liberation Sans"), …;
  ascent-override: 150%;
  descent-override: 0%;
  line-gap-override: 0%;
}
```

A line box is then exactly the ascent tall, there is no half-leading for the
type to sit inside, and the baseline is the under edge of the line box — in
every line, whatever the font underneath, in a browser that honours the
descriptors. Chromium and Firefox do. The ladder produces three ratios and
there are three faces: body, subhead and page title are set on one and a half
times their size, the small register and the section on twice it, and the
subgrid puts the small register on its own size. A register is three
declarations, and the third is what makes the first two a grid:

```css
.micro { font-family: var(--face-200), var(--font-family); font-size: var(--size-1); line-height: var(--line); }
```

Safari loads the faces and ignores what they say about their metrics, so
there every text block is also trimmed to its type: `text-box: trim-both cap
alphabetic` makes the block's over edge the cap of its first line and its
under edge the baseline of its last, and one padding rounds the cap up to the
block's own leading —

```css
padding-block-start: calc(round(up, 1cap, 1lh) - round(1cap, 1px));
```

— measured by the browser in cap and line units, so the library still never
has to be told the font's metrics. The cap is rounded to a pixel because that
is the cap WebKit trims to, and WebKit is the browser this is for. It is
published as `--cap-correction`: a component that puts padding above its type
adds it. Only where it is needed, though, and only when told: a trimmed box
is a 64th of a pixel short as often as not on the engine the correction is
written for, and half a pixel out per block on one that trims to the exact
cap, which down a long column is a visible drift. So one line of script ahead
of the stylesheets marks the document `no-metric-overrides` where the faces
are not honoured, and the trim steps in there and nowhere else;
`its_swiss_stylesheet_tags` writes it, and anything linking the stylesheets
by hand should too:

```html
<script>if (!("ascentOverride" in FontFace.prototype)) document.documentElement.classList.add("no-metric-overrides")</script>
```

Without it the page is on the faces alone: exact in Chromium and Firefox, and
in Safari in step but not registered. The faces are the mechanism and the
trim is the fallback. Three things follow.

Anything that changes size *inside* a line — `code`, a `small`, a
superscript — is given no leading at all, so it never asks the line for room;
its glyphs still sit on the strut's baseline, which is the grid's.

No row asks the browser to find a baseline. Every box's baselines are whole
lines below its own over edge, so a row that starts its items on one line has
put their baselines on one line; `.run` aligns on `flex-start`, the masthead
and the nav on `end`, a table cell on `top`, and none of them on `baseline`,
which is a question three kinds of box answer three ways.

Text lives in text elements. The trim is asked of headings, paragraphs,
terms, cells, captions, labels, list items and definitions that hold text,
nav links, pagination, buttons — and not of the boxes that hold those, since
a box that holds blocks is trimmed through its first and last child and would
be corrected twice. Plain text dropped straight into a `<footer>` or a `<div>`
is in step and, in Safari, off the baseline; put it in a paragraph. The shell
does, for the `:footer` slot.

A control is two lines: one the type is set on, one the rule closes, with the
rule's width taken out of the second. A button is a box, two lines tall with
its label centred in it, and its label's baseline is the one baseline in the
library that is not on a line — on purpose, since a label set on the second
line of a two-line box reads as a field with a rule under it. Its keyline is
an inset shadow rather than a border, so the box is the label's line and two
paddings and nothing else. A control's own text is the one thing neither
mechanism reaches in Safari: an input, a select or a textarea cannot be
trimmed, and with the faces ignored its text sits where the font puts it, a
few pixels above the line. The box is on the grid; the type in it is the
font's until WebKit honours the descriptors.

#### Your own typeface

Declared under the same names with the same descriptors, and the helper writes
it:

```erb
<%= its_swiss_typeface regular: "inter-regular.woff2", bold: "inter-bold.woff2" %>
<%= its_swiss_typeface variable: "inter.woff2", mono: "jetbrains-mono.woff2" %>
```

Put it after the library's stylesheets. The declarations are unlayered, and a
name defined outside a layer beats the same name defined inside one — the way
the application's rules beat the library's — but a browser that resolves a
name by order rather than by layer wants it last too. `--font-family` is only
what a machine with none of the faces falls through to: the page is still
readable and still in step, and no longer registered.

The faces are the ladder's. Re-proportion `--line` or a size and the ratios
move with them, and the faces have to be declared again for the ratios the new
ladder produces.

#### The one subgrid

A block of small type may sit on a half-line — a dense run of captions, a
table of figures:

```html
<div class="subgrid">…</div>
```

It halves `--line` for the block's **children** and moves the small register
onto the face for its new ratio, and the leadings and the spacing follow. The
children, not the block: a block's own
margins belong to the column outside it and are owed whole lines. Set on the
block itself it halves the gap above it and lands the column half a line out.

A block, and only a block. An inline `<small>` shares its paragraph's line and
must not change it.


### The value scale

Six steps of OKLCH lightness, paper to ink. OKLCH because the steps have to be
perceptually even to read as a scale at all — the same arithmetic in sRGB puts
four of the six inside the top quarter of the range.

| Token | Lightness | Alias | For |
| --- | --- | --- | --- |
| `--value-0` | 98% | `--paper` | The ground |
| `--value-1` | 94% | `--paper-shaded` | A shaded ground |
| `--value-2` | 89% | `--rule` | A hairline |
| `--value-3` | 72% | `--rule-strong` | A rule that has to be seen |
| `--value-4` | 54% | `--ink-quiet` | Secondary text — 4.7:1 on paper |
| `--value-5` | 18% | `--ink` | Ink |

The ladder is deliberately not evenly spaced: a hairline has to be barely
there, so the top is dense; the middle only has to hold secondary text away
from primary, so it is sparse. An even ladder gives a usable mid-gray and no
usable rule.

Neutral as shipped. `--value-chroma: 0.006; --value-hue: 95` turns the whole
ladder to the warm grays of a printed page — and, near enough, to Pandatone's:

| Step | Warmed | Pandatone had |
| --- | --- | --- |
| `--value-0` | `#FAF8F4` | `#FAF9F7` `--ground` |
| `--value-2` | `#DCDBD6` | `#DCDAD4` `--keyline` |
| `--value-4` | `#706F6B` | `#6F6F6A` `--ink-quiet` |
| `--value-5` | `#12120F` | `#111111` `--ink` |

Within three units a channel, which is the cost of the four hand-picked
values becoming one ladder with a single chroma and a single hue. Measured in
Chromium, not calculated.

### Pictures

The one case that nearly does not transfer from print. A picture's height is
its fluid width over its ratio, so without help one picture puts the whole
column below it off the grid at every width but a few.

```html
<figure class="figure" style="--ratio: 1.618">
  <img src="…" alt="…">
  <figcaption class="micro">…</figcaption>
</figure>
```

The box is the picture's natural height taken up to the next whole line, by
`round()`, recomputed as the container resizes. The picture is fitted inside
it — `contain` by default, because a library must not crop an image it did not
choose. `.figure--cover` crops instead, which is the Müller-Brockmann move and
yours to make where you own the picture.

`--ratio` is yours to declare; CSS cannot read an intrinsic one.

### The grid

The gem ships primitives and never a grid.

```css
.page    /* the one measured container: --page-max wide, --page-inset either side */
.grid    /* repeat(var(--columns), minmax(0, 1fr)) with --gutter between */
.measure /* three fields wide */
.fields  /* --span fields wide */
.run     /* items on a shared baseline, a space apart, wrapping when they must */
.stack   /* the same, turned ninety degrees */
```

A child of `.grid` says how many fields it takes with `--span`; a child that
says nothing runs the whole field, because that is what nearly everything on a
page does.

`--field` is derived from the page rather than measured, so anything built on
it stops on a field line:

```css
--field: calc((var(--page-max) - var(--page-inset) * 2
               - var(--gutter) * (var(--columns) - 1)) / var(--columns));
--measure: calc(var(--field) * 3 + var(--gutter) * 2);
```

## The layout shell

The installer writes `app/views/layouts/application.html.erb` as a layout
**for** the shell rather than one instead of it:

```erb
<% content_for :head do %>
  <%= stylesheet_link_tag "theme", "data-turbo-track": "reload" %>
<% end %>

<% content_for :mark do %><%= link_to "Your app", root_path %><% end %>

<%= render template: "layouts/its_swiss/shell" %>
```

Nested, not `layout "its_swiss/shell"` on a controller. `content_for` has to
run while a view is rendering, and these slots are set once for the whole
application — naming the shell on the controller renders it but leaves
nowhere to fill it, so every view ends up writing the same masthead.

Note the `:head` slot links `theme.css`. The shell links the library's seven
stylesheets and stops; the accent and the grid live in yours, and nothing
links it but this.

Slots, all optional:

| Slot | |
| --- | --- |
| `:title` | Falls back to the application's name |
| `:head` | Anything else that belongs in `<head>` |
| `:mark` | The wordmark. No mark and no nav means no masthead at all |
| `:nav` | The destinations |
| `:main_class` | What the page's main region is, if it is a grid |
| `:footer` | Whatever belongs after the page |

The shell writes the view transition opt-in, the seven stylesheet links, the
importmap tags, a skip link, and the flash. It stops there — a page layout
beyond the shell is the application's, for the same reason its grid is.

## Helpers

| | |
| --- | --- |
| `its_swiss_stylesheet_tags` | The seven links, tracked for Turbo |
| `its_swiss_typeface(regular:, bold:)` | The application's typeface, declared under the library's face names |
| `nav_link_to(name, url, current:)` | A destination, with `aria-current` when you are at it |
| `copy_button(value)` | A value that copies itself |
| `its_swiss_form_with(...)` | `form_with`, already holding the library's builder |
| `its_swiss_page_numbers(page, pages)` | Which numbers a run of them shows, elided |

### Pagination

The library has no paginator and no opinion about which one you use — it takes
a page, a total, and something that turns a number into a URL:

```erb
<%= render "its_swiss/shared/pagination",
      page: @page, pages: @pages, url: ->(n) { colors_path(page: n) } %>
```

Long runs are elided around the current page. `window:` (default 2) sets how
many neighbours show; `label:` names the `<nav>` for a screen reader.

## The form builder

One shape for every field: a label, a control, and — when there is something to
say — a hint or the reason it was refused.

```erb
<%= its_swiss_form_with model: @palette do |form| %>
  <%= form.text_field :name, hint: "As it appears in the nav." %>
  <%= form.check_box :published %>
  <%= form.submit "Save" %>
<% end %>
```

It exists because the parts that get left out by hand are the parts nobody
sees missing: a label whose `for` does not match its input does not enlarge the
target; a hint beside a control is a hint a screen reader never reaches; a
refused field coloured by CSS alone is a refusal only some readers get. The
builder wires `for`, `aria-describedby`, `aria-invalid` and `.field--invalid`
every time.

`label: false` hides the label rather than removing it — the name moves onto
the control as `aria-label`.

## The specimen

`/its-swiss/specimen`, mounted by the installer under `if Rails.env.development?`
and refused a second time by the controller, because a route is a line in a file
someone can move.

It renders every component, the type scale, the value scale and the grid
primitives — **twice**. The first take is the library exactly as it ships, with
the accent collapsed onto ink; the second sets an accent and changes nothing
else. If the first reads correctly, the value scale is doing the work.

It is the documentation and the regression fixture.

## Tests

```sh
bin/test                                     # everything; browser tests skip
CHROME_BINARY=... CHROMEDRIVER=... bin/test   # including the browser tests
bin/specimen tmp/specimen && node test/browsers/grid.mjs tmp/specimen/index.html   # chromium, webkit, firefox
```

Tests come first, and a guard is only kept if removing what it guards makes it
fail.

Most of the suite reads the CSS rather than rendering it, which is enough for
the decisions that are decisions about the source: that the value scale is a
descending ladder, that no stylesheet invents a colour or a column count, that
every line box is measured in baselines, that no signal rests on colour alone.

The rest needs a browser, because a rule on the wrong selector reads correctly
in the CSS and does nothing on a page. Those assert what Chromium actually
resolved: that an unlayered declaration beats the library's layered one, that
the accent unset is ink, that quiet ink clears 4.5:1, that every box on the
specimen starts and ends on a line, that every run of type on it has its
baseline on one, that nothing escapes the page at 390px, and that the measure
lands on a field line the browser really laid out. They skip loudly rather
than pretending to have checked.

The two grid questions are one function, `test/support/on_the_grid.js`, and
`test/browsers/grid.mjs` asks it of the published specimen in Chromium, WebKit
and Firefox through Playwright. CI runs all three; a grid checked in one
browser is a claim about that browser. Chromium is also asked with the faces
taken away and the document marked, which is the page as Safari lays it out,
so the trim is measured on every push and not only in the one job that has
WebKit.

There are no pixel tests.

## Coming from Pandatone

The token names changed where the boundary moved. The value scale is the same
ladder; the names are the library's rather than the application's.

| Pandatone | its-swiss |
| --- | --- |
| `--ground` | `--paper` |
| `--keyline` | `--rule` |
| `--ink-quiet`, `--ink` | unchanged |
| `--accent` | unchanged — still the application's to set |
| `--font` | `--font-family` |
| `--size-1..5`, `--space-N`, `--measure`, `--page-max` | unchanged |
| `--baseline` (8px) | **gone.** `--line` (24px) is the baseline now — see 0.4.0 |
| `.masthead__nav` | `.nav` |
| `.channels` | `.pairs` |
| `.form`, `.field`, `.button*`, `.copy`, `.errors`, `.hint`, `.empty` | unchanged |
| `--columns-dense`, `--card`, `--card-wide`, `.swatch*`, `.tag*`, `.filter*` | stay in Pandatone |

Two behavioural differences to know about:

- **The masthead no longer sits on the page's field.** It lays itself out in
  flex, so it does not break when an application changes `--columns`.
- **`--field` now subtracts the page's own inset** before dividing. Pandatone's
  `--measure` was a gutter and a half wider than three fields; anything relying
  on the old number moves in by 24px.
- **`.button--danger` is set apart by a step on the ladder, not an auto
  margin.** Pandatone scoped the auto margin to two named regions; a library
  cannot, and an auto margin across a whole page reads as a different control
  rather than a separated one.

## Versioning

Semver with a changelog. Consumers pin `~> 0.1`.

`0.1.0` ships with one consumer — Pandatone — and that is what the leading
zero is for: the boundary was drawn from one real application and the second
has not been built yet. The surface will move. Read `CHANGELOG.md` before
upgrading, and see `RELEASING.md` for how a version gets out.

## License

MIT.
