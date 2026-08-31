# Changelog

Semver. Consumers pin `~> 0.1`.

## 0.1.0 — 2026-08-31

The first extraction, from Pandatone.

Cut before either consumer has shipped on it, which is what the leading zero
is for: the boundary was drawn from one real application and a second has not
tested it yet. Expect the surface to move. Pin `~> 0.1` and read this file
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

`.table` and `.pagination` have one consumer between them and no second
application to check them against yet. They are in the boundary the handoff
drew, and they are the two components most likely to move when Stripeclub
lands.
