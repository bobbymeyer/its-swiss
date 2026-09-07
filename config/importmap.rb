# The library's whole JavaScript surface: two controllers and the module
# that registers them, which the shell imports.
pin "its_swiss", to: "its_swiss.js"
pin "its_swiss/clipboard_controller", to: "its_swiss/clipboard_controller.js"
pin "its_swiss/live_search_controller", to: "its_swiss/live_search_controller.js"
