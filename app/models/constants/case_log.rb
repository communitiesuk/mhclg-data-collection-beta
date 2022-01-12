module Constants::CaseLog
  BENEFITCAP = {
    "Yes - benefit cap" => 5,
    "Yes - removal of the spare room subsidy" => 4,
    "Yes - both the benefit cap and the removal of the spare room subsidy" => 6,
    "No" => 2,
    "Don’t know" => 3,
    "Prefer not to say" => 100,
  }.freeze

  UNITLETAS = {
    "Social rent basis" => 1,
    "Affordable rent basis" => 2,
    "Intermediate rent basis" => 4,
    "Don’t know" => 3,
  }.freeze

  BUILTYPE = {
    "Purpose built" => 1,
    "Converted from previous residential or non-residential property" => 2,
  }.freeze

  ECSTAT = {
    "Part-time - Less than 30 hours" => 2,
    "Full-time - 30 hours or more" => 1,
    "In government training into work, such as New Deal" => 3,
    "Jobseeker" => 4,
    "Retired" => 5,
    "Not seeking work" => 6,
    "Full-time student" => 7,
    "Unable to work because of long term sick or disability" => 8,
    "Child under 16" => 9,
    "Other" => 0,
    "Prefer not to say" => 10,
  }.freeze

  ETHNIC = {
    "White: English, Welsh, Scottish, Northern Irish or British" => 1,
    "White: Irish" => 2,
    "White: Gypsy or Irish Traveller" => 18,
    "White: Other" => 3,
    "Mixed: White and Black Caribbean" => 4,
    "Mixed: White and Black African" => 5,
    "Mixed: White and Asian" => 6,
    "Mixed: Other" => 7,
    "Asian or Asian British: Indian" => 8,
    "Asian or Asian British: Pakistani" => 9,
    "Asian or Asian British: Bangladeshi" => 10,
    "Asian or Asian British: Chinese" => 15,
    "Asian or Asian British: Other" => 11,
    "Black: Caribbean" => 12,
    "Black: African" => 13,
    "Black: Other" => 14,
    "Other Ethnic Group: Arab" => 16,
    "Other Ethnic Group: Other" => 19,
    "Prefer not to say" => 17,
  }.freeze

  HOMELESS = {
    "Yes - assessed as homeless by a local authority and owed a homelessness duty. Including if threatened with homelessness within 56 days" => 11,
    "Yes - other homelessness" => 7,
    "No" => 1,
  }.freeze

  ILLNESS = {
    "Yes" => 1,
    "No" => 2,
    "Prefer not to say" => 3,
  }.freeze

  LEFTREG = {
    "Yes" => 6,
    "No - they left up to 5 years ago" => 4,
    "No - they left more than 5 years ago" => 5,
    "Prefer not to say" => 3,
  }.freeze

  NATIONAL = {
    "UK national resident in UK" => 1,
    "A current or former reserve in the UK Armed Forces (excluding National Service)" => 100,
    "UK national returning from residence overseas" => 2,
    "Czech Republic" => 3,
    "Estonia" => 4,
    "Hungary" => 5,
    "Latvia" => 6,
    "Lithuania" => 7,
    "Poland" => 8,
    "Slovakia" => 9,
    "Bulgaria" => 14,
    "Romania" => 15,
    "Ireland" => 17,
    "Slovenia" => 10,
    "Croatia" => 16,
    "Other EU Economic Area (EEA country)" => 11,
    "Any other country" => 12,
    "Prefer not to say" => 13,
  }.freeze

  PREGNANCY = {
    "Yes" => 1,
    "No" => 2,
    "Prefer not to say" => 3,
  }.freeze

  PREVIOUS_TENANCY = {
    "Owner occupation (private) " => 26,
    "Owner occupation (low cost home ownership)" => 27,
    "Private sector tenancy" => 3,
    "Tied housing or rented with job" => 4,
    "Supported housing" => 5,
    "Sheltered accomodation" => 8,
    "Residential care home" => 9,
    "Living with friends or family" => 28,
    "Refuge" => 21,
    "Hospital" => 10,
    "Prison or approved probation hostel" => 29,
    "Direct access hostel" => 7,
    "Bed and breakfast" => 14,
    "Mobile home or caravan" => 23,
    "Any other temporary accommodation" => 18,
    "Home Office Asylum Support" => 24,
    "Children’s home or foster care" => 13,
    "Rough sleeping" => 19,
    "Other" => 25,
    "Fixed term Local Authority General Needs tenancy" => 30,
    "Lifetime Local Authority General Needs tenancy" => 31,
    "Fixed term PRP General Needs tenancy" => 32,
    "Lifetime PRP General Needs tenancy" => 33,
  }.freeze

  RESERVIST = {
    "Yes" => 1,
    "No" => 2,
    "Prefer not to say" => 3,
  }.freeze

  POLAR = {
    "No" => 0,
    "Yes" => 1,
  }.freeze

  POLAR2 = {
    "No" => 2,
    "Yes" => 1,
  }.freeze

  POLAR_WITH_UNKNOWN = {
    "No" => 2,
    "Yes" => 1,
    "Don’t know" => 3,
  }.freeze

  TENANCY = {
    "Secure (including flexible)" => 1,
    "Assured" => 2,
    "Assured Shorthold" => 4,
    "Licence agreement (almshouses only)" => 5,
    "Other" => 3,
  }.freeze

  LANDLORD = {
    "This landlord" => 1,
    "Another registered provider - includes housing association or local authority" => 2,
  }.freeze

  RSNVAC = {
    "First let of new-build property" => 15,
    "First let of conversion, rehabilitation or acquired property" => 16,
    "First let of leased property" => 17,
    "Tenant evicted due to arrears" => 10,
    "Tenant evicted due to ASB or other reason" => 11,
    "Previous tenant passed away (no succession)" => 5,
    "Tenant moved to other social housing provider" => 12,
    "Tenant abandoned property" => 6,
    "Tenant moved to private sector or other accommodation" => 8,
    "Relet to tenant who occupied same property as temporary accommodation" => 9,
    "Internal transfer (excluding renewals of a fixed-term tenancy)" => 13,
    "Renewal of fixed-term tenancy" => 14,
    "Tenant moved to care home" => 18,
    "Tenant involved in a succession downsize" => 19,
  }.freeze

  UNITTYPE_GN = {
    "Flat or maisonette" => 1,
    "Bedsit" => 2,
    "House" => 7,
    "Bungalow" => 8,
    "Shared flat or maisonette" => 4,
    "Shared house" => 9,
    "Shared bungalow" => 10,
    "Other" => 6,
  }.freeze

  INCFREQ = {
    "Weekly" => 1,
    "Monthly" => 2,
    "Yearly" => 3,
  }.freeze

  BENEFITS = {
    "All" => 1,
    "Some" => 2,
    "None" => 3,
    "Don’t know" => 4,
  }.freeze

  PERIOD = {
    "Weekly for 52 weeks" => 1,
    "Fortnightly" => 2,
    "Four-weekly" => 3,
    "Calendar monthly" => 4,
    "Weekly for 50 weeks" => 5,
    "Weekly for 49 weeks" => 6,
    "Weekly for 48 weeks" => 7,
    "Weekly for 47 weeks" => 8,
    "Weekly for 46 weeks" => 9,
    "Weekly for 53 weeks" => 10,
  }.freeze

  LATIME = {
    "Just moved to local authority area" => 1,
    "Less than 1 year" => 2,
    "1 to 2 years" => 7,
    "2 to 3 years" => 8,
    "3 to 4 years" => 9,
    "4 to 5 years" => 10,
    "5 years or more" => 5,
    "Don’t know" => 6,
  }.freeze

  HOUSING_BENEFIT = {
    "Housing Benefit, but not Universal Credit" => 1,
    "Universal Credit with housing element, but not Housing Benefit" => 6,
    "Universal Credit without housing element and no Housing Benefit" => 7,
    "Universal Credit and Housing Benefit" => 8,
    "Not Housing Benefit or Universal Credit" => 9,
    "Don’t know" => 3,
    "Prefer not to say" => 100,
  }.freeze

  REASON = {
    "Permanently decanted from another property owned by this landlord" => 1,
    "Left home country as a refugee" => 2,
    "Loss of tied accommodation" => 4,
    "Domestic abuse" => 7,
    "(Non violent) relationship breakdown with partner" => 8,
    "Asked to leave by family or friends" => 9,
    "Racial harassment" => 10,
    "Other problems with neighbours" => 11,
    "Property unsuitable because of overcrowding" => 12,
    "End of assured shorthold tenancy - no fault" => 40,
    "End of assured shorthold tenancy - tenant's fault" => 41,
    "End of fixed term tenancy - no fault" => 42,
    "End of fixed term tenancy - tenant's fault" => 43,
    "Repossession" => 34,
    "Under occupation - offered incentive to downsize" => 29,
    "Under occupation - no incentive" => 30,
    "Property unsuitable because of ill health / disability" => 13,
    "Property unsuitable because of poor condition" => 14,
    "Couldn't afford fees attached to renewing the tenancy" => 35,
    "Couldn't afford increase in rent" => 36,
    "Couldn't afford rent or mortgage - welfare reforms" => 37,
    "Couldn't afford rent or mortgage - employment" => 38,
    "Couldn't afford rent or mortgage - other" => 39,
    "To move nearer to family / friends / school" => 16,
    "To move nearer to work" => 17,
    "To move to accomodation with support" => 18,
    "To move to independent accomodation" => 19,
    "Hate crime" => 31,
    "Death of household member in last settled accomodation" => 46,
    "Discharged from prison" => 44,
    "Discharged from long stay hospital or similar institution" => 45,
    "Other" => 20,
    "Don’t know" => 28,
    "Prefer not to say" => 100,
  }.freeze

  ENGLISH_LA = {
    "Adur" => "E07000223",
    "Allerdale" => "E07000026",
    "Amber Valley" => "E07000032",
    "Arun" => "E07000224",
    "Ashfield" => "E07000170",
    "Ashford" => "E07000105",
    "Babergh" => "E07000200",
    "Barking and Dagenham" => "E09000002",
    "Barnet" => "E09000003",
    "Barnsley" => "E08000016",
    "Barrow-in-Furness" => "E07000027",
    "Basildon" => "E07000066",
    "Basingstoke and Deane" => "E07000084",
    "Bassetlaw" => "E07000171",
    "Bath and North East Somerset" => "E06000022",
    "Bedford" => "E06000055",
    "Bexley" => "E09000004",
    "Birmingham" => "E08000025",
    "Blaby" => "E07000129",
    "Blackburn with Darwen" => "E06000008",
    "Blackpool" => "E06000009",
    "Bolsover" => "E07000033",
    "Bolton" => "E08000001",
    "Boston" => "E07000136",
    "Bournemouth, Christchurch and Poole" => "E06000058",
    "Bracknell Forest" => "E06000036",
    "Bradford" => "E08000032",
    "Braintree" => "E07000067",
    "Breckland" => "E07000143",
    "Brent" => "E09000005",
    "Brentwood" => "E07000068",
    "Brighton and Hove" => "E06000043",
    "Bristol, City of" => "E06000023",
    "Broadland" => "E07000144",
    "Bromley" => "E09000006",
    "Bromsgrove" => "E07000234",
    "Broxbourne" => "E07000095",
    "Broxtowe" => "E07000172",
    "Buckinghamshire" => "E06000060",
    "Burnley" => "E07000117",
    "Bury" => "E08000002",
    "Calderdale" => "E08000033",
    "Cambridge" => "E07000008",
    "Camden" => "E09000007",
    "Cannock Chase" => "E07000192",
    "Canterbury" => "E07000106",
    "Carlisle" => "E07000028",
    "Castle Point" => "E07000069",
    "Central Bedfordshire" => "E06000056",
    "Charnwood" => "E07000130",
    "Chelmsford" => "E07000070",
    "Cheltenham" => "E07000078",
    "Cherwell" => "E07000177",
    "Cheshire East" => "E06000049",
    "Cheshire West and Chester" => "E06000050",
    "Chesterfield" => "E07000034",
    "Chichester" => "E07000225",
    "Chorley" => "E07000118",
    "City of London" => "E09000001",
    "Colchester" => "E07000071",
    "Copeland" => "E07000029",
    "Corby" => "E07000150",
    "Cornwall" => "E06000052",
    "Cotswold" => "E07000079",
    "County Durham" => "E06000047",
    "Coventry" => "E08000026",
    "Craven" => "E07000163",
    "Crawley" => "E07000226",
    "Croydon" => "E09000008",
    "Dacorum" => "E07000096",
    "Darlington" => "E06000005",
    "Dartford" => "E07000107",
    "Daventry" => "E07000151",
    "Derby" => "E06000015",
    "Derbyshire Dales" => "E07000035",
    "Doncaster" => "E08000017",
    "Dorset" => "E06000059",
    "Dover" => "E07000108",
    "Dudley" => "E08000027",
    "Ealing" => "E09000009",
    "East Cambridgeshire" => "E07000009",
    "East Devon" => "E07000040",
    "East Hampshire" => "E07000085",
    "East Hertfordshire" => "E07000242",
    "East Lindsey" => "E07000137",
    "East Northamptonshire" => "E07000152",
    "East Riding of Yorkshire" => "E06000011",
    "East Staffordshire" => "E07000193",
    "East Suffolk" => "E07000244",
    "Eastbourne" => "E07000061",
    "Eastleigh" => "E07000086",
    "Eden" => "E07000030",
    "Elmbridge" => "E07000207",
    "Enfield" => "E09000010",
    "Epping Forest" => "E07000072",
    "Epsom and Ewell" => "E07000208",
    "Erewash" => "E07000036",
    "Exeter" => "E07000041",
    "Fareham" => "E07000087",
    "Fenland" => "E07000010",
    "Folkestone and Hythe" => "E07000112",
    "Forest of Dean" => "E07000080",
    "Fylde" => "E07000119",
    "Gateshead" => "E08000037",
    "Gedling" => "E07000173",
    "Gloucester" => "E07000081",
    "Gosport" => "E07000088",
    "Gravesham" => "E07000109",
    "Great Yarmouth" => "E07000145",
    "Greenwich" => "E09000011",
    "Guildford" => "E07000209",
    "Gwynedd" => "W06000002",
    "Hackney" => "E09000012",
    "Halton" => "E06000006",
    "Hambleton" => "E07000164",
    "Hammersmith and Fulham" => "E09000013",
    "Harborough" => "E07000131",
    "Haringey" => "E09000014",
    "Harlow" => "E07000073",
    "Harrogate" => "E07000165",
    "Harrow" => "E09000015",
    "Hart" => "E07000089",
    "Hartlepool" => "E06000001",
    "Hastings" => "E07000062",
    "Havant" => "E07000090",
    "Havering" => "E09000016",
    "Herefordshire, County of" => "E06000019",
    "Hertsmere" => "E07000098",
    "High Peak" => "E07000037",
    "Highland" => "S12000017",
    "Hillingdon" => "E09000017",
    "Hinckley and Bosworth" => "E07000132",
    "Horsham" => "E07000227",
    "Hounslow" => "E09000018",
    "Huntingdonshire" => "E07000011",
    "Hyndburn" => "E07000120",
    "Ipswich" => "E07000202",
    "Isle of Wight" => "E06000046",
    "Isles of Scilly" => "E06000053",
    "Islington" => "E09000019",
    "Kensington and Chelsea" => "E09000020",
    "Kettering" => "E07000153",
    "King's Lynn and West Norfolk" => "E07000146",
    "Kingston upon Hull, City of" => "E06000010",
    "Kingston upon Thames" => "E09000021",
    "Kirklees" => "E08000034",
    "Knowsley" => "E08000011",
    "Lambeth" => "E09000022",
    "Lancaster" => "E07000121",
    "Leeds" => "E08000035",
    "Leicester" => "E06000016",
    "Lewes" => "E07000063",
    "Lewisham" => "E09000023",
    "Lichfield" => "E07000194",
    "Lincoln" => "E07000138",
    "Liverpool" => "E08000012",
    "Luton" => "E06000032",
    "Maidstone" => "E07000110",
    "Maldon" => "E07000074",
    "Malvern Hills" => "E07000235",
    "Manchester" => "E08000003",
    "Mansfield" => "E07000174",
    "Medway" => "E06000035",
    "Melton" => "E07000133",
    "Mendip" => "E07000187",
    "Merton" => "E09000024",
    "Mid Devon" => "E07000042",
    "Mid Suffolk" => "E07000203",
    "Mid Sussex" => "E07000228",
    "Middlesbrough" => "E06000002",
    "Milton Keynes" => "E06000042",
    "Mole Valley" => "E07000210",
    "New Forest" => "E07000091",
    "Newark and Sherwood" => "E07000175",
    "Newcastle upon Tyne" => "E08000021",
    "Newcastle-under-Lyme" => "E07000195",
    "Newham" => "E09000025",
    "North Devon" => "E07000043",
    "North East Derbyshire" => "E07000038",
    "North East Lincolnshire" => "E06000012",
    "North Hertfordshire" => "E07000099",
    "North Kesteven" => "E07000139",
    "North Lincolnshire" => "E06000013",
    "North Norfolk" => "E07000147",
    "North Somerset" => "E06000024",
    "North Tyneside" => "E08000022",
    "North Warwickshire" => "E07000218",
    "North West Leicestershire" => "E07000134",
    "Northampton" => "E07000154",
    "Northumberland" => "E06000057",
    "Norwich" => "E07000148",
    "Nottingham" => "E06000018",
    "Nuneaton and Bedworth" => "E07000219",
    "Oadby and Wigston" => "E07000135",
    "Oldham" => "E08000004",
    "Oxford" => "E07000178",
    "Pendle" => "E07000122",
    "Peterborough" => "E06000031",
    "Plymouth" => "E06000026",
    "Portsmouth" => "E06000044",
    "Preston" => "E07000123",
    "Reading" => "E06000038",
    "Redbridge" => "E09000026",
    "Redcar and Cleveland" => "E06000003",
    "Redditch" => "E07000236",
    "Reigate and Banstead" => "E07000211",
    "Ribble Valley" => "E07000124",
    "Richmond upon Thames" => "E09000027",
    "Richmondshire" => "E07000166",
    "Rochdale" => "E08000005",
    "Rochford" => "E07000075",
    "Rossendale" => "E07000125",
    "Rother" => "E07000064",
    "Rotherham" => "E08000018",
    "Rugby" => "E07000220",
    "Runnymede" => "E07000212",
    "Rushcliffe" => "E07000176",
    "Rushmoor" => "E07000092",
    "Rutland" => "E06000017",
    "Ryedale" => "E07000167",
    "Salford" => "E08000006",
    "Sandwell" => "E08000028",
    "Scarborough" => "E07000168",
    "Sedgemoor" => "E07000188",
    "Sefton" => "E08000014",
    "Selby" => "E07000169",
    "Sevenoaks" => "E07000111",
    "Sheffield" => "E08000019",
    "Shropshire" => "E06000051",
    "Slough" => "E06000039",
    "Solihull" => "E08000029",
    "Somerset West and Taunton" => "E07000246",
    "South Cambridgeshire" => "E07000012",
    "South Derbyshire" => "E07000039",
    "South Gloucestershire" => "E06000025",
    "South Hams" => "E07000044",
    "South Holland" => "E07000140",
    "South Kesteven" => "E07000141",
    "South Lakeland" => "E07000031",
    "South Norfolk" => "E07000149",
    "South Northamptonshire" => "E07000155",
    "South Oxfordshire" => "E07000179",
    "South Ribble" => "E07000126",
    "South Somerset" => "E07000189",
    "South Staffordshire" => "E07000196",
    "South Tyneside" => "E08000023",
    "Southampton" => "E06000045",
    "Southend-on-Sea" => "E06000033",
    "Southwark" => "E09000028",
    "Spelthorne" => "E07000213",
    "St Albans" => "E07000240",
    "St. Helens" => "E08000013",
    "Stafford" => "E07000197",
    "Staffordshire Moorlands" => "E07000198",
    "Stevenage" => "E07000243",
    "Stockport" => "E08000007",
    "Stockton-on-Tees" => "E06000004",
    "Stoke-on-Trent" => "E06000021",
    "Stratford-on-Avon" => "E07000221",
    "Stroud" => "E07000082",
    "Sunderland" => "E08000024",
    "Surrey Heath" => "E07000214",
    "Sutton" => "E09000029",
    "Swale" => "E07000113",
    "Swindon" => "E06000030",
    "Tameside" => "E08000008",
    "Tamworth" => "E07000199",
    "Tandridge" => "E07000215",
    "Teignbridge" => "E07000045",
    "Telford and Wrekin" => "E06000020",
    "Tendring" => "E07000076",
    "Test Valley" => "E07000093",
    "Tewkesbury" => "E07000083",
    "Thanet" => "E07000114",
    "Three Rivers" => "E07000102",
    "Thurrock" => "E06000034",
    "Tonbridge and Malling" => "E07000115",
    "Torbay" => "E06000027",
    "Torridge" => "E07000046",
    "Tower Hamlets" => "E09000030",
    "Trafford" => "E08000009",
    "Tunbridge Wells" => "E07000116",
    "Uttlesford" => "E07000077",
    "Vale of White Horse" => "E07000180",
    "Wakefield" => "E08000036",
    "Walsall" => "E08000030",
    "Waltham Forest" => "E09000031",
    "Wandsworth" => "E09000032",
    "Warrington" => "E06000007",
    "Warwick" => "E07000222",
    "Watford" => "E07000103",
    "Waverley" => "E07000216",
    "Wealden" => "E07000065",
    "Wellingborough" => "E07000156",
    "Welwyn Hatfield" => "E07000241",
    "West Berkshire" => "E06000037",
    "West Devon" => "E07000047",
    "West Lancashire" => "E07000127",
    "West Lindsey" => "E07000142",
    "West Oxfordshire" => "E07000181",
    "West Suffolk" => "E07000245",
    "Westminster" => "E09000033",
    "Wigan" => "E08000010",
    "Wiltshire" => "E06000054",
    "Winchester" => "E07000094",
    "Windsor and Maidenhead" => "E06000040",
    "Wirral" => "E08000015",
    "Woking" => "E07000217",
    "Wokingham" => "E06000041",
    "Wolverhampton" => "E08000031",
    "Worcester" => "E07000237",
    "Worthing" => "E07000229",
    "Wychavon" => "E07000238",
    "Wyre" => "E07000128",
    "Wyre Forest" => "E07000239",
    "York" => "E06000014",
  }.freeze

  UK_LA = {
    "Aberdeen City" => "S12000033",
    "Aberdeenshire" => "S12000034",
    "Adur" => "E07000223",
    "Allerdale" => "E07000026",
    "Amber Valley" => "E07000032",
    "Angus" => "S12000041",
    "Antrim and Newtownabbey" => "N09000001",
    "Ards and North Down" => "N09000011",
    "Argyll and Bute" => "S12000035",
    "Armagh City, Banbridge and Craigavon" => "N09000002",
    "Arun" => "E07000224",
    "Ashfield" => "E07000170",
    "Ashford" => "E07000105",
    "Babergh" => "E07000200",
    "Barking and Dagenham" => "E09000002",
    "Barnet" => "E09000003",
    "Barnsley" => "E08000016",
    "Barrow-in-Furness" => "E07000027",
    "Basildon" => "E07000066",
    "Basingstoke and Deane" => "E07000084",
    "Bassetlaw" => "E07000171",
    "Bath and North East Somerset" => "E06000022",
    "Bedford" => "E06000055",
    "Belfast" => "N09000003",
    "Bexley" => "E09000004",
    "Birmingham" => "E08000025",
    "Blaby" => "E07000129",
    "Blackburn with Darwen" => "E06000008",
    "Blackpool" => "E06000009",
    "Blaenau Gwent" => "W06000019",
    "Bolsover" => "E07000033",
    "Bolton" => "E08000001",
    "Boston" => "E07000136",
    "Bournemouth, Christchurch and Poole" => "E06000058",
    "Bracknell Forest" => "E06000036",
    "Bradford" => "E08000032",
    "Braintree" => "E07000067",
    "Breckland" => "E07000143",
    "Brent" => "E09000005",
    "Brentwood" => "E07000068",
    "Bridgend" => "W06000013",
    "Brighton and Hove" => "E06000043",
    "Bristol, City of" => "E06000023",
    "Broadland" => "E07000144",
    "Bromley" => "E09000006",
    "Bromsgrove" => "E07000234",
    "Broxbourne" => "E07000095",
    "Broxtowe" => "E07000172",
    "Buckinghamshire" => "E06000060",
    "Burnley" => "E07000117",
    "Bury" => "E08000002",
    "Caerphilly" => "W06000018",
    "Calderdale" => "E08000033",
    "Cambridge" => "E07000008",
    "Camden" => "E09000007",
    "Cannock Chase" => "E07000192",
    "Canterbury" => "E07000106",
    "Cardiff" => "W06000015",
    "Carlisle" => "E07000028",
    "Carmarthenshire" => "W06000010",
    "Castle Point" => "E07000069",
    "Causeway Coast and Glens" => "N09000004",
    "Central Bedfordshire" => "E06000056",
    "Ceredigion" => "W06000008",
    "Charnwood" => "E07000130",
    "Chelmsford" => "E07000070",
    "Cheltenham" => "E07000078",
    "Cherwell" => "E07000177",
    "Cheshire East" => "E06000049",
    "Cheshire West and Chester" => "E06000050",
    "Chesterfield" => "E07000034",
    "Chichester" => "E07000225",
    "Chorley" => "E07000118",
    "City of Edinburgh" => "S12000036",
    "City of London" => "E09000001",
    "Clackmannanshire" => "S12000005",
    "Colchester" => "E07000071",
    "Conwy" => "W06000003",
    "Copeland" => "E07000029",
    "Corby" => "E07000150",
    "Cornwall" => "E06000052",
    "Cotswold" => "E07000079",
    "County Durham" => "E06000047",
    "Coventry" => "E08000026",
    "Craven" => "E07000163",
    "Crawley" => "E07000226",
    "Croydon" => "E09000008",
    "Dacorum" => "E07000096",
    "Darlington" => "E06000005",
    "Dartford" => "E07000107",
    "Daventry" => "E07000151",
    "Denbighshire" => "W06000004",
    "Derby" => "E06000015",
    "Derbyshire Dales" => "E07000035",
    "Derry City and Strabane" => "N09000005",
    "Doncaster" => "E08000017",
    "Dorset" => "E06000059",
    "Dover" => "E07000108",
    "Dudley" => "E08000027",
    "Dumfries and Galloway" => "S12000006",
    "Dundee City" => "S12000042",
    "Ealing" => "E09000009",
    "East Ayrshire" => "S12000008",
    "East Cambridgeshire" => "E07000009",
    "East Devon" => "E07000040",
    "East Dunbartonshire" => "S12000045",
    "East Hampshire" => "E07000085",
    "East Hertfordshire" => "E07000242",
    "East Lindsey" => "E07000137",
    "East Lothian" => "S12000010",
    "East Northamptonshire" => "E07000152",
    "East Renfrewshire" => "S12000011",
    "East Riding of Yorkshire" => "E06000011",
    "East Staffordshire" => "E07000193",
    "East Suffolk" => "E07000244",
    "Eastbourne" => "E07000061",
    "Eastleigh" => "E07000086",
    "Eden" => "E07000030",
    "Elmbridge" => "E07000207",
    "Enfield" => "E09000010",
    "Epping Forest" => "E07000072",
    "Epsom and Ewell" => "E07000208",
    "Erewash" => "E07000036",
    "Exeter" => "E07000041",
    "Falkirk" => "S12000014",
    "Fareham" => "E07000087",
    "Fenland" => "E07000010",
    "Fermanagh and Omagh" => "N09000006",
    "Fife" => "S12000047",
    "Flintshire" => "W06000005",
    "Folkestone and Hythe" => "E07000112",
    "Forest of Dean" => "E07000080",
    "Fylde" => "E07000119",
    "Gateshead" => "E08000037",
    "Gedling" => "E07000173",
    "Glasgow City" => "S12000049",
    "Gloucester" => "E07000081",
    "Gosport" => "E07000088",
    "Gravesham" => "E07000109",
    "Great Yarmouth" => "E07000145",
    "Greenwich" => "E09000011",
    "Guildford" => "E07000209",
    "Gwynedd" => "W06000002",
    "Hackney" => "E09000012",
    "Halton" => "E06000006",
    "Hambleton" => "E07000164",
    "Hammersmith and Fulham" => "E09000013",
    "Harborough" => "E07000131",
    "Haringey" => "E09000014",
    "Harlow" => "E07000073",
    "Harrogate" => "E07000165",
    "Harrow" => "E09000015",
    "Hart" => "E07000089",
    "Hartlepool" => "E06000001",
    "Hastings" => "E07000062",
    "Havant" => "E07000090",
    "Havering" => "E09000016",
    "Herefordshire, County of" => "E06000019",
    "Hertsmere" => "E07000098",
    "High Peak" => "E07000037",
    "Highland" => "S12000017",
    "Hillingdon" => "E09000017",
    "Hinckley and Bosworth" => "E07000132",
    "Horsham" => "E07000227",
    "Hounslow" => "E09000018",
    "Huntingdonshire" => "E07000011",
    "Hyndburn" => "E07000120",
    "Inverclyde" => "S12000018",
    "Ipswich" => "E07000202",
    "Isle of Anglesey" => "W06000001",
    "Isle of Wight" => "E06000046",
    "Isles of Scilly" => "E06000053",
    "Islington" => "E09000019",
    "Kensington and Chelsea" => "E09000020",
    "Kettering" => "E07000153",
    "King's Lynn and West Norfolk" => "E07000146",
    "Kingston upon Hull, City of" => "E06000010",
    "Kingston upon Thames" => "E09000021",
    "Kirklees" => "E08000034",
    "Knowsley" => "E08000011",
    "Lambeth" => "E09000022",
    "Lancaster" => "E07000121",
    "Leeds" => "E08000035",
    "Leicester" => "E06000016",
    "Lewes" => "E07000063",
    "Lewisham" => "E09000023",
    "Lichfield" => "E07000194",
    "Lincoln" => "E07000138",
    "Lisburn and Castlereagh" => "N09000007",
    "Liverpool" => "E08000012",
    "Luton" => "E06000032",
    "Maidstone" => "E07000110",
    "Maldon" => "E07000074",
    "Malvern Hills" => "E07000235",
    "Manchester" => "E08000003",
    "Mansfield" => "E07000174",
    "Medway" => "E06000035",
    "Melton" => "E07000133",
    "Mendip" => "E07000187",
    "Merthyr Tydfil" => "W06000024",
    "Merton" => "E09000024",
    "Mid Devon" => "E07000042",
    "Mid Suffolk" => "E07000203",
    "Mid Sussex" => "E07000228",
    "Mid Ulster" => "N09000009",
    "Mid and East Antrim" => "N09000008",
    "Middlesbrough" => "E06000002",
    "Midlothian" => "S12000019",
    "Milton Keynes" => "E06000042",
    "Mole Valley" => "E07000210",
    "Monmouthshire" => "W06000021",
    "Moray" => "S12000020",
    "Na h-Eileanan Siar" => "S12000013",
    "Neath Port Talbot" => "W06000012",
    "New Forest" => "E07000091",
    "Newark and Sherwood" => "E07000175",
    "Newcastle upon Tyne" => "E08000021",
    "Newcastle-under-Lyme" => "E07000195",
    "Newham" => "E09000025",
    "Newport" => "W06000022",
    "Newry, Mourne and Down" => "N09000010",
    "North Ayrshire" => "S12000021",
    "North Devon" => "E07000043",
    "North East Derbyshire" => "E07000038",
    "North East Lincolnshire" => "E06000012",
    "North Hertfordshire" => "E07000099",
    "North Kesteven" => "E07000139",
    "North Lanarkshire" => "S12000050",
    "North Lincolnshire" => "E06000013",
    "North Norfolk" => "E07000147",
    "North Somerset" => "E06000024",
    "North Tyneside" => "E08000022",
    "North Warwickshire" => "E07000218",
    "North West Leicestershire" => "E07000134",
    "Northampton" => "E07000154",
    "Northumberland" => "E06000057",
    "Norwich" => "E07000148",
    "Nottingham" => "E06000018",
    "Nuneaton and Bedworth" => "E07000219",
    "Oadby and Wigston" => "E07000135",
    "Oldham" => "E08000004",
    "Orkney Islands" => "S12000023",
    "Oxford" => "E07000178",
    "Pembrokeshire" => "W06000009",
    "Pendle" => "E07000122",
    "Perth and Kinross" => "S12000048",
    "Peterborough" => "E06000031",
    "Plymouth" => "E06000026",
    "Portsmouth" => "E06000044",
    "Powys" => "W06000023",
    "Preston" => "E07000123",
    "Reading" => "E06000038",
    "Redbridge" => "E09000026",
    "Redcar and Cleveland" => "E06000003",
    "Redditch" => "E07000236",
    "Reigate and Banstead" => "E07000211",
    "Renfrewshire" => "S12000038",
    "Rhondda Cynon Taf" => "W06000016",
    "Ribble Valley" => "E07000124",
    "Richmond upon Thames" => "E09000027",
    "Richmondshire" => "E07000166",
    "Rochdale" => "E08000005",
    "Rochford" => "E07000075",
    "Rossendale" => "E07000125",
    "Rother" => "E07000064",
    "Rotherham" => "E08000018",
    "Rugby" => "E07000220",
    "Runnymede" => "E07000212",
    "Rushcliffe" => "E07000176",
    "Rushmoor" => "E07000092",
    "Rutland" => "E06000017",
    "Ryedale" => "E07000167",
    "Salford" => "E08000006",
    "Sandwell" => "E08000028",
    "Scarborough" => "E07000168",
    "Scottish Borders" => "S12000026",
    "Sedgemoor" => "E07000188",
    "Sefton" => "E08000014",
    "Selby" => "E07000169",
    "Sevenoaks" => "E07000111",
    "Sheffield" => "E08000019",
    "Shetland Islands" => "S12000027",
    "Shropshire" => "E06000051",
    "Slough" => "E06000039",
    "Solihull" => "E08000029",
    "Somerset West and Taunton" => "E07000246",
    "South Ayrshire" => "S12000028",
    "South Cambridgeshire" => "E07000012",
    "South Derbyshire" => "E07000039",
    "South Gloucestershire" => "E06000025",
    "South Hams" => "E07000044",
    "South Holland" => "E07000140",
    "South Kesteven" => "E07000141",
    "South Lakeland" => "E07000031",
    "South Lanarkshire" => "S12000029",
    "South Norfolk" => "E07000149",
    "South Northamptonshire" => "E07000155",
    "South Oxfordshire" => "E07000179",
    "South Ribble" => "E07000126",
    "South Somerset" => "E07000189",
    "South Staffordshire" => "E07000196",
    "South Tyneside" => "E08000023",
    "Southampton" => "E06000045",
    "Southend-on-Sea" => "E06000033",
    "Southwark" => "E09000028",
    "Spelthorne" => "E07000213",
    "St Albans" => "E07000240",
    "St. Helens" => "E08000013",
    "Stafford" => "E07000197",
    "Staffordshire Moorlands" => "E07000198",
    "Stevenage" => "E07000243",
    "Stirling" => "S12000030",
    "Stockport" => "E08000007",
    "Stockton-on-Tees" => "E06000004",
    "Stoke-on-Trent" => "E06000021",
    "Stratford-on-Avon" => "E07000221",
    "Stroud" => "E07000082",
    "Sunderland" => "E08000024",
    "Surrey Heath" => "E07000214",
    "Sutton" => "E09000029",
    "Swale" => "E07000113",
    "Swansea" => "W06000011",
    "Swindon" => "E06000030",
    "Tameside" => "E08000008",
    "Tamworth" => "E07000199",
    "Tandridge" => "E07000215",
    "Teignbridge" => "E07000045",
    "Telford and Wrekin" => "E06000020",
    "Tendring" => "E07000076",
    "Test Valley" => "E07000093",
    "Tewkesbury" => "E07000083",
    "Thanet" => "E07000114",
    "Three Rivers" => "E07000102",
    "Thurrock" => "E06000034",
    "Tonbridge and Malling" => "E07000115",
    "Torbay" => "E06000027",
    "Torfaen" => "W06000020",
    "Torridge" => "E07000046",
    "Tower Hamlets" => "E09000030",
    "Trafford" => "E08000009",
    "Tunbridge Wells" => "E07000116",
    "Uttlesford" => "E07000077",
    "Vale of Glamorgan" => "W06000014",
    "Vale of White Horse" => "E07000180",
    "Wakefield" => "E08000036",
    "Walsall" => "E08000030",
    "Waltham Forest" => "E09000031",
    "Wandsworth" => "E09000032",
    "Warrington" => "E06000007",
    "Warwick" => "E07000222",
    "Watford" => "E07000103",
    "Waverley" => "E07000216",
    "Wealden" => "E07000065",
    "Wellingborough" => "E07000156",
    "Welwyn Hatfield" => "E07000241",
    "West Berkshire" => "E06000037",
    "West Devon" => "E07000047",
    "West Dunbartonshire" => "S12000039",
    "West Lancashire" => "E07000127",
    "West Lindsey" => "E07000142",
    "West Lothian" => "S12000040",
    "West Oxfordshire" => "E07000181",
    "West Suffolk" => "E07000245",
    "Westminster" => "E09000033",
    "Wigan" => "E08000010",
    "Wiltshire" => "E06000054",
    "Winchester" => "E07000094",
    "Windsor and Maidenhead" => "E06000040",
    "Wirral" => "E08000015",
    "Woking" => "E07000217",
    "Wokingham" => "E06000041",
    "Wolverhampton" => "E08000031",
    "Worcester" => "E07000237",
    "Worthing" => "E07000229",
    "Wrexham" => "W06000006",
    "Wychavon" => "E07000238",
    "Wyre" => "E07000128",
    "Wyre Forest" => "E07000239",
    "York" => "E06000014",
    "Northern Ireland" => "N92000002",
    "Scotland" => "S92000003",
    "Wales" => "W92000004",
    "Outside UK" => "9300000XX",
  }.freeze

  ARMED_FORCES = {
    "A current or former regular in the UK Armed Forces (excluding National Service)" => 1,
    "No" => 2,
    "Tenant prefers not to say" => 3,
    "A current or former reserve in the UK Armed Forces (excluding National Service)" => 4,
    "A spouse / civil partner of a UK Armed Forces member who has separated or been bereaved within the last 2 years" => 5,
  }.freeze

  RENT_TYPE = {
    "Social Rent" => 1,
    "Affordable Rent" => 2,
    "Intermediate Rent" => 3,
  }.freeze

  NEEDS_TYPE = {
    "General needs" => 1,
    "Supported housing" => 2,
  }.freeze

  LET_TYPE = {
    "Social Rent General needs PRP" => 1,
    "Social Rent Supported housing PRP" => 2,
    "Social Rent General needs LA" => 3,
    "Social Rent Supported housing LA" => 4,
    "Affordable Rent General needs PRP" => 5,
    "Affordable Rent Supported housing PRP" => 6,
    "Affordable Rent General needs LA" => 7,
    "Affordable Rent Supported housing LA" => 8,
    "Intermediate Rent General needs PRP" => 9,
    "Intermediate Rent Supported housing PRP" => 10,
    "Intermediate Rent General needs LA" => 11,
    "Intermediate Rent Supported housing LA" => 12,
  }.freeze

  RENT_TYPE_MAPPING = {
    "Social rent" => "Social Rent",
    "Affordable rent" => "Affordable Rent",
    "London Affordable rent" => "Affordable Rent",
    "Rent to buy" => "Intermediate Rent",
    "London living rent" => "Intermediate Rent",
    "Other intermediate rent product" => "Intermediate Rent",
  }.freeze

  LONDON_BOROUGHS = ["City of London",
                     "Barking and Dagenham",
                     "Barnet",
                     "Bexley",
                     "Brent",
                     "Bromley",
                     "Camden",
                     "Croydon",
                     "Ealing",
                     "Enfield",
                     "Greenwich",
                     "Hackney",
                     "Hammersmith and Fulham",
                     "Haringey",
                     "Harrow",
                     "Havering",
                     "Hillingdon",
                     "Hounslow",
                     "Islington",
                     "Kensington and Chelsea",
                     "Kingston-upon-Thames",
                     "Lambeth",
                     "Lewisham",
                     "Merton",
                     "Newham",
                     "Redbridge",
                     "Richmond-upon-Thames",
                     "Southwark",
                     "Sutton",
                     "Tower Hamlets",
                     "Waltham Forest",
                     "Wandsworth",
                     "Westminster"].freeze

  RELAT = {
    "Child - includes young adult and grown-up" => "C",
    "Partner" => "P",
    "Other" => "X",
    "Prefer not to say" => "R",
  }.freeze

  GENDER = {
    "Female" => "F",
    "Male" => "M",
    "Non-binary" => "X",
    "Prefer not to say" => "R",
  }.freeze

  NET_INCOME_KNOWN = {
    "Yes – the household has a weekly income" => 0,
    "Yes – the household has a monthly income" => 1,
    "Yes – the household has a yearly income" => 2,
    "Tenant prefers not to say" => 3,
  }.freeze
end
