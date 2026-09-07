# The library's whole JavaScript surface: two controllers. A typographic
# system does not need script to set type; these are here because a value
# that exists to be taken somewhere else should be a button that copies
# itself, and a search should narrow the list as you type, and neither can
# be done in CSS.
pin "its_swiss/clipboard_controller", to: "its_swiss/clipboard_controller.js"
pin "its_swiss/live_search_controller", to: "its_swiss/live_search_controller.js"
