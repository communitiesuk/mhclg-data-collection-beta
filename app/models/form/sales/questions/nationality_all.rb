class Form::Sales::Questions::NationalityAll < ::Form::Question
  def initialize(id, hsh, page, buyer_index)
    super(id, hsh, page)
    @check_answer_label = "Buyer #{buyer_index}’s nationality"
    @header = "Enter a nationality"
    @type = "select"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = buyer_index
    @question_number = buyer_index == 1 ? 24 : 32
  end

  ANSWER_OPTIONS = {
    "" => "Select an option",
    "4" => "Afghanistan",
    "8" => "Albania",
    "12" => "Algeria",
    "20" => "Andorra",
    "24" => "Angola",
    "28" => "Antigua and Barbuda",
    "32" => "Argentina",
    "51" => "Armenia",
    "36" => "Australia",
    "40" => "Austria",
    "31" => "Azerbaijan",
    "44" => "Bahamas",
    "48" => "Bahrain",
    "50" => "Bangladesh",
    "52" => "Barbados",
    "112" => "Belarus",
    "56" => "Belgium",
    "84" => "Belize",
    "204" => "Benin",
    "64" => "Bhutan",
    "68" => "Bolivia",
    "70" => "Bosnia and Herzegovina",
    "72" => "Botswana",
    "76" => "Brazil",
    "96" => "Brunei",
    "100" => "Bulgaria",
    "854" => "Burkina Faso",
    "108" => "Burundi",
    "132" => "Cabo Verde",
    "116" => "Cambodia",
    "120" => "Cameroon",
    "124" => "Canada",
    "140" => "Central African Republic",
    "148" => "Chad",
    "152" => "Chile",
    "156" => "China",
    "170" => "Colombia",
    "174" => "Comoros",
    "178" => "Congo",
    "188" => "Costa Rica",
    "384" => "Côte d'Ivoire",
    "191" => "Croatia",
    "192" => "Cuba",
    "196" => "Cyprus",
    "203" => "Czechia",
    "180" => "Democratic Republic of the Congo",
    "208" => "Denmark",
    "262" => "Djibouti",
    "212" => "Dominica",
    "214" => "Dominican Republic",
    "218" => "Ecuador",
    "818" => "Egypt",
    "222" => "El Salvador",
    "226" => "Equatorial Guinea",
    "232" => "Eritrea",
    "233" => "Estonia",
    "748" => "Eswatini",
    "231" => "Ethiopia",
    "238" => "Falkland Islands",
    "242" => "Fiji",
    "246" => "Finland",
    "250" => "France",
    "266" => "Gabon",
    "270" => "Gambia",
    "268" => "Georgia",
    "276" => "Germany",
    "288" => "Ghana",
    "292" => "Gibraltar",
    "300" => "Greece",
    "308" => "Grenada",
    "320" => "Guatemala",
    "831" => "Guernsey",
    "324" => "Guinea",
    "624" => "Guinea-Bissau",
    "328" => "Guyana",
    "332" => "Haiti",
    "340" => "Honduras",
    "344" => "Hong Kong",
    "348" => "Hungary",
    "352" => "Iceland",
    "356" => "India",
    "360" => "Indonesia",
    "364" => "Iran",
    "368" => "Iraq",
    "372" => "Ireland",
    "833" => "Isle of Man",
    "376" => "Israel",
    "380" => "Italy",
    "388" => "Jamaica",
    "392" => "Japan",
    "832" => "Jersey",
    "400" => "Jordan",
    "398" => "Kazakhstan",
    "404" => "Kenya",
    "296" => "Kiribati",
    "414" => "Kuwait",
    "417" => "Kyrgyzstan",
    "418" => "Laos",
    "428" => "Latvia",
    "422" => "Lebanon",
    "426" => "Lesotho",
    "430" => "Liberia",
    "434" => "Libya",
    "438" => "Liechtenstein",
    "440" => "Lithuania",
    "442" => "Luxembourg",
    "450" => "Madagascar",
    "454" => "Malawi",
    "458" => "Malaysia",
    "462" => "Maldives",
    "466" => "Mali",
    "470" => "Malta",
    "584" => "Marshall Islands",
    "478" => "Mauritania",
    "480" => "Mauritius",
    "484" => "Mexico",
    "583" => "Micronesia (Federated States of)",
    "498" => "Moldova",
    "492" => "Monaco",
    "496" => "Mongolia",
    "499" => "Montenegro",
    "504" => "Morocco",
    "508" => "Mozambique",
    "104" => "Myanmar",
    "516" => "Namibia",
    "520" => "Nauru",
    "524" => "Nepal",
    "528" => "Netherlands",
    "554" => "New Zealand",
    "558" => "Nicaragua",
    "562" => "Niger",
    "566" => "Nigeria",
    "807" => "North Macedonia",
    "408" => "North Korea",
    "578" => "Norway",
    "512" => "Oman",
    "586" => "Pakistan",
    "585" => "Palau",
    "275" => "Palestine, State of",
    "591" => "Panama",
    "598" => "Papua New Guinea",
    "600" => "Paraguay",
    "604" => "Peru",
    "608" => "Philippines",
    "616" => "Poland",
    "620" => "Portugal",
    "634" => "Qatar",
    "642" => "Romania",
    "643" => "Russia",
    "646" => "Rwanda",
    "659" => "Saint Kitts and Nevis",
    "662" => "Saint Lucia",
    "670" => "Saint Vincent and the Grenadines",
    "882" => "Samoa",
    "674" => "San Marino",
    "678" => "Sao Tome and Principe",
    "682" => "Saudi Arabia",
    "686" => "Senegal",
    "688" => "Serbia",
    "690" => "Seychelles",
    "694" => "Sierra Leone",
    "702" => "Singapore",
    "703" => "Slovakia",
    "705" => "Slovenia",
    "90" => "Solomon Islands",
    "706" => "Somalia",
    "710" => "South Africa",
    "410" => "South Korea",
    "728" => "South Sudan",
    "724" => "Spain",
    "144" => "Sri Lanka",
    "729" => "Sudan",
    "740" => "Suriname",
    "752" => "Sweden",
    "756" => "Switzerland",
    "760" => "Syria",
    "158" => "Taiwan",
    "762" => "Tajikistan",
    "834" => "Tanzania",
    "764" => "Thailand",
    "626" => "Timor-Leste",
    "768" => "Togo",
    "776" => "Tonga",
    "780" => "Trinidad and Tobago",
    "788" => "Tunisia",
    "792" => "Turkey",
    "795" => "Turkmenistan",
    "798" => "Tuvalu",
    "800" => "Uganda",
    "804" => "Ukraine",
    "784" => "United Arab Emirates",
    "826" => "United Kingdom",
    "840" => "United States of America",
    "858" => "Uruguay",
    "860" => "Uzbekistan",
    "548" => "Vanuatu",
    "336" => "Vatican City",
    "862" => "Venezuela",
    "704" => "Vietnam",
    "887" => "Yemen",
    "894" => "Zambia",
    "716" => "Zimbabwe",
  }.freeze
end
