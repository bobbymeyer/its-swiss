# Pandatone — Handoff

its-swiss exists. Pandatone is its first consumer, and the job now is to
delete what was extracted and take it from the gem instead.

The gem is on `main` at `github.com/bobbymeyer/its-swiss`. Nothing is tagged
yet, so develop against `path: "../its-swiss"` and cut `0.1.0` when both
consumers ship on it.

## What was extracted

| Layer | Contents |
| --- | --- |
| Core | Six plain-CSS files — tokens, reset, type, grid primitives, components, transitions — each inside a cascade layer |
| Engine | `its_swiss/shell` layout, masthead/flash/errors/pagination partials, `ItsSwiss::FormBuilder`, five helpers, one Stimulus controller, an install generator |
| Specimen | `/its-swiss/specimen` — every component, the type scale, the value scale, the grid primitives, rendered twice |

Read `README.md` for the whole surface. Three things changed in the move and
they are the reason this is a handoff rather than a find-and-replace.

**The value scale is re-founded.** Four hand-picked grays became six OKLCH
lightness steps, neutral, with `--value-chroma` and `--value-hue` as the
slots that warm them. At `0.006 / 95` the ladder lands within three units a
channel of Pandatone's — measured in Chromium, not calculated.

**The boundary is the cascade.** Everything the gem ships is layered and
Pandatone's own CSS is not, so Pandatone wins every conflict without
out-specifying anything or reaching for `!important`. Nothing needs a
`:root:root` and nothing needs a bang.

**The gem ships no typeface and no palette.** Archivo stays here, as an
`@font-face` and a `--font-family` in Pandatone's own stylesheet, for the same
reason `--accent` always did.

## The ask

Replace Pandatone's tokens, reset, typography, shared components and layout
with the gem. Keep the grid, the swatch, the tag, the filter block and every
other thing that is about colors.

Rule for what stays: **if it knows what a swatch is, it is Pandatone's.**

## Order of operations

One commit per step, each with its spec, in this order. The suite should be
green at every one of them.

| Step | Do |
| --- | --- |
| 1 | `gem "its-swiss", path: "../its-swiss"`. Nothing else. `bin/rails test:all` still green |
| 2 | Tokens and reset: delete `base.css`, move what stays into `theme.css`. Rename tokens |
| 3 | Type: delete `type.css` bar Pandatone's own registers. Move `@font-face` to `theme.css` |
| 4 | Components, one at a time — masthead, buttons, forms, errors, copy |
| 5 | The layout: `application.html.erb` becomes slots on the shell |
| 6 | The grid: point Pandatone's lists at `.grid`, delete the duplicate track declarations |
| 7 | Rewrite `test/assets/grid_test.rb` down to what is still Pandatone's to guard |

`bin/rails generate its_swiss:install` writes `theme.css`, the layout line and
the specimen route. Run it at step 1 and fill the file in as you go, rather
than writing it by hand.

## Renames

Tokens appear in `app/assets/stylesheets` and in **no view** — all ten of them.
So this is confined to four files.

| Pandatone | its-swiss | Uses |
| --- | --- | --- |
| `--ground` | `--paper` | 3 |
| `--keyline` | `--rule` | 9 |
| `--font` | `--font-family` | 2 |
| `--ink`, `--ink-quiet`, `--accent` | unchanged | 37 |
| `--size-1..5`, `--space-N`, `--baseline`, `--measure`, `--page-max`, `--gutter`, `--columns` | unchanged | — |
| `--columns-dense`, `--card`, `--card-wide`, `--register-label` | stay in Pandatone | — |

Classes, which do appear in views:

| Pandatone | its-swiss | Where |
| --- | --- | --- |
| `.masthead__nav` | `.nav` | the layout only |
| `.page-lede` | `.lede` | 12 views |
| `.channels` | `.pairs` | 2 views; keep a `.channels` modifier for what is domain about it |
| `.radio` | `.choice` | `shared/_swatch_fields`, `palettes/colors/new` |
| `.page-title`, `.hint`, `.empty`, `.errors`, `.link-quiet`, `.button*`, `.copy`, `.form`, `.field` | unchanged | — |

`.page-lede` is a `sed` across twelve files, or one rule in `theme.css` if you
would rather not touch them. Prefer the `sed` — an alias is a name the app has
to keep explaining.

## What the gem now says for you

Delete these from Pandatone and take the gem's version:

| Gone | Note |
| --- | --- |
| `base.css` entirely | Except `overflow-wrap: anywhere` on `body` — that is about free-text swatch names and stays |
| The type scale, `body`, `h2`, `h3`, `.page-title`, `.hint`, `code` | The registers Pandatone adds to stay |
| `.masthead`, `.masthead__mark`, `.masthead__nav` | The gem's masthead is flex, not on the field — see below |
| `.form`, `.form--inline`, `.field`, `.field input` | `.field--channel` and `.field--picker` stay |
| `.button` and all four modifiers, `.link-quiet`, `.copy` | `.hex` stays and keeps wearing `.copy` |
| `.errors`, `.errors__title`, `.errors ul`, `.empty` | `.warning` stays; it is a question about swatches |
| `shared/_flash`, `shared/_errors` | The shell renders flash itself; errors is `its_swiss/shared/errors` |
| `transitions.css` entirely | The swatch morph names are set per element in `SwatchesHelper` and stay |
| `SwatchesHelper#copy_button` | `hex_tag` keeps working — it calls the gem's now |

Two rules in `components.css` get **shorter** rather than deleted:

- The row rule lists twenty-two selectors. Drop `.masthead__nav`; keep the
  other twenty-one. (Or put `class="run"` in the markup and delete them, but
  that is a bigger change than this step needs.)
