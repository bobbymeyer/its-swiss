# Design

Why the library is what it is. The stylesheets say what each rule is for in
a sentence; the arguments are here, so that they are stated once. The README
says how to use it, and CHANGELOG.md when each of these arrived.

## The boundary is the cascade

Everything the gem ships is inside a cascade layer, `its-swiss`, with one
sublayer per file in a fixed order. An application's own CSS is unlayered,
and an unlayered rule beats every layered one whatever its specificity. So
the application always wins, without having to out-specify anything or reach
for `!important`. The library has one `!important`, in the reset, for
`[hidden]`: the rule it has to beat is inside its own layer.

A pattern enters the gem after it appears in two applications, not before.
The grid itself, which blocks span which fields, never does: it is what an
application looks like.

## The baseline

`--line` is the interval everything vertical registers to, and the leading of
the body text. In this style those are one number, because that is what a
baseline grid is: Müller-Brockmann's horizontal lines are one line of text
apart, and a field is a whole number of them. Every leading is `--line` or a
whole multiple, and so is every margin, padding and gap on the vertical axis.
`--space-*` is the horizontal step: an inline gap has no baseline to miss.

0.1.0 called eight pixels the baseline. Eight pixels is a third of the body
line, so a block could be a whole number of them and still put every line of
type after it somewhere new. A third of a line is a spacing unit.

### The faces

Boxes in step are only the easy half. Where a line's baseline falls inside
its line box is the font's decision: half the leading down, then the font's
ascent, a number in the font file the library has never been told. So the
library sets every register in a face of its own: the machine's grotesque
declared again over `src: local()`, once per ratio of leading to size the
ladder produces, with `ascent-override` set to that ratio and the descent and
line gap set to nothing. A line box is then exactly the ascent tall, and the
baseline is the under edge of the line box, in every line, whatever the font
underneath, in a browser that honours the descriptors. Chromium and Firefox
do. A register is three declarations, and the third is what makes the first
two a grid:

```css
.micro { font-family: var(--face-200), var(--font-family); font-size: var(--size-1); line-height: var(--line); }
```

### The trim

Safari loads the faces and ignores what they say about their metrics. There
every text block is trimmed to its type instead: `text-box: trim-both cap
alphabetic` makes the block's over edge the cap of its first line and its
under edge the baseline of its last, and one padding rounds the cap up to
the block's own leading, measured by the browser in cap and line units. The
cap is rounded to a pixel because that is the cap WebKit trims to.

Only where it is needed, and only when told. A trimmed box is a 64th of a
pixel short as often as not on the engine the correction is written for,
and half a pixel out per block on one that trims to the exact cap. So one
line of script ahead of the stylesheets marks the document
`no-metric-overrides` where the faces are not honoured, and the trim steps in
there and nowhere else. The faces are the mechanism; the trim is the
fallback.

Three things follow. Anything that changes size inside a line is given no
leading, so it never asks the line for room. No row asks the browser to find
a baseline: every box's baselines are whole lines below its own over edge,
so a row that starts its items on one line has put their baselines on one
line. And text lives in text elements: a block that holds blocks is trimmed
through its first and last child and would be corrected twice.

### The two runs of type off the baseline

A control's text is set in `--font-family` itself, with the font's own
metrics, on the line the rule closes: a browser sets that text in a box of
its own, centres it there and clips it there, and on a face with no descent
every descender was cut off at the rule. A button's label is centred in its
box by cap: a label set on the second line of a two-line box reads as a
field with a rule under it.

## Rules are drawn inside the box

A rule is drawn inside the box it belongs to, never on top of it. Wherever
one sits on a padded edge, its width comes out of that padding, and wherever
it is the element, out of the margin above it. A pixel added instead of
taken is a box a pixel taller than the ladder says, which puts everything
below it off the baseline; and since every rule on the page does it, the
error accumulates down the column rather than showing up once. The `hr` is a
box one line tall with the rule on its top edge, so its margins survive
collapsing.

## The value scale

