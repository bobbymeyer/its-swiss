# Changelog

Semver. Consumers pin `~> 0.1`.

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
