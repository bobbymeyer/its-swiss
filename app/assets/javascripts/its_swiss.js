// Registers the library's two controllers with the host's Stimulus
// application. controllers/application is what stimulus-rails installs in
// every host, and it is the one thing this file assumes about the JavaScript
// around it. The shell imports this module, so a host has nothing to write;
// a host that registers the two by hand still can, and registers them twice
// harmlessly.
import { application } from "controllers/application"
import ClipboardController from "its_swiss/clipboard_controller"
import LiveSearchController from "its_swiss/live_search_controller"

application.register("its-swiss-clipboard", ClipboardController)
application.register("its-swiss-live-search", LiveSearchController)
