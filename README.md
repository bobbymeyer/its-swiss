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
gem "its-swiss", "~> 1.0"
```

```sh
bin/rails generate its_swiss:install
```

Then open `/its-swiss/specimen`.

The current specimen is also published, for anywhere that cannot run Rails:
**[bobbymeyer.github.io/its-swiss](https://bobbymeyer.github.io/its-swiss/)**.
`bin/specimen out` writes it as one static file, and a Pages workflow does
that on every push to `main`; the versions kept in `published/` are copied
alongside it at `/<version>.html` for anything that needs to pin.

## What is in the gem, and what stays in the application

| In the gem | Stays in the application |
| --- | --- |
| Tokens, reset, base typography | The grid itself — which blocks span which fields |
| Masthead, nav, page head, footer, table, form, button, definition list, pagination, filters, cards | Domain components |
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
| `--module` | A field's height, in lines: what divides the page down |
| `--measure-characters` | How many characters a line of prose holds; the grid is what it stops on |
| `--ratio` | A picture's aspect ratio, per figure — the library cannot read one |
| `--card` | How many fields a card takes, and at which widths |
| `--filter-label` | The column a filter's label occupies, so every register's choices start on one line |
| `--face-150`, `--face-200`, `--face-100` | Read, not set: the face a register names for its ratio of leading to size |

### The baseline

`--line` (24px) is the interval everything vertical registers to, and the
leading of the body text: one number, because that is what a baseline grid
is. Every leading, margin, padding and gap on the vertical axis is a whole
number of lines; `--space-*` is the horizontal step.

Every baseline is the under edge of its line box, two ways. The library sets
every register in a face of its own, the machine's grotesque declared again
with its ascent set to the register's ratio of leading to size and no
descent, which Chromium and Firefox honour. Where a browser ignores what a
face says about its metrics, Safari, every text block is trimmed to its type
instead, and one line of script ahead of the stylesheets says which is in
force. `its_swiss_stylesheet_tags` writes it; anything linking the
stylesheets by hand should too:

```html
<script>if (!("ascentOverride" in FontFace.prototype)) document.documentElement.classList.add("no-metric-overrides")</script>
```

The whole argument, and what follows from it, is in `DESIGN.md`.

#### Your own typeface

Declared under the same names with the same descriptors, and the helper writes
it:

```erb
<%= its_swiss_typeface regular: "inter-regular.woff2", bold: "inter-bold.woff2" %>
<%= its_swiss_typeface variable: "inter.woff2", mono: "jetbrains-mono.woff2" %>
<%= its_swiss_typeface variable: "inter.woff2", family: "Inter" %>
```

Put it after the library's stylesheets. `family:` declares the typeface under
its own name as well, which a control's text is set in; `--font-family` is
what a machine with none of the faces falls through to.

#### The one subgrid

A block of small type may sit on a half-line:

```html
<div class="subgrid">…</div>
```

It halves `--line` for the block's **children** and moves the small register
onto the face for its new ratio. A block, and only a block: an inline
`<small>` shares its paragraph's line.

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
.page     /* the one measured container: --page-max wide, --page-inset either side, and the container a field is measured in */
.grid     /* repeat(var(--columns), minmax(0, 1fr)) with --gutter between */
.measure  /* the measure: --measure-characters of the type, stopped on a field line */
.fields   /* --span fields wide */
.modules  /* --modules modules tall */
.run      /* items on a shared baseline, a space apart, wrapping when they must */
.stack    /* the same, turned ninety degrees */
```

A child of `.grid` says how many fields it takes with `--span`; a child that
says nothing runs the whole field. `--span` is registered not to inherit, so a
grid inside a spanned item starts its own children on the whole field.

A field is the page's actual width, less the gutters, divided, measured in
container units from the `.page` the fields are laid out in:

```css
--field: calc((100cqw - var(--gutter) * (var(--columns) - 1)) / var(--columns));
```

The measure is a count of characters, and the grid is what it stops on:
`--measure-characters` (65) in the type's own font, taken up to the nearest
whole run of fields, and never past the page. The module is a field's height
in lines, `--module` (6): the columns divide the page across and the module
divides it down, and `.modules` and `.figure--modular` size a block or a
picture to whole ones.

### The page head

What a page is and what can be done to it, in one shape on every page: the
title in the page-title register, its lede when it has one, and the actions in
a run beside them, wrapping under the title when the page is narrow.

```erb
<%= page_head "Palettes", lede: "Every palette in the library." do %>
  <%= link_to "New palette", new_palette_path, class: "button button--primary" %>
<% end %>
```

The document is titled from it unless the view has already set `:title`.

A page with several surfaces — what a thing is made of, what it wears, how it
leaves — names them under the title with `sections:`, each a name, a URL and
whether it is the one shown, and shows that one alone. A working page must
not scroll: what is done daily is reached from the head, in the same position
on every page.

```erb
<%= page_head @pattern.name, sections: [ [ "Compose", pattern_path(@pattern), @section == "compose" ],
                                         [ "Dress", pattern_path(@pattern, section: "dress"), @section == "dress" ] ] do %>
```

### Explanations

What a section means, behind one word. A sentence over every table is needed
on the first day and never again, and a tool used daily is read on every
other day; so `explain` writes it in the hint register, closed, and the word
"About" in the small register opens it. `label:` says another word.

```erb
<%= explain "The repeat, in order along the stripe normal." %>
```

### Filters and cards

