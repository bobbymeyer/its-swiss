// Every place a page is off the grid, asked of whatever page is open.
//
// One function, so the engine's specimen, the published file and the same
// file in a browser that is not Chromium are all asked exactly this. It is
// read by the Ruby system tests and by the cross-engine job in CI, which is
// why it is a file rather than a heredoc in either.
//
// Two lists come back. `boxes` holds every block box off the grid: a box
// that holds lines or nothing ends on a line whatever its height — a
// paragraph, a cell, a half-line swatch standing on a baseline — and a box
// that holds blocks starts on a line and puts whole lines under the last of
// them. The column is a stack of these, and one that ends a pixel late puts
// everything below it a pixel late. `type` holds every run of text whose
// baseline is not on a line.
//
// Where the baseline is depends on which of the library's two mechanisms
// the engine is using, and both are read off what the engine laid out
// rather than probed for — a span put into a trimmed block to find its
// baseline re-lays the block out and moves the thing it was measuring. A
// trimmed block ends on the baseline of its last line, so its under edge
// less its padding is that baseline. An untrimmed run of text is set in a
// face with no descent, so the under edge of the rectangle the engine
// reports for it is its baseline; in an engine that ignores the face and
// does not trim, that rectangle ends a descent below the baseline, which
// is off the grid, which is the truth.
(unit) => {
  // A browser lays out in 64ths of a pixel, and on the faces every box is
  // exact: the tolerance is a layout unit or two. A trimmed box is its cap
  // as the engine trims it and a padding that is a leading less its cap as
  // the engine measures it, and the two are not the same number — WebKit
  // trims to the cap rounded to a pixel, and the correction is written for
  // that, so Chromium trimming to the exact cap lands within half a pixel.
  // Neither tolerance is a fudge: a real error is a whole pixel, because
  // that is the smallest thing a rule or a border can be.
  const exact = !document.documentElement.classList.contains("no-metric-overrides")
  const tolerance = exact ? 0.05 : 0.5
  const off = (value, u) => {
    const over = ((value % u) + u) % u
    return Math.min(over, u - over) > tolerance
  }

  // Where a page is measured from. On the faces every box is exact, and it
  // is measured from the top of the page: a box a pixel out puts everything
  // below it a pixel out, and that is what is asked. A trimmed box is its
  // cap and a padding that is a leading less its cap, each snapped to a
  // 64th on its own, so it comes out a 64th short as often as not — under
  // a pixel down the whole of a long page, and invisible, but down the
  // whole of a long page, and a container of such boxes is the sum of
  // their 64ths. So a page that trims is measured box by box: each against
  // the under edge of the sibling above it or the over edge of its parent,
  // a box that holds blocks by what it puts under the last of them, a box
  // that holds lines by its height, and each baseline against its own
  // block. Every rule's pixel and every leading led off the ladder is still
  // a whole pixel in that measure; only the 64ths are let go.
  const inFlow = (el) => {
    const style = getComputedStyle(el)
    return style.display !== "none" && style.position !== "absolute" && style.position !== "fixed"
  }
  const blockLevel = (el) => !getComputedStyle(el).display.startsWith("inline")
  const origin = (el) => {
    let previous = el.previousElementSibling
    while (previous && !inFlow(previous)) previous = previous.previousElementSibling
    const reference = previous ? previous.getBoundingClientRect().bottom : el.parentElement.getBoundingClientRect().top
    return y(reference)
  }

  // A block of small type may sit on a half-line — that is what .subgrid
  // declares. The block itself still owes the column whole lines; only what
  // is inside it may halve them.
  const unitFor = (el) => (el.closest(".subgrid > *") ? unit / 2 : unit)

  // A page shown at a scale — an embed fitted to a panel, a zoomed window —
  // reports every rectangle at that scale while its layout is in CSS pixels,
  // and a grid of 24 measured against boxes of 24.002 is off everywhere by
  // the page's height. The scale is read off a probe of a known size at the
  // document's origin: a thousand pixels tall, so the scale is exact to the
  // float, and at the top, so a shift of the whole page is read with it.
  // Every position below is read through both.
  const probe = document.createElement("div")
  probe.style.cssText = "position: absolute; top: 0; left: 0; width: 1000px; height: 1000px; visibility: hidden; pointer-events: none"
  document.body.append(probe)
  const known = probe.getBoundingClientRect()
  const scale = known.height / 1000 || 1
  const shift = known.top + window.scrollY
  probe.remove()
  const y = (visual) => (visual + window.scrollY - shift) / scale

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
    const top = y(box.top)
    const bottom = y(box.bottom)
    const where = `${name(el)} from ${top} to ${bottom}`
    // A control is a leaf whatever its options say they are.
    const blocks = el.matches("select") ? [] : Array.from(el.children).filter((child) => inFlow(child) && blockLevel(child))
    const last = blocks.at(-1)

    if (exact) {
      if (off(bottom, u) || (last && off(top, u))) boxes.push(where)
      continue
    }

    // Measured from the box before. An inline-block sits on its line rather
    // than under a sibling, so only its height is the ladder's business; a
    // box that holds blocks starts where the box before it ended and puts
    // whole lines under its last block, measured in that block's unit, since
    // the space under a subgrid's last row may be a half-line.
    if (!blockLevel(el)) {
      if (off(bottom - top, u)) boxes.push(where)
    } else if (last) {
      const under = bottom - y(last.getBoundingClientRect().bottom)
      if (off(top - origin(el), u) || off(under, unitFor(last))) boxes.push(where)
    } else if (off(bottom - origin(el), u)) {
      boxes.push(where)
    }
  }

  const type = []
  // A superscript and a subscript are moved off the baseline on purpose, and
  // so is a button's label, centred in a box that is itself on the grid; a
  // control's text is not in the document at all; everything else that is
  // not on the page is not on the grid either.
  const unmeasured = "script, style, title, select, textarea, sup, sub, .button, [hidden], .visually-hidden, .skip-link"
  const trimmed = (el) => getComputedStyle(el).textBoxTrim === "trim-both"
  const blockOf = (el) => {
    while (el && el !== document.body) {
      const display = getComputedStyle(el).display
      if (!display.startsWith("inline") || display.startsWith("inline-")) return el
      el = el.parentElement
    }
    return document.body
  }
  const measured = new Set()

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
  let node
  while ((node = walker.nextNode())) {
    const text = node.textContent.trim()
    if (!text) continue
    const parent = node.parentElement
    if (parent.closest(unmeasured) || getComputedStyle(parent).display === "none") continue

    const u = unitFor(parent)
    const label = `${name(parent)} "${text.slice(0, 32)}"`
    const block = blockOf(parent)

    if (trimmed(block)) {
      if (measured.has(block)) continue
      measured.add(block)
      const style = getComputedStyle(block)
      const box = block.getBoundingClientRect()
      const baseline = y(box.bottom) - parseFloat(style.paddingBottom) - parseFloat(style.borderBottomWidth)
      const from = exact ? 0 : y(box.top)
      if (off(baseline - from, u)) type.push(`${label} ends on a baseline at ${baseline}`)
      continue
    }

    const from = exact ? 0 : y(block.getBoundingClientRect().top)
    const range = document.createRange()
    range.selectNodeContents(node)
    for (const rect of range.getClientRects()) {
      if (rect.width === 0 || rect.height === 0) continue
      const baseline = y(rect.bottom)
      if (off(baseline - from, u)) type.push(`${label} has a baseline at ${baseline}`)
    }
  }

  return { boxes, type, scale, shift }
}
