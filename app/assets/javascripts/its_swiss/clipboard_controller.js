import { Controller } from "@hotwired/stimulus"

// The library's whole JavaScript surface. A typographic system does not need
// script to set type; this is here because a value that exists to be taken
// somewhere else should be a button that copies itself, and that cannot be
// done in CSS.
//
// The value is an attribute rather than the button's own text, so a button
// that shows a value shortened for the page still copies the whole of it.
export default class extends Controller {
  static values = { text: String, saidFor: { type: Number, default: 1200 } }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue || this.element.textContent.trim())
    } catch {
      // A refused or unavailable clipboard is not an error the page should
      // report: the value is still on screen, still selectable, and saying
      // "copied" when nothing was copied is the only outcome worth avoiding.
      return
    }

    // Says it worked in the one place you are already looking. The attribute
    // is the whole signal; what it looks like is components.css's business.
    this.element.setAttribute("data-copied", "")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.removeAttribute("data-copied"), this.saidForValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
