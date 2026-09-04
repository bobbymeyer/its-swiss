// Every place a page is off the grid, asked of whatever page is open.
//
// One function, so the engine's specimen, the published file and the same
// file in a browser that is not Chromium are all asked exactly this. It is
// read by the Ruby system tests and by the cross-engine job in CI, which is
// why it is a file rather than a heredoc in either.
//
// Two lists come back. `boxes` holds every block box whose over or under
// edge is not on a line: the column is a stack of these, and one that is a
// pixel tall too many puts everything below it off the grid. `type` holds
// every run of text whose baseline is not on a line, or whose height is not
// its leading — the second is how a face that did not take shows up, since
// a face with the leading for its ascent and no descent is exactly one
// leading tall, and a font with its own metrics is not.
//
// Nothing is probed. A span inserted to find a baseline re-lays out the page
// it was inserted into; a text run's client rect is the browser's own answer
// for where that run already is, and with no descent its under edge is its
// baseline.
(unit) => {
  // A browser lays out in 64ths of a pixel. The tolerance is a layout unit
  // or two, not a fudge: a real error is a whole pixel, because that is the
  // smallest thing a rule or a border can be.
  const off = (value, u) => {
    const over = ((value % u) + u) % u
    return Math.min(over, u - over) > 0.05
  }

  // A block of small type may sit on a half-line — that is what .subgrid
  // declares. The block itself still owes the column whole lines; only what
  // is inside it may halve them.
  const unitFor = (el) => (el.closest(".subgrid > *") ? unit / 2 : unit)

  const name = (el) => {
    const classes = typeof el.className === "string" && el.className.trim()
    return el.tagName.toLowerCase() + (classes ? "." + classes.split(/\s+/).join(".") : "")
  }

  const boxes = []
  for (const el of document.querySelectorAll("body *")) {
    const style = getComputedStyle(el)
    // An inline box is the line's business, an out-of-flow box sits on no
    // column at all, and a checkbox is drawn by the browser at a size of
    // its own on a row that is measured here regardless.
    if (style.display.startsWith("inline") && !style.display.startsWith("inline-")) continue
    if (style.position === "absolute" || style.position === "fixed") continue
    if (el.matches("input[type=checkbox], input[type=radio]")) continue

    const box = el.getBoundingClientRect()
    if (box.height === 0) continue

    const u = unitFor(el)
    const top = box.top + window.scrollY
    const bottom = box.bottom + window.scrollY
    if (off(top, u) || off(bottom, u)) boxes.push(`${name(el)} from ${top} to ${bottom}`)
  }

  const type = []
  // A superscript and a subscript are moved off the baseline on purpose;
  // everything else that is not on the page is not on the grid either.
  const unmeasured = "script, style, sup, sub, [hidden], .visually-hidden, .skip-link"
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
  let node
  while ((node = walker.nextNode())) {
    const text = node.textContent.trim()
    if (!text) continue
    const parent = node.parentElement
    if (parent.closest(unmeasured)) continue
    const style = getComputedStyle(parent)
    if (style.display === "none") continue

    const range = document.createRange()
    range.selectNodeContents(node)
    const u = unitFor(parent)
    // Zero leading is an inline that has given the line back to the strut —
    // code, a small — and its height is its own font's, not the line's.
    const leading = parseFloat(style.lineHeight)
    const label = `${name(parent)} "${text.slice(0, 32)}"`

    for (const rect of range.getClientRects()) {
      if (rect.width === 0 || rect.height === 0) continue
      const baseline = rect.bottom + window.scrollY
      if (off(baseline, u)) type.push(`${label} has a baseline at ${baseline}`)
      else if (leading > 0 && Math.abs(rect.height - leading) > 0.05) {
        type.push(`${label} is ${rect.height} tall on a leading of ${leading}, so the face did not take`)
      }
    }
  }

  return { boxes, type }
}
