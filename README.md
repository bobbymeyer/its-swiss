# its-swiss

sensible Swiss defaults for Rails

Tokens, reset, typography, grid primitives and components in the spirit of the
International Typographic Style, as plain CSS plus a Rails engine that ships
it. Monochrome by default: the value scale does the work, and the one accent
is the consuming application's to set.

## quickstart

```ruby
# Gemfile
gem "its-swiss", github: "bobbymeyer/its-swiss"
```

```sh
bundle install
bin/rails generate its_swiss:install
```

The generator fills the four slots an application owns:

| It writes | Which is |
| --- | --- |
| `app/assets/stylesheets/theme.css` | The accent, the typeface, the value scale, the field count, the baseline |
| `app/views/layouts/application.html.erb` | A nested layout inside the shell — no `layout` line on any controller |
| A route for the specimen | Development only; skipped if already mounted |

Everything else is a gem dependency: Propshaft finds the stylesheets, and the
engine pins its own JavaScript, so upgrading the gem is enough.

[**Specimen →**](https://bobbymeyer.github.io/its-swiss/) — every component,
the type scale, the value scale and the grid primitives, rendered by the
library and published from this repository.

## the shell

`layouts/its_swiss/shell` carries the view-transition opt-in, the stylesheets
in layer order, a skip link, and the slots. All optional:

| Slot | Is |
| --- | --- |
| `:title` | The page's title; falls back to the application's name |
| `:head` | Anything else belonging in `<head>` |
| `:mark` | The wordmark. No mark and no nav means no masthead at all |
| `:nav` | The destinations |
| `:subnav` | A second layer, inside the one you are in |
| `:main_class` | What the page's main region is, if it is a grid |
| `:footer` | Whatever belongs after the page |

It stops there. A page layout beyond the shell is the application's, for the
same reason its grid is.

## tokens

Set in `theme.css`; everything else reads them.

| Group | Custom properties |
| --- | --- |
| Value scale | `--value-chroma`, `--value-hue`, `--value-0` … `--value-5` |
| Roles | `--paper`, `--paper-shaded`, `--rule`, `--rule-strong`, `--ink-quiet`, `--ink`, `--accent`, `--accent-ink` |
| Rules | `--rule-hair`, `--rule-heavy` |
| Type | `--font-family`, `--font-mono`, `--face-100`, `--face-150`, `--face-200`, `--face-mono`, `--cap-correction` |
| Scale | `--size-1` … `--size-5` |
| Baseline | `--line`, `--line-2`, `--line-3`, `--line-4`, `--half-line`, `--module` |
| Space | `--space-unit`, `--space-1`, `--space-2`, `--space-3`, `--space-4`, `--space-6`, `--space-8` |
| Page | `--columns`, `--gutter`, `--page-max`, `--page-inset`, `--field` |
| Measure | `--measure`, `--measure-characters`, `--card`, `--filter-label` |
| Transitions | `--transition-page`, `--transition-morph`, `--transition-ease` |

## grid primitives

`.page`, `.grid`, `.run`, `.stack`, `.modules`, `.fields`, `.measure`.

## components

| Class | Is |
| --- | --- |
| `.masthead`, `.nav`, `.subnav`, `.menu`, `.menu--current`, `.skip-link` | Navigation |
| `.page-head`, `.sections`, `.footer` | Page furniture |
| `.button`, `.button--primary`, `.button--quiet`, `.button--danger` | Buttons |
| `.form`, `.form--inline`, `.form--dense`, `.field`, `.field--inline`, `.field--invalid`, `.choice`, `.errors` | Forms |
| `.filters`, `.filter` | Filter bars |
| `.cards`, `.card` | Cards |
| `.table`, `.numeric` | Tables |
| `.pairs`, `.pairs--stacked` | Definition pairs |
| `.figure`, `.figure--cover`, `.figure--modular` | Figures |
| `.pagination` | Pagination |
| `.md`, `.measure`, `.copy`, `.explain`, `.link-quiet`, `.empty` | Prose and states |
| `.css`, `.components`, `.visually-hidden`, `.no-metric-overrides`, `.rule--heavy` | Utilities |

## helpers

| Helper | Does |
| --- | --- |
| `its_swiss_form_with` | The form builder |
| `its_swiss_stylesheet_tags` | The seven stylesheets, in layer order |
| `its_swiss_page_numbers` | Page numbers for pagination |
| `its_swiss_application_name` | The application's name |
| `its_swiss_face`, `its_swiss_typeface` | The typeface slots |
| `page_head`, `page_sections` | Page head and section destinations |
| `nav_link_to`, `nav_menu` | Navigation |
| `search_form`, `filter_register` | Filter bars |
| `copy_button` | A value that copies itself |
| `explain` | An explanatory note |

Partials: `its_swiss/shared/masthead`, `flash`, `errors`, `pagination`.

### form builder

`its_swiss_form_with` adds `field`, `select`, `collection_select`,
`check_box`, `radio_button`, `text_area` and `submit`, each rendering its own
label, hint and error, wired with `aria-describedby`.

## JavaScript

Three Stimulus controllers, registered by the module the shell imports. The
host adds nothing to its importmap.

| Controller | Does |
| --- | --- |
| `its-swiss-clipboard` | A value that copies itself |
| `its-swiss-live-search` | Search on an index |
| `its-swiss-mono` | Monospace metric handling |

## the cascade

Every file states its own layer, and the order is declared before the first
import:

```css
@layer its-swiss.tokens, its-swiss.faces, its-swiss.reset, its-swiss.type,
       its-swiss.grid, its-swiss.components, its-swiss.transitions;
```

Everything is inside `@layer`, so any application rule wins without effort. A
stylesheet the application adds after the library takes its place in the order
from where its layer is first named.

`its-swiss.css` is the whole library in one `<link>`; the Rails helper writes
the seven separately. Both resolve identically.

## tech

Rails engine, v1.0.0. Ruby >= 3.2. 1,475 lines of CSS in seven files. No
build step and no CSS framework.

```sh
bundle exec rake test
```

150 runs. 30 of them drive a real browser through Capybara and Selenium, and
need a Chrome matching the installed ChromeDriver. The specimen is measured in
Chromium, WebKit and Firefox before it is published.

## license

MIT.
