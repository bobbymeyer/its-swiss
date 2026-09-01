# its-swiss

A Swiss typographic style for Rails applications, in two layers.

The **core** is plain CSS and one small piece of JavaScript: tokens, a reset,
typography, grid primitives, components and view transition rules. It needs
nothing but a `<link>` tag.

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

## What is in the gem, and what stays in the application

| In the gem | Stays in the application |
| --- | --- |
| Tokens, reset, base typography | The grid itself — which blocks span which fields |
| Masthead, nav, footer, table, form, button, definition list, pagination | Domain components |
| A base layout shell with `content_for` slots | Page layouts beyond the shell |
| View transition names and durations | Which pages transition to which |
| The value scale and the accent slot | Any hue, any palette knowledge |
| A fallback grotesque stack | The typeface |

A pattern enters the gem after it appears in two applications, not before.

### The boundary is the cascade, not a convention

Everything the gem ships is inside a cascade layer. An application's own CSS is
unlayered, and an unlayered rule beats every layered one whatever its
specificity — so the application always wins, without having to out-specify
anything or reach for `!important`.

```
@layer its-swiss.tokens, its-swiss.reset, its-swiss.type,
       its-swiss.grid, its-swiss.components, its-swiss.transitions;
```

Each file declares its own layer, so linking the six files individually (what
`its_swiss_stylesheet_tags` does) and linking the single `its-swiss.css` that
imports them resolve identically.

## The slots an application fills

`bin/rails generate its_swiss:install` writes `app/assets/stylesheets/theme.css`
holding all of them. Nothing here has a default the gem could pick honestly.

| Slot | What it is |
| --- | --- |
| `--accent`, `--accent-ink` | State and emphasis only. Unset, the accent is ink |
| `--font-family` | The typeface. The gem ships none — declare `@font-face` and name it |
| `--value-chroma`, `--value-hue` | Warms the whole value scale together. Neutral as shipped |
| `--columns`, `--gutter`, `--baseline` | How many fields this problem has, and the unit everything vertical is measured in |
| `--cap-correction` | Read, not set: what a trimmed register adds above its cap to reach the next baseline |

### The baseline

Everything vertical is measured in baselines, and the type sits on them rather
than merely in step with them.

Boxes in step are the easy half: line boxes and spacing are whole numbers of
`--baseline`, so blocks that start together stay together down the column.
That alone is not a baseline grid — where a line's baseline falls inside its
line box depends on the font's ascent and the leading either side of it, so a
caption and a paragraph can both be in step and still be three pixels out of
register with each other.

So every text register is trimmed to its own type: `text-box: trim-both cap
alphabetic` makes a block's over edge the cap of its first line and its under
edge the baseline of its last, and one padding rounds the cap height up to the
next baseline —

```css
padding-block-start: calc(round(up, 1cap, var(--baseline)) - 1cap);
```

— which the browser computes in cap units, so the library still never has to
be told the font's metrics. It is published as `--cap-correction`: a component
that sets its own padding on trimmed text adds it, as
`calc(var(--space-1) + var(--cap-correction))`, which is the right padding
whether or not the browser trims.

Two things opt out, with `text-box: normal; padding-block-start: 0`: a control,
whose box is the target and whose label is centred in it, and any block whose
content is not type — an image, a swatch, a diagram.

It is behind `@supports`, and the fallback is the box rhythm above. Chromium
and Safari trim; Firefox does not yet. The two do not render identically:
trimming takes the leading out of a block's own box, so a trimmed page is a
few pixels tighter per block and the ladder means what it says rather than
what it says plus half a line. Both stay on the grid.

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

Note the `:head` slot links `theme.css`. The shell links the library's six
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

The shell writes the view transition opt-in, the six stylesheet links, the
importmap tags, a skip link, and the flash. It stops there — a page layout
beyond the shell is the application's, for the same reason its grid is.

## Helpers

| | |
| --- | --- |
| `its_swiss_stylesheet_tags` | The six links, tracked for Turbo |
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
bin/test                                  # everything; browser tests skip
CHROME_BINARY=... CHROMEDRIVER=... bin/test   # including the browser tests
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
specimen starts on a baseline and is a whole number of them tall, that every
register's last baseline lands on one, that nothing escapes the page at 390px,
and that the measure lands on a field line the browser really laid out. They
skip loudly rather than pretending to have checked.

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
| `--size-1..5`, `--space-N`, `--baseline`, `--measure`, `--page-max` | unchanged |
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
