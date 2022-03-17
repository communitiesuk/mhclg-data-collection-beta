// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
require.context("govuk-frontend/govuk/assets")

// Polyfills for IE
import "core-js/features/promise"
import "unfetch/polyfill"
import "@stimulus/polyfills"
//

import "./styles/application.scss"
import "./controllers"
import "@hotwired/turbo-rails"
import { initAll } from "govuk-frontend"

initAll()