Six steps of OKLCH lightness, paper to ink. OKLCH because the steps have to
be perceptually even to be read as a scale at all; the same arithmetic in
sRGB puts four of the six inside the top quarter of the range. The ladder is
deliberately not evenly spaced: a hairline has to be barely there, so the
top is dense; the middle only has to hold secondary text away from primary,
so it is sparse. Neutral as shipped, and warmed as a whole through two slots.

## The accent

State and emphasis only, and unset it is ink. If a page reads correctly with
the accent collapsed onto the value scale, the values were doing the work.
One red per page: the accent is for where you are on the site, the nav, the
subnav, the page numbers, and for the one thing that cannot be undone. Where
you are on a page, in a menu, in a filter, is the weight, in ink. The one
filled button is in ink: the primary action is the one you were going to
take, and the accent is for the one you have to be told about.

## The grid

A field is the page's actual width, less the gutters, divided: `--field` is
measured in container units from the `.page` the fields are laid out in, so
a field on a phone is a phone's field. Every width helper is built from it,
which is what keeps a block stopping on a field line instead of three pixels
short of one.

The measure is a count of characters, and the grid is what it stops on.
Sixty-five characters in the type's own font, taken up to the nearest whole
run of fields with `round()`, and never past the page. A measure that was
three fields whatever the count was a proportion: a quarter of a
twelve-column page, and wider than a phone.

The module is a field's height, in lines. The columns divide the page across
and the module divides it down; a picture or a block sized to whole modules
is what makes a column grid a modular one. A figure rounds to whole lines by
default, which keeps the column in step, and to whole modules with
`.figure--modular`, which gives it the grid's proportion.

`--span` is a registered property that does not inherit. A custom property
inherits by default, and a grid inside a spanned item would otherwise start
every child of its own at the parent's span.

## Pictures

The one case that nearly does not transfer from print. A picture's height is
its fluid width over its ratio, so without help one picture puts the whole
column below it off the grid at every width but a few. `round()` takes the
box up to the next whole line, recomputed as the container resizes. The
picture is fitted inside it, because a library must not crop an image it did
not choose; `.figure--cover` crops, which is the Müller-Brockmann move and
the application's to make where it owns the picture. `--ratio` is the
application's to declare: CSS cannot read an intrinsic one.

## Forms

A field is a label, a control and, when there is something to say, a hint or
the reason it was refused. The control is a rule under the text rather than
a box around it. A control is two lines: a line of air under the label, then
the line the type stands on, which the rule closes, so the type stands on
its rule the way a line of handwriting stands on a ruled page. The dense form
puts the label on the line of air, for a form of many fields or a panel.

The rule at rest is the strong rule, ink under the hand, and the accent,
heavy, when the control has the focus or has been refused. The focus is the
rule and not a box: a box drawn round a field whose only visible part is a
rule crosses the label above it.

A form is a column with no width of its own; the measure is the page's to
give it. `its_swiss_form_with` gives it.

## Buttons

A button is a box and a link is underlined text; both at once leaves the
page saying "follow me" and "press me" in the same breath. Every button is
the same box, two lines tall, with a keyline drawn as an inset shadow so the
box is the label's line and two paddings and nothing else. One is filled,
in ink. Destroying is set apart by a step on the ladder before it is
coloured on hover, because a reader scanning the row has not hovered
anything yet, and by focus as well as hover, because a keyboard reaches it
and touch never hovers.

## What is measured

Most of the suite reads the CSS, for the decisions that are decisions about
the source: that the scale descends, that no stylesheet invents a colour,
that every leading is whole lines, that nothing is centred or in capitals.
The rest asks a browser what it laid out: that an unlayered declaration
beats the library's, that quiet ink clears 4.5:1, that every box on the
specimen starts and ends on a line and every baseline is on one, on the
faces and trimmed, and that the measure lands on a field line the browser
really laid out. `test/support/on_the_grid.js` is the one question, asked of
Chromium by the Ruby suite and of WebKit and Firefox by
`test/browsers/grid.mjs`. There are no pixel tests.
