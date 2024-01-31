class Form::Lettings::Questions::NationalityAll < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "nationality_all"
    @check_answer_label = "Lead tenant’s nationality"
    @header = "Enter a nationality"
    @type = "select"
    @check_answers_card_number = 1
    @answer_options = ANSWER_OPTIONS
    @question_number = 36
  end

  ANSWER_OPTIONS = {
    "" => "Select an option",
    "4" => { "name" => "Afghanistan", "synonyms" => "AF" },
    "8" => { "name" => "Albania", "synonyms" => "AL" },
    "12" => { "name" => "Algeria", "synonyms" => "DZ" },
    "20" => { "name" => "Andorra", "synonyms" => "AD" },
    "24" => { "name" => "Angola", "synonyms" => "AO" },
    "28" => { "name" => "Antigua and Barbuda", "synonyms" => "AG" },
    "32" => { "name" => "Argentina", "synonyms" => "AR" },
    "51" => { "name" => "Armenia", "synonyms" => "AM" },
    "36" => { "name" => "Australia", "synonyms" => "AU" },
    "40" => { "name" => "Austria", "synonyms" => "AT" },
    "31" => { "name" => "Azerbaijan", "synonyms" => "AZ" },
    "44" => { "name" => "Bahamas", "synonyms" => "" },
    "48" => { "name" => "Bahrain", "synonyms" => "BH" },
    "50" => { "name" => "Bangladesh", "synonyms" => "BD" },
    "52" => { "name" => "Barbados", "synonyms" => "BB" },
    "112" => { "name" => "Belarus", "synonyms" => "BY" },
    "56" => { "name" => "Belgium", "synonyms" => "BE" },
    "84" => { "name" => "Belize", "synonyms" => "BZ" },
    "204" => { "name" => "Benin", "synonyms" => "BJ" },
    "64" => { "name" => "Bhutan", "synonyms" => "BT" },
    "68" => { "name" => "Bolivia", "synonyms" => "BO" },
    "70" => { "name" => "Bosnia and Herzegovina", "synonyms" => "BA" },
    "72" => { "name" => "Botswana", "synonyms" => "BW" },
    "76" => { "name" => "Brazil", "synonyms" => "BR" },
    "96" => { "name" => "Brunei", "synonyms" => "BN" },
    "100" => { "name" => "Bulgaria", "synonyms" => "BG" },
    "854" => { "name" => "Burkina Faso", "synonyms" => "BF" },
    "108" => { "name" => "Burundi", "synonyms" => "BI" },
    "132" => { "name" => "Cabo Verde", "synonyms" => "" },
    "116" => { "name" => "Cambodia", "synonyms" => "KH" },
    "120" => { "name" => "Cameroon", "synonyms" => "CM" },
    "124" => { "name" => "Canada", "synonyms" => "CA" },
    "140" => { "name" => "Central African Republic", "synonyms" => "CF" },
    "148" => { "name" => "Chad", "synonyms" => "TD" },
    "152" => { "name" => "Chile", "synonyms" => "CL" },
    "156" => { "name" => "China", "synonyms" => "CN" },
    "170" => { "name" => "Colombia", "synonyms" => "CO" },
    "174" => { "name" => "Comoros", "synonyms" => "KM" },
    "178" => { "name" => "Congo", "synonyms" => "CG" },
    "188" => { "name" => "Costa Rica", "synonyms" => "CR" },
    "384" => { "name" => "Côte d'Ivoire", "synonyms" => "" },
    "191" => { "name" => "Croatia", "synonyms" => "HR" },
    "192" => { "name" => "Cuba", "synonyms" => "CU" },
    "196" => { "name" => "Cyprus", "synonyms" => "CY" },
    "203" => { "name" => "Czechia", "synonyms" => "CZ" },
    "180" => { "name" => "Democratic Republic of the Congo", "synonyms" => "" },
    "208" => { "name" => "Denmark", "synonyms" => "DK" },
    "262" => { "name" => "Djibouti", "synonyms" => "DJ" },
    "212" => { "name" => "Dominica", "synonyms" => "DM" },
    "214" => { "name" => "Dominican Republic", "synonyms" => "DO" },
    "218" => { "name" => "Ecuador", "synonyms" => "EC" },
    "818" => { "name" => "Egypt", "synonyms" => "EG" },
    "222" => { "name" => "El Salvador", "synonyms" => "SV" },
    "226" => { "name" => "Equatorial Guinea", "synonyms" => "GQ" },
    "232" => { "name" => "Eritrea", "synonyms" => "ER" },
    "233" => { "name" => "Estonia", "synonyms" => "EE" },
    "748" => { "name" => "Eswatini", "synonyms" => "SZ" },
    "231" => { "name" => "Ethiopia", "synonyms" => "ET" },
    "238" => { "name" => "Falkland Islands", "synonyms" => "" },
    "242" => { "name" => "Fiji", "synonyms" => "FJ" },
    "246" => { "name" => "Finland", "synonyms" => "FI" },
    "250" => { "name" => "France", "synonyms" => "FR" },
    "266" => { "name" => "Gabon", "synonyms" => "GA" },
    "270" => { "name" => "Gambia", "synonyms" => "" },
    "268" => { "name" => "Georgia", "synonyms" => "GE" },
    "276" => { "name" => "Germany", "synonyms" => "DE" },
    "288" => { "name" => "Ghana", "synonyms" => "GH" },
    "292" => { "name" => "Gibraltar", "synonyms" => "" },
    "300" => { "name" => "Greece", "synonyms" => "GR" },
    "308" => { "name" => "Grenada", "synonyms" => "GD" },
    "320" => { "name" => "Guatemala", "synonyms" => "GT" },
    "831" => { "name" => "Guernsey", "synonyms" => "" },
    "324" => { "name" => "Guinea", "synonyms" => "GN" },
    "624" => { "name" => "Guinea-Bissau", "synonyms" => "GW" },
    "328" => { "name" => "Guyana", "synonyms" => "GY" },
    "332" => { "name" => "Haiti", "synonyms" => "HT" },
    "340" => { "name" => "Honduras", "synonyms" => "HN" },
    "344" => { "name" => "Hong Kong", "synonyms" => "" },
    "348" => { "name" => "Hungary", "synonyms" => "HU" },
    "352" => { "name" => "Iceland", "synonyms" => "IS" },
    "356" => { "name" => "India", "synonyms" => "IN" },
    "360" => { "name" => "Indonesia", "synonyms" => "ID" },
    "364" => { "name" => "Iran", "synonyms" => "IR" },
    "368" => { "name" => "Iraq", "synonyms" => "IQ" },
    "372" => { "name" => "Ireland", "synonyms" => "IE" },
    "833" => { "name" => "Isle of Man", "synonyms" => "" },
    "376" => { "name" => "Israel", "synonyms" => "IL" },
    "380" => { "name" => "Italy", "synonyms" => "IT" },
    "388" => { "name" => "Jamaica", "synonyms" => "JM" },
    "392" => { "name" => "Japan", "synonyms" => "JP" },
    "832" => { "name" => "Jersey", "synonyms" => "" },
    "400" => { "name" => "Jordan", "synonyms" => "JO" },
    "398" => { "name" => "Kazakhstan", "synonyms" => "KZ" },
    "404" => { "name" => "Kenya", "synonyms" => "KE" },
    "296" => { "name" => "Kiribati", "synonyms" => "KI" },
    "414" => { "name" => "Kuwait", "synonyms" => "KW" },
    "417" => { "name" => "Kyrgyzstan", "synonyms" => "KG" },
    "418" => { "name" => "Laos", "synonyms" => "LA" },
    "428" => { "name" => "Latvia", "synonyms" => "LV" },
    "422" => { "name" => "Lebanon", "synonyms" => "LB" },
    "426" => { "name" => "Lesotho", "synonyms" => "LS" },
    "430" => { "name" => "Liberia", "synonyms" => "LR" },
    "434" => { "name" => "Libya", "synonyms" => "LY" },
    "438" => { "name" => "Liechtenstein", "synonyms" => "LI" },
    "440" => { "name" => "Lithuania", "synonyms" => "LT" },
    "442" => { "name" => "Luxembourg", "synonyms" => "LU" },
    "450" => { "name" => "Madagascar", "synonyms" => "MG" },
    "454" => { "name" => "Malawi", "synonyms" => "MW" },
    "458" => { "name" => "Malaysia", "synonyms" => "MY" },
    "462" => { "name" => "Maldives", "synonyms" => "MV" },
    "466" => { "name" => "Mali", "synonyms" => "ML" },
    "470" => { "name" => "Malta", "synonyms" => "MT" },
    "584" => { "name" => "Marshall Islands", "synonyms" => "MH" },
    "478" => { "name" => "Mauritania", "synonyms" => "MR" },
    "480" => { "name" => "Mauritius", "synonyms" => "MU" },
    "484" => { "name" => "Mexico", "synonyms" => "MX" },
    "583" => { "name" => "Micronesia (Federated States of)", "synonyms" => "" },
    "498" => { "name" => "Moldova", "synonyms" => "MD" },
    "492" => { "name" => "Monaco", "synonyms" => "MC" },
    "496" => { "name" => "Mongolia", "synonyms" => "MN" },
    "499" => { "name" => "Montenegro", "synonyms" => "ME" },
    "504" => { "name" => "Morocco", "synonyms" => "MA" },
    "508" => { "name" => "Mozambique", "synonyms" => "MZ" },
    "104" => { "name" => "Myanmar", "synonyms" => "" },
    "516" => { "name" => "Namibia", "synonyms" => "NA" },
    "520" => { "name" => "Nauru", "synonyms" => "NR" },
    "524" => { "name" => "Nepal", "synonyms" => "NP" },
    "528" => { "name" => "Netherlands", "synonyms" => "NL" },
    "554" => { "name" => "New Zealand", "synonyms" => "NZ" },
    "558" => { "name" => "Nicaragua", "synonyms" => "NI" },
    "562" => { "name" => "Niger", "synonyms" => "NE" },
    "566" => { "name" => "Nigeria", "synonyms" => "NG" },
    "807" => { "name" => "North Macedonia", "synonyms" => "MK" },
    "408" => { "name" => "North Korea", "synonyms" => "KP" },
    "578" => { "name" => "Norway", "synonyms" => "NO" },
    "512" => { "name" => "Oman", "synonyms" => "OM" },
    "586" => { "name" => "Pakistan", "synonyms" => "PK" },
    "585" => { "name" => "Palau", "synonyms" => "PW" },
    "275" => { "name" => "Palestine, State of", "synonyms" => "" },
    "591" => { "name" => "Panama", "synonyms" => "PA" },
    "598" => { "name" => "Papua New Guinea", "synonyms" => "PG" },
    "600" => { "name" => "Paraguay", "synonyms" => "PY" },
    "604" => { "name" => "Peru", "synonyms" => "PE" },
    "608" => { "name" => "Philippines", "synonyms" => "PH" },
    "616" => { "name" => "Poland", "synonyms" => "PL" },
    "620" => { "name" => "Portugal", "synonyms" => "PT" },
    "634" => { "name" => "Qatar", "synonyms" => "QA" },
    "642" => { "name" => "Romania", "synonyms" => "RO" },
    "643" => { "name" => "Russia", "synonyms" => "RU" },
    "646" => { "name" => "Rwanda", "synonyms" => "RW" },
    "659" => { "name" => "Saint Kitts and Nevis", "synonyms" => "" },
    "662" => { "name" => "Saint Lucia", "synonyms" => "" },
    "670" => { "name" => "Saint Vincent and the Grenadines", "synonyms" => "" },
    "882" => { "name" => "Samoa", "synonyms" => "WS" },
    "674" => { "name" => "San Marino", "synonyms" => "SM" },
    "678" => { "name" => "Sao Tome and Principe", "synonyms" => "ST" },
    "682" => { "name" => "Saudi Arabia", "synonyms" => "SA" },
    "686" => { "name" => "Senegal", "synonyms" => "SN" },
    "688" => { "name" => "Serbia", "synonyms" => "RS" },
    "690" => { "name" => "Seychelles", "synonyms" => "SC" },
    "694" => { "name" => "Sierra Leone", "synonyms" => "SL" },
    "702" => { "name" => "Singapore", "synonyms" => "SG" },
    "703" => { "name" => "Slovakia", "synonyms" => "SK" },
    "705" => { "name" => "Slovenia", "synonyms" => "SI" },
    "90" => { "name" => "Solomon Islands", "synonyms" => "SB" },
    "706" => { "name" => "Somalia", "synonyms" => "SO" },
    "710" => { "name" => "South Africa", "synonyms" => "ZA" },
    "410" => { "name" => "South Korea", "synonyms" => "KR" },
    "728" => { "name" => "South Sudan", "synonyms" => "SS" },
    "724" => { "name" => "Spain", "synonyms" => "ES" },
    "144" => { "name" => "Sri Lanka", "synonyms" => "LK" },
    "729" => { "name" => "Sudan", "synonyms" => "SD" },
    "740" => { "name" => "Suriname", "synonyms" => "SR" },
    "752" => { "name" => "Sweden", "synonyms" => "SE" },
    "756" => { "name" => "Switzerland", "synonyms" => "CH" },
    "760" => { "name" => "Syria", "synonyms" => "SY" },
    "158" => { "name" => "Taiwan", "synonyms" => "" },
    "762" => { "name" => "Tajikistan", "synonyms" => "TJ" },
    "834" => { "name" => "Tanzania", "synonyms" => "TZ" },
    "764" => { "name" => "Thailand", "synonyms" => "TH" },
    "626" => { "name" => "Timor-Leste", "synonyms" => "" },
    "768" => { "name" => "Togo", "synonyms" => "TG" },
    "776" => { "name" => "Tonga", "synonyms" => "TO" },
    "780" => { "name" => "Trinidad and Tobago", "synonyms" => "TT" },
    "788" => { "name" => "Tunisia", "synonyms" => "TN" },
    "792" => { "name" => "Turkey", "synonyms" => "TR" },
    "795" => { "name" => "Turkmenistan", "synonyms" => "TM" },
    "798" => { "name" => "Tuvalu", "synonyms" => "TV" },
    "800" => { "name" => "Uganda", "synonyms" => "UG" },
    "804" => { "name" => "Ukraine", "synonyms" => "UA" },
    "784" => { "name" => "United Arab Emirates", "synonyms" => "AE" },
    "826" => { "name" => "United Kingdom", "synonyms" => "GB,UK,England,Wales,Scotland,Northern Ireland" },
    "840" => { "name" => "United States of America", "synonyms" => "US,USA" },
    "858" => { "name" => "Uruguay", "synonyms" => "UY" },
    "860" => { "name" => "Uzbekistan", "synonyms" => "UZ" },
    "548" => { "name" => "Vanuatu", "synonyms" => "VU" },
    "336" => { "name" => "Vatican City", "synonyms" => "VA" },
    "862" => { "name" => "Venezuela", "synonyms" => "VE" },
    "704" => { "name" => "Vietnam", "synonyms" => "VN" },
    "887" => { "name" => "Yemen", "synonyms" => "YE" },
    "894" => { "name" => "Zambia", "synonyms" => "ZM" },
    "716" => { "name" => "Zimbabwe", "synonyms" => "ZW" },
  }.freeze

  def answer_label(log, _current_user = nil)
    ANSWER_OPTIONS[log.nationality_all.to_s]["name"]
  end
end