- The quiet register lists sixteen. Drop `.button--quiet`, `.button--danger`,
  `.empty` and `.errors ul` — the gem says those. Keep the eleven that are
  about swatches, tags and palettes.
- The micro register: drop `.field label`, `.mode-toggle legend` and
  `.source-toggle legend`. The gem sets bare `label` and `legend` in micro, so
  those come free. `.filter-row__label` and `.export__label` are spans and stay.

## The layout

`application.html.erb` becomes slots:

```erb
<% content_for :title, "Pandatone" %>
<% content_for :head do %>
  <link rel="icon" href="/icon.png" type="image/png">
  <link rel="preload" href="<%= asset_path("archivo-variable-latin.woff2") %>"
        as="font" type="font/woff2" crossorigin>
<% end %>
<% content_for :mark do %>
  <span class="masthead__panda" aria-hidden="true">🐼</span><%= link_to "Pandatone", root_path %>
<% end %>
<% content_for :nav do %>
  <%= nav_link_to "Colors", colors_path %>
  <%= nav_link_to "Palettes", palettes_path %>
  <%= nav_link_to "Lookup", lookup_path %>
  <%= nav_link_to "Account", account_path if authenticated? %>
<% end %>
<% content_for :main_class, "grid" %>
```

`layout "its_swiss/shell"` on `ApplicationController` and the file itself goes.
The `<meta name="view-transition">` tag, the stylesheet links, the importmap
tags and a skip link are the shell's now.

`nav_link_to` gives you `aria-current="page"`, which the old nav did not have,
and the gem colours and weights it. A destination is current when
`current_page?` says so — pass `current:` where that is wrong, which it will be
on `/palettes/12`.

## Four things that will actually break

**1. The masthead comes off the field.** Pandatone put the mark in fields 1–2
and the nav from field 3. A component that places itself on the app's grid
breaks the moment the app changes `--columns`, so the gem's masthead is flex.
The nav will start beside the wordmark instead of on the third field line. If
that reads wrong, put it back in `theme.css` — unlayered, so it wins:

```css
.masthead { display: grid; grid-template-columns: repeat(var(--columns), minmax(0, 1fr)); column-gap: var(--gutter); }
.masthead__mark { grid-column: 1 / span 2; }
.masthead .nav { grid-column: 3 / -1; }
```

Keep the 34rem stack rule either way.

**2. `--measure` narrows by 24px.** Pandatone derived `--field` from
`--page-max` without subtracting the page's own inset, so the measure was a
gutter and a half wider than three fields — prose that was meant to stop on
the third field line stopped past it. The gem subtracts it. `page_width_test`
and `field_placement_test` measure this; the numbers move and the new ones are
the right ones.

**3. Flash moves.** Pandatone renders `shared/flash` inside six pages —
registrations, sessions, both passwords, account, people — in the form column.
The shell renders it once at the top of `main`. Delete the six calls.
`sign_in_test`, `sign_up_test`, `account_test` and `people_test` assert on it;
check whether any of them assert it is *inside* something.

**4. `.button--danger` is set apart by `--space-6`, not `margin-inline-start:
auto`.** Pandatone scoped the auto margin to `.swatch-detail__controls` and
`.page-actions`; a library cannot scope it to two named regions, and an auto
margin across a whole page reads as a different control rather than a
separated one. `button_test` guards the gap — it should still pass, but the
distance changed.

## Tests

`test/assets/grid_test.rb` is where most of the churn is. Its guards about
tokens, the type ladder, the micro register, the destructive register and the
copy affordance now live in the gem's own suite and should be **deleted here,
not duplicated** — a guard on someone else's file is a guard that goes stale
without failing.

What stays Pandatone's to guard: `--columns: 6` and `--columns-dense: 12`,
`--card` / `--card-wide`, the small-list density, and that no *Pandatone*
stylesheet invents its own column count.

These will need looking at:

| File | Why |
| --- | --- |
| `test/assets/grid_test.rb` | Most of it moved |
| `test/system/navigation_test.rb` | Nav markup, the font preload, the masthead |
| `test/system/page_width_test.rb`, `field_placement_test.rb` | The measure moved |
| `test/system/button_test.rb` | The danger gap |
| `test/system/sign_in_test.rb`, `sign_up_test.rb`, `account_test.rb` | Flash placement |
| `test/system/heading_outline_test.rb` | The shell's skip link is new markup before the mark |

The morph tests should not move at all. The transition *names* are Pandatone's
and always were.

## Step 6, if you get that far

Pandatone already says the field's tracks once, for five selectors —
`.grid`, `.palette-list`, `.color-list`, `.color-detail`, `.lookup-result` —
which was the right call when they were all in one file. Now the gem ships
`.grid`. Putting `class="grid"` on those four lists and deleting the local
declaration leaves `.list--small` as the only track definition Pandatone still
owns, which is correct: a second density is Pandatone's problem and always
was. It is the one place the extraction makes Pandatone smaller rather than
merely different.

The `--span` convention replaces the explicit spans:

```css
.page-head { --span: 4; }
.palette-list > * { --span: var(--card-wide); }
.color-list > * { --span: var(--card); }
```

A child that says nothing runs the whole field, which is what
`main.grid > *` already meant.

## Done when

- `bin/rails test:all` green
- `SYSTEM_TEST_DRIVER=selenium bin/rails test:system` green
- `/its-swiss/specimen` renders in development
- Deleting `--accent` from `theme.css` leaves an app that still reads

The last one is the point of the whole exercise. If it fails, the values are
not doing the work and something moved that should not have.

Then Stripeclub, and `0.1.0` when both are on it.