What narrows a list, and the list. A search that filters as you type, and a
register for each other way of narrowing it — a tag, an order, a size — in the
same two positions every time: a quiet label, then the choices, the one in
force carrying `aria-current`, which the CSS sets in the weight. In ink, not
the accent: the accent is for where you are on the site and for the one
thing that cannot be undone, and a page has one red.

```erb
<div class="filters">
  <%= search_form palettes_path, frame: "palettes", keep: { tag: params[:tag], sort: params[:sort] } %>
  <%= filter_register "Tagged", [ [ "All", palettes_path, params[:tag].blank? ],
                                  *tags.map { |t| [ t, palettes_path(tag: t), params[:tag] == t ] } ],
        name: "tag" %>
</div>

<%= turbo_frame_tag "palettes", target: "_top" do %>
  <ul class="grid cards">
    <li class="card">
      <a class="card__link" href="…">
        <figure class="card__figure figure" style="--ratio: 1.5"><img src="…" alt=""></figure>
        <span class="card__name">Brand Core</span>
      </a>
      <span class="card__meta">4 swatches</span>
    </li>
  </ul>
<% end %>
```

The search form belongs outside the frame it fills, so only the results are
replaced and the field keeps its cursor. `keep:` carries the other choices as
hidden fields, so a search does not drop the tag or the order you were reading
in. The button is there for a browser that runs no script; the controller
takes it away once it has connected.

A card is `--card` fields wide on the page's own grid — say how many once, and
again at each width that changes it. The picture is a `.figure` with its
`--ratio` declared, so its box is whole lines at any width and the name under
it stays on the grid.

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
stylesheets and the module that registers its controllers, and stops; the
accent and the grid live in yours, and nothing links it but this.

Slots, all optional:

| Slot | |
| --- | --- |
| `:title` | Falls back to the application's name |
| `:head` | Anything else that belongs in `<head>` |
| `:mark` | The wordmark. No mark and no nav means no masthead at all |
| `:nav` | The destinations |
| `:subnav` | A second layer of destinations, inside the one you are in: a shaded band under the masthead |
| `:main_class` | What the page's main region is, if it is a grid |
| `:footer` | Whatever belongs after the page |

The shell writes the view transition opt-in, the seven stylesheet links, the
importmap tags, the library's JavaScript module, a skip link, and the flash. It stops there — a page layout
beyond the shell is the application's, for the same reason its grid is.

## Helpers

| | |
| --- | --- |
| `its_swiss_stylesheet_tags` | The seven links, tracked for Turbo, and the metric-override mark with the page's nonce |
| `its_swiss_typeface(regular:, bold:)` | The application's typeface, declared under the library's face names |
| `nav_link_to(name, url, current:)` | A destination, with `aria-current` when you are at it |
| `nav_menu(label, current:) { links }` | A destination that opens into destinations, with no script |
| `copy_button(value)` | A value that copies itself |
| `its_swiss_form_with(...)` | `form_with`, already holding the library's builder, at the measure |
| `its_swiss_page_numbers(page, pages)` | Which numbers a run of them shows, elided |
| `page_head(title, lede:, sections:) { actions }` | The one shape every page opens with |
| `page_sections(sections)` | The surfaces of one page, the one shown in the weight |
| `explain(text, label:) { }` | What a section means, behind one word |
| `filter_register(label, choices, name:)` | One register of a filter block |
| `search_form(url, frame:, keep:)` | A search that narrows a list as you type |

### Pagination

The library has no paginator and no opinion about which one you use — it takes
a page, a total, and something that turns a number into a URL:

```erb
<%= render "its_swiss/shared/pagination",
      page: @page, pages: @pages, url: ->(n) { colors_path(page: n) } %>
```

Long runs are elided around the current page. `window:` (default 2) sets how
many neighbours show; `label:` names the `<nav>` for a screen reader.

### JavaScript

Two Stimulus controllers, pinned by the engine, and a module that registers
them with the host's Stimulus application, which the shell imports. A host
has nothing to write; one that registers the two by hand still can, and
registering them twice is harmless. `copy_button` and `search_form` write
the `data-controller` attributes; a page without script still works, with
the value selectable and the search's button on the page.

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
the control as `aria-label`. A textarea's `rows:` is how many lines tall it
is. `class: "form form--dense"` puts each label on its control's line of
air, three lines a field rather than four, for a form of many fields.

A control's rule is the strong rule at rest, ink under the hand, and the
accent, heavy, when the control has the focus or has been refused. The focus
is the rule, not a box.

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
| `--space-5`, `--space-13`, `--line-6` | **gone** in 1.0.0: nothing in the library used them. `--space-6`, `--space-8` and `--line-4` remain |
| `.masthead__nav` | `.nav` |
| `.channels` | `.pairs` |
| `.form`, `.field`, `.button*`, `.copy`, `.errors`, `.hint`, `.empty` | unchanged |
| `.tag*`, `.filter*`, `.page-head`, `live-search` | `.filter*`, `.page-head`, `.cards`, `its-swiss-live-search` — in the gem since 0.8.0 |
| `--columns-dense`, `--card-wide`, `.swatch*` | stay in Pandatone |

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

Semver with a changelog. Consumers pin `~> 1.0`.

1.0.0 is the surface three applications settled on, and what changes it now
changes a major. Read `CHANGELOG.md` before upgrading, and see `RELEASING.md`
for how a version gets out.

## License

MIT.
