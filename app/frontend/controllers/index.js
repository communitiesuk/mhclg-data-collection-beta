// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { application } from './application'

import AccessibleAutocompleteController from './accessible_autocomplete_controller.js'

import ConditionalFilterController from './conditional_filter_controller.js'

import ConditionalQuestionController from './conditional_question_controller.js'

import GovukfrontendController from './govukfrontend_controller.js'

import NumericQuestionController from './numeric_question_controller.js'

import SearchController from './search_controller.js'

import FilterLayoutController from './filter_layout_controller.js'

import TabsController from './tabs_controller.js'

import AddressSearchController from './address_search_controller.js'

application.register('accessible-autocomplete', AccessibleAutocompleteController)
application.register('conditional-filter', ConditionalFilterController)
application.register('conditional-question', ConditionalQuestionController)
application.register('govukfrontend', GovukfrontendController)
application.register('numeric-question', NumericQuestionController)
application.register('filter-layout', FilterLayoutController)
application.register('search', SearchController)
application.register('tabs', TabsController)
application.register('address-search', AddressSearchController)
