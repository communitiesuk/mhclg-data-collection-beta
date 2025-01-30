import {Controller} from '@hotwired/stimulus'
import accessibleAutocomplete from 'accessible-autocomplete'
import 'accessible-autocomplete/dist/accessible-autocomplete.min.css'
import {searchableName} from "../modules/search";

const options = []

const fetchOptions = async (query) => {
  const response = await fetch(`/address_options?query=${query}`)
  const data = await response.json()
  console.log(data)
  return data
}

const fetchAndPopulateSearchResults = async (query, populateResults, populateOptions, selectEl) => {
  if (/\S/.test(query)) {
    const results = await fetchOptions(query)
    console.log(results) // address and uprn keys returned per result
    populateOptions(results, selectEl)
    populateResults(Object.values(results).map((o) => o.address))
  }
}

const populateOptions = (results, selectEl) => {
  selectEl.innerHTML = ''

  results.forEach((result) => {
    const option = document.createElement('option')
    option.value = result.uprn
    option.innerHTML = result.address
    option.setAttribute('address', result.address)
    selectEl.appendChild(option)
    options.push(option)
  })
}

export default class extends Controller {
  connect () {
    const selectEl = this.element

    accessibleAutocomplete.enhanceSelectElement({
      defaultValue: '',
      selectElement: selectEl,
      minLength: 1,
      source: (query, populateResults) => {
        fetchAndPopulateSearchResults(query, populateResults, populateOptions, selectEl)
      },
      autoselect: true,
      showNoOptionsFound: true,
      placeholder: 'Start typing to search',
      templates: { suggestion: (value) => value },
      onConfirm: (val) => {
        const selectedResult = Array.from(selectEl.options).find(option => option.address === val)

        if (selectedResult) {
          selectedResult.selected = true
        }
      }
    })
  }


}
