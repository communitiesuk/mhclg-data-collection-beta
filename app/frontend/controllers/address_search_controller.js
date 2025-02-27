import { Controller } from '@hotwired/stimulus'
import accessibleAutocomplete from 'accessible-autocomplete'
import 'accessible-autocomplete/dist/accessible-autocomplete.min.css'

const options = []

const fetchOptions = async (query, searchUrl) => {
  if (query.length < 2) {
    throw new Error('Query must be at least 2 characters long.')
  }
  try {
    const response = await fetch(`${searchUrl}?query=${encodeURIComponent(query.trim())}`)
    return await response.json()
  } catch (error) {
    return error
  }
}

const fetchAndPopulateSearchResults = async (query, populateResults, searchUrl, populateOptions, selectEl) => {
  if (/\S/.test(query)) {
    try {
      const results = await fetchOptions(query, searchUrl)
      if (results.length === 0) {
        populateOptions([], selectEl)
        populateResults([])
      } else {
        populateOptions(results, selectEl)
        populateResults(Object.values(results).map((o) => `${o.text} (${o.value})`))
      }
    } catch (error) {
      populateOptions([], selectEl)
      populateResults([])
    }
  }
}

const populateOptions = (results, selectEl) => {
  selectEl.innerHTML = ''

  results.forEach((result) => {
    const option = document.createElement('option')
    option.value = result.value
    option.innerHTML = `${result.text} (${result.value})`
    selectEl.appendChild(option)
    options.push(option)
  })
}

export default class extends Controller {
  connect () {
    const searchUrl = JSON.parse(this.element.dataset.info).search_url
    const selectEl = this.element

    accessibleAutocomplete.enhanceSelectElement({
      defaultValue: '',
      selectElement: selectEl,
      minLength: 2,
      source: (query, populateResults) => {
        fetchAndPopulateSearchResults(query, populateResults, searchUrl, populateOptions, selectEl)
      },
      autoselect: true,
      showNoOptionsFound: true,
      placeholder: 'Start typing to search',
      templates: { suggestion: (value) => value },
      onConfirm: (val) => {
        const selectedResult = Array.from(selectEl.options).find(option => option.text === val)
        if (selectedResult) {
          selectedResult.selected = true
        }
      }
    })
  }
}
