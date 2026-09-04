require "nokogiri"

module ItsSwiss
  # The specimen as one static file.
  #
  # The engine renders it from ERB, which only a Rails application can do — so
  # a static site that wants to show it has, until now, had to keep a copy
  # made by hand. Two of those drifted: one declared a --baseline the library
  # had renamed and a --measure it never had.
  #
  # This renders the real page and inlines the real stylesheets, so the
  # published specimen is the library rather than a likeness of it.
  class StaticSpecimen
    # The page's own chrome is unlayered, which is exactly how a consuming
    # application sits on top of the library: it wins without out-specifying
    # anything.
    CHROME = <<~CSS
      :root {
        --accent: #E30613;
        --value-chroma: 0.006;
        --value-hue: 95;
        --columns: 6;
        --page-max: 46rem;
      }

      /* What the first button toggles. The library ships with the accent
         unset and falling back to ink, which is the argument the page makes. */
      html.no-accent { --accent: var(--ink); }

      body { padding-block: var(--line-2) var(--line-4); }

      main { position: relative; }

      /* The baseline, drawn over the type it is registered to: one laid-out
         element per line rather than a repeating gradient. A gradient is
         rasterised a tile at a time, and a tile whose height is not a whole
         number of device pixels — a page shown at any scale but one to one —
         gains a fraction with every repeat, until the lines have crept off
         the boxes they are meant to show. An element at calc(n * --line) goes
         through the same arithmetic as the boxes, and lands where they do at
         any scale. */
      .specimen__baselines {
        position: absolute;
        inset: 0;
        z-index: 1;
        pointer-events: none;
        display: none;
      }

      html.show-baseline .specimen__baselines { display: block; }

      .specimen__baselines > i {
        position: absolute;
        inset-inline: 0;
        border-top: var(--rule-hair) solid color-mix(in oklch, var(--accent) 34%, transparent);
      }

      .specimen-controls { margin-block: var(--line) var(--line-2); }

      /* What the measure button says. Wrapped, or a user agent string scrolls
         the page sideways; a whole number of lines, like anything else. */
      #grid-report { margin-block: 0 var(--line-2); white-space: pre-wrap; overflow-wrap: anywhere; }
    CSS

    SCRIPT = <<~JS
      const root = document.documentElement

      const toggle = (id, cls, on, off) => {
        const button = document.getElementById(id)
        button.addEventListener("click", () => {
          button.textContent = root.classList.toggle(cls) ? off : on
        })
      }

      toggle("accent-toggle", "no-accent", "Unset the accent", "Set the accent")
      toggle("baseline-toggle", "show-baseline", "Show the baseline", "Hide the baseline")

      // The lines the baseline toggle shows, one per line of the page, laid
      // out rather than painted. Drawn again whenever the page changes
      // height, since a reflow at a new width is a different number of them.
      const main = document.getElementById("main")
      const baselines = document.createElement("div")
      baselines.className = "specimen__baselines"
      baselines.setAttribute("aria-hidden", "true")
      main.append(baselines)
      const drawBaselines = () => {
        const line = parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5
        const count = Math.ceil(main.offsetHeight / line) + 1
        if (baselines.childElementCount === count) return
        baselines.replaceChildren(...Array.from({ length: count }, (_, n) => {
          const i = document.createElement("i")
          i.style.top = `calc(${n} * var(--line))`
          return i
        }))
      }
      new ResizeObserver(drawBaselines).observe(main)
      drawBaselines()

      // The same question the test suite asks, asked of this browser: which
      // mechanism it is on, which faces it loaded, and every box and run of
      // type it laid out off the grid. A page that only looks right in the
      // browsers somebody checked is a page with a button for the others.
      document.getElementById("measure").addEventListener("click", () => {
        const unit = parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5
        const { boxes, type, scale, shift } = (__GRID__)(unit)
        const faces = Array.from(document.fonts).filter((face) => face.family.startsWith("its-swiss"))
          .map((face) => `${face.family} ${face.weight} ${face.status}`)
        const report = [
          navigator.userAgent,
          `its-swiss ${document.documentElement.dataset.version}, ${document.documentElement.classList.contains("no-metric-overrides") ? "trimmed" : "on the faces"}` +
            `, ${CSS.supports("text-box", "trim-both cap alphabetic") ? "can trim" : "cannot trim"}`,
          `faces: ${faces.join("; ") || "none listed"}`,
          `${boxes.length} boxes and ${type.length} runs of type off the ${unit}px grid` +
            (scale !== 1 || shift !== 0 ? `, read through a scale of ${scale.toFixed(6)} and a shift of ${shift.toFixed(4)}px` : ""),
          ...boxes.slice(0, 20), ...type.slice(0, 20)
        ].join("\\n")
        let out = document.getElementById("grid-report")
        if (!out) {
          out = document.createElement("pre")
          out.id = "grid-report"
          document.querySelector(".specimen-controls").after(out)
        }
        out.textContent = report
      })

      // The library's one piece of JavaScript, which the gem ships as a
      // Stimulus controller. Written plainly here because this page has no
      // Stimulus, and a copy button that does not copy is not the component.
      for (const button of document.querySelectorAll(".copy")) {
        button.addEventListener("click", async () => {
          try {
            await navigator.clipboard.writeText(
              button.dataset.itsSwissClipboardTextValue || button.textContent.trim())
          } catch { return }
          button.setAttribute("data-copied", "")
          setTimeout(() => button.removeAttribute("data-copied"), 1200)
        })
      }

      // Embedded in an iframe, tell the parent how tall this actually is, so
      // nobody has to guess a height that is only right at one width.
      const post = () => parent.postMessage(
        { specimen: "its-swiss", version: document.documentElement.dataset.version,
          height: document.documentElement.scrollHeight }, "*")
      new ResizeObserver(post).observe(document.documentElement)
      addEventListener("load", post)
    JS

    def self.call(...) = new(...).call

    def initialize(root: Rails.root, version: ItsSwiss::VERSION)
      @root = Pathname.new(root)
      @version = version
    end

    def call
      <<~HTML
        <!doctype html>
        <html lang="en" data-version="#{@version}">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>its-swiss #{@version} — specimen</title>

        <!-- GENERATED by bin/specimen. Do not hand-edit.

             The stylesheets are its-swiss #{@version} verbatim, in layer order,
             and the markup is the engine's own specimen page — the library's
             documentation and its regression fixture. Regenerate; never patch. -->

        <script>#{ItsSwiss::METRIC_OVERRIDES_SCRIPT}</script>

        <style>
        #{stylesheets}
        </style>

        <style>
        #{CHROME}
        </style>
        </head>

        <body>
        <main id="main" class="page">
          <h1 class="page-title">its-swiss</h1>
          <p class="lede">
            Every component the library ships, the type scale, the value scale
            and the grid primitives — version #{@version}, rendered by the
            library itself. The accent is one custom property: unset it and the
            value scale is left to do the work, which is the whole argument.
          </p>

          <div class="run specimen-controls">
            <button type="button" class="button" id="accent-toggle">Unset the accent</button>
            <button type="button" class="button" id="baseline-toggle">Show the baseline</button>
            <button type="button" class="button button--quiet" id="measure">Measure the grid</button>
          </div>

        #{sections}
        </main>

        <script>
        #{SCRIPT.sub("__GRID__", grid_script)}
        </script>
        </body>
        </html>
      HTML
    end

    private
      # The gem's own stylesheets, in the order their layers are declared, plus
      # the specimen's furniture.
      def stylesheets
        (ItsSwiss::STYLESHEETS + [ "specimen" ]).map do |name|
          gem_root.join("app/assets/stylesheets/its_swiss/#{name}.css").read.rstrip
        end.join("\n")
      end

      # The monochrome take, without the heading and rule that separate it from
      # the second one: this page has a button where the engine's has a second
      # rendering.
      def sections
        page = Nokogiri::HTML5(render)
        take = page.at("[data-specimen-take=monochrome]") or
          raise "the specimen rendered without its monochrome take"

        take.css("hr.rule--heavy").each(&:remove)
        take.children.select { |node| %w[ h2 p ].include?(node.name) }.each(&:remove)
        take.inner_html.strip
      end

      def render
        ItsSwiss.configure { |config| config.specimen = true }
        session = ActionDispatch::Integration::Session.new(Rails.application)
        session.get(ItsSwiss::Engine.routes.url_helpers.specimen_path)
        raise "the specimen answered #{session.response.status}" unless session.response.ok?

        session.response.body
      end

      # The grid guard, verbatim, so the page asks exactly what the suite asks.
      def grid_script = gem_root.join("test/support/on_the_grid.js").read.gsub(%r{^//.*\n}, "").strip

      def gem_root = Pathname.new(File.expand_path("..", __dir__))
  end
end
