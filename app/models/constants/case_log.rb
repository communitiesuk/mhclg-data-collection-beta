module Constants::CaseLog
  BENEFITCAP = {
    "Yes - benefit cap" => 5,
    "Yes - removal of the spare room subsidy" => 4,
    "Yes - both the benefit cap and the removal of the spare room subsidy" => 6,
    "No" => 2,
    "Do not know" => 3,
    "Prefer not to say" => 100,
  }.freeze

  UNITLETAS = {
    "Social rent basis" => 1,
    "Affordable rent basis" => 2,
    "Intermediate rent basis" => 4,
    "Do not know" => 3,
  }.freeze

  BUILTYPE = {
    "Purpose built" => 1,
    "Conversion" => 2,
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
    "White: English/Scottish/Welsh/Northern Irish/British" => 1,
    "White: Irish" => 2,
    "White: Gypsy/Irish Traveller" => 18,
    "White: Other" => 3,
    "Mixed: White & Black Caribbean" => 4,
    "Mixed: White & Black African" => 5,
    "Mixed: White & Asian" => 6,
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
    "Do not know" => 3,
  }.freeze

  LEFTREG = {
    "Yes" => 6,
    "No - they left up to 5 years ago" => 4,
    "No - they left more than 5 years ago" => 5,
    "Prefer not to say" => 3,
  }.freeze

  NATIONAL = {
    "UK national resident in UK" => 1,
    "A current or former reserve in the UK Armed Forces (exc. National Service)" => 100,
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
    "Prison / approved probation hostel" => 29,
    "Direct access hostel" => 7,
    "Bed & Breakfast" => 14,
    "Mobile home / caravan" => 23,
    "Any other temporary accommodation" => 18,
    "Home Office Asylum Support" => 24,
    "Children’s home / foster care" => 13,
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
    "Do not know" => 3,
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
    "First let of newbuild property" => 15,
    "First let of conversion/rehabilitation/acquired property" => 16,
    "First let of leased property" => 17,
    "Tenant evicted due to arrears" => 10,
    "Tenant evicted due to ASB or other reason" => 11,
    "Tenant died (no succession)" => 5,
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
    "Flat / maisonette" => 1,
    "Bed-sit" => 2,
    "House" => 7,
    "Bungalow" => 8,
    "Shared flat / maisonette" => 4,
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
    "Do not know" => 4,
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
    "Do not know" => 6,
  }.freeze

  HOUSING_BENEFIT = {
    "Housing Benefit, but not Universal Credit" => 1,
    "Universal Credit with housing element, but not Housing Benefit" => 6,
    "Universal Credit without housing element and no Housing Benefit" => 7,
    "Universal Credit and Housing Benefit" => 8,
    "Not Housing Benefit or Universal Credit" => 9,
    "Do not know" => 3,
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
    "Do not know" => 28,
    "Prefer not to say" => 100,
  }.freeze

  LA = {
    "Hartlepool" => "E06000001",
    "Na h-Eileanan Siar" => "S12000013",
    "Middlesbrough" => "E06000002",
    "Redcar and Cleveland" => "E06000003",
    "Stockton-on-Tees" => "E06000004",
    "Darlington" => "E06000005",
    "Halton" => "E06000006",
    "Warrington" => "E06000007",
    "Blackburn with Darwen" => "E06000008",
    "Blackpool" => "E06000009",
    "Kingston upon Hull, City of" => "E06000010",
    "East Riding of Yorkshire" => "E06000011",
    "North East Lincolnshire" => "E06000012",
    "North Lincolnshire" => "E06000013",
    "York" => "E06000014",
    "Derby" => "E06000015",
    "Leicester" => "E06000016",
    "Rutland" => "E06000017",
    "Nottingham" => "E06000018",
    "Herefordshire, County of" => "E06000019",
    "Telford and Wrekin" => "E06000020",
    "Stoke-on-Trent" => "E06000021",
    "Bath and North East Somerset" => "E06000022",
    "Bristol, City of" => "E06000023",
    "North Somerset" => "E06000024",
    "South Gloucestershire" => "E06000025",
    "Plymouth" => "E06000026",
    "Torbay" => "E06000027",
    "Swindon" => "E06000030",
    "Peterborough" => "E06000031",
    "Luton" => "E06000032",
    "Southend-on-Sea" => "E06000033",
    "Thurrock" => "E06000034",
    "Medway" => "E06000035",
    "Bracknell Forest" => "E06000036",
    "West Berkshire" => "E06000037",
    "Reading" => "E06000038",
    "Slough" => "E06000039",
    "Windsor and Maidenhead" => "E06000040",
    "Wokingham" => "E06000041",
    "Milton Keynes" => "E06000042",
    "Brighton and Hove" => "E06000043",
    "Portsmouth" => "E06000044",
    "Southampton" => "E06000045",
    "Isle of Wight" => "E06000046",
    "County Durham" => "E06000047",
    "Cheshire East" => "E06000049",
    "Cheshire West and Chester" => "E06000050",
    "Shropshire" => "E06000051",
    "Cornwall" => "E06000052",
    "Isles of Scilly" => "E06000053",
    "Wiltshire" => "E06000054",
    "Bedford" => "E06000055",
    "Central Bedfordshire" => "E06000056",
    "Northumberland" => "E06000057",
    "Bournemouth, Christchurch and Poole" => "E06000058",
    "North Warwickshire" => "E07000218",
    "Nuneaton and Bedworth" => "E07000219",
    "Rugby" => "E07000220",
    "Stratford-on-Avon" => "E07000221",
    "Warwick" => "E07000222",
    "Adur" => "E07000223",
    "Arun" => "E07000224",
    "Chichester" => "E07000225",
    "Crawley" => "E07000226",
    "Horsham" => "E07000227",
    "Mid Sussex" => "E07000228",
    "Worthing" => "E07000229",
    "Bromsgrove" => "E07000234",
    "Malvern Hills" => "E07000235",
    "Redditch" => "E07000236",
    "Worcester" => "E07000237",
    "Wychavon" => "E07000238",
    "Wyre Forest" => "E07000239",
    "St Albans" => "E07000240",
    "Welwyn Hatfield" => "E07000241",
    "East Hertfordshire" => "E07000242",
    "Stevenage" => "E07000243",
    "East Suffolk" => "E07000244",
    "West Suffolk" => "E07000245",
    "Somerset West and Taunton" => "E07000246",
    "Bolton" => "E08000001",
    "Bury" => "E08000002",
    "Manchester" => "E08000003",
    "Oldham" => "E08000004",
    "Rochdale" => "E08000005",
    "Salford" => "E08000006",
    "Stockport" => "E08000007",
    "Tameside" => "E08000008",
    "Trafford" => "E08000009",
    "Wigan" => "E08000010",
    "Knowsley" => "E08000011",
    "Liverpool" => "E08000012",
    "St. Helens" => "E08000013",
    "Sefton" => "E08000014",
    "Wirral" => "E08000015",
    "Barnsley" => "E08000016",
    "Doncaster" => "E08000017",
    "Rotherham" => "E08000018",
    "Sheffield" => "E08000019",
    "Newcastle upon Tyne" => "E08000021",
    "North Tyneside" => "E08000022",
    "South Tyneside" => "E08000023",
    "Sunderland" => "E08000024",
    "Birmingham" => "E08000025",
    "Coventry" => "E08000026",
    "Dudley" => "E08000027",
    "Sandwell" => "E08000028",
    "Solihull" => "E08000029",
    "Walsall" => "E08000030",
    "Dorset" => "E06000059",
    "Wolverhampton" => "E08000031",
    "Falkirk" => "S12000014",
    "Highland" => "S12000017",
    "Inverclyde" => "S12000018",
    "Midlothian" => "S12000019",
    "Moray" => "S12000020",
    "North Ayrshire" => "S12000021",
    "Orkney Islands" => "S12000023",
    "Scottish Borders" => "S12000026",
    "Shetland Islands" => "S12000027",
    "South Ayrshire" => "S12000028",
    "South Lanarkshire" => "S12000029",
    "Stirling" => "S12000030",
    "Aberdeen City" => "S12000033",
    "Aberdeenshire" => "S12000034",
    "Argyll and Bute" => "S12000035",
    "City of Edinburgh" => "S12000036",
    "Renfrewshire" => "S12000038",
    "West Dunbartonshire" => "S12000039",
    "West Lothian" => "S12000040",
    "Angus" => "S12000041",
    "Dundee City" => "S12000042",
    "East Dunbartonshire" => "S12000045",
    "Buckinghamshire" => "E06000060",
    "Fife" => "S12000047",
    "Cambridge" => "E07000008",
    "Perth and Kinross" => "S12000048",
    "East Cambridgeshire" => "E07000009",
    "Glasgow City" => "S12000049",
    "Fenland" => "E07000010",
    "North Lanarkshire" => "S12000050",
    "Huntingdonshire" => "E07000011",
    "Isle of Anglesey" => "W06000001",
    "South Cambridgeshire" => "E07000012",
    "Gwynedd" => "W06000002",
    "Allerdale" => "E07000026",
    "Conwy" => "W06000003",
    "Barrow-in-Furness" => "E07000027",
    "Denbighshire" => "W06000004",
    "Carlisle" => "E07000028",
    "Flintshire" => "W06000005",
    "Copeland" => "E07000029",
    "Wrexham" => "W06000006",
    "Eden" => "E07000030",
    "Ceredigion" => "W06000008",
    "South Lakeland" => "E07000031",
    "Pembrokeshire" => "W06000009",
    "Amber Valley" => "E07000032",
    "Carmarthenshire" => "W06000010",
    "Bolsover" => "E07000033",
    "Swansea" => "W06000011",
    "Chesterfield" => "E07000034",
    "Neath Port Talbot" => "W06000012",
    "Derbyshire Dales" => "E07000035",
    "Bridgend" => "W06000013",
    "Erewash" => "E07000036",
    "Vale of Glamorgan" => "W06000014",
    "High Peak" => "E07000037",
    "Cardiff" => "W06000015",
    "North East Derbyshire" => "E07000038",
    "Rhondda Cynon Taf" => "W06000016",
    "South Derbyshire" => "E07000039",
    "Caerphilly" => "W06000018",
    "East Devon" => "E07000040",
    "Blaenau Gwent" => "W06000019",
    "Exeter" => "E07000041",
    "Torfaen" => "W06000020",
    "Mid Devon" => "E07000042",
    "Monmouthshire" => "W06000021",
    "North Devon" => "E07000043",
    "Newport" => "W06000022",
    "South Hams" => "E07000044",
    "Powys" => "W06000023",
    "Teignbridge" => "E07000045",
    "Merthyr Tydfil" => "W06000024",
    "Torridge" => "E07000046",
    "West Devon" => "E07000047",
    "Eastbourne" => "E07000061",
    "Hastings" => "E07000062",
    "Lewes" => "E07000063",
    "Rother" => "E07000064",
    "Wealden" => "E07000065",
    "Basildon" => "E07000066",
    "Braintree" => "E07000067",
    "Brentwood" => "E07000068",
    "Castle Point" => "E07000069",
    "Chelmsford" => "E07000070",
    "Colchester" => "E07000071",
    "Epping Forest" => "E07000072",
    "Harlow" => "E07000073",
    "Maldon" => "E07000074",
    "Rochford" => "E07000075",
    "Tendring" => "E07000076",
    "Uttlesford" => "E07000077",
    "Cheltenham" => "E07000078",
    "Cotswold" => "E07000079",
    "Forest of Dean" => "E07000080",
    "Gloucester" => "E07000081",
    "Stroud" => "E07000082",
    "Tewkesbury" => "E07000083",
    "Basingstoke and Deane" => "E07000084",
    "East Hampshire" => "E07000085",
    "King’s Lynn and West Norfolk" => "E07000146",
    "Eastleigh" => "E07000086",
    "North Norfolk" => "E07000147",
    "Norwich" => "E07000148",
    "South Norfolk" => "E07000149",
    "Corby" => "E07000150",
    "Daventry" => "E07000151",
    "East Northamptonshire" => "E07000152",
    "Kettering" => "E07000153",
    "Northampton" => "E07000154",
    "South Northamptonshire" => "E07000155",
    "Wellingborough" => "E07000156",
    "Craven" => "E07000163",
    "Hambleton" => "E07000164",
    "Harrogate" => "E07000165",
    "Richmondshire" => "E07000166",
    "Ryedale" => "E07000167",
    "Scarborough" => "E07000168",
    "Selby" => "E07000169",
    "Ashfield" => "E07000170",
    "Bassetlaw" => "E07000171",
    "Broxtowe" => "E07000172",
    "Gedling" => "E07000173",
    "Mansfield" => "E07000174",
    "Newark and Sherwood" => "E07000175",
    "Rushcliffe" => "E07000176",
    "Cherwell" => "E07000177",
    "Oxford" => "E07000178",
    "South Oxfordshire" => "E07000179",
    "Vale of White Horse" => "E07000180",
    "West Oxfordshire" => "E07000181",
    "Mendip" => "E07000187",
    "Sedgemoor" => "E07000188",
    "South Somerset" => "E07000189",
    "Cannock Chase" => "E07000192",
    "East Staffordshire" => "E07000193",
    "Lichfield" => "E07000194",
    "Newcastle-under-Lyme" => "E07000195",
    "South Staffordshire" => "E07000196",
    "Stafford" => "E07000197",
    "Staffordshire Moorlands" => "E07000198",
    "Tamworth" => "E07000199",
    "Babergh" => "E07000200",
    "Ipswich" => "E07000202",
    "Mid Suffolk" => "E07000203",
    "Elmbridge" => "E07000207",
    "Epsom and Ewell" => "E07000208",
    "Guildford" => "E07000209",
    "Mole Valley" => "E07000210",
    "Reigate and Banstead" => "E07000211",
    "Runnymede" => "E07000212",
    "Spelthorne" => "E07000213",
    "Surrey Heath" => "E07000214",
    "Tandridge" => "E07000215",
    "Waverley" => "E07000216",
    "Woking" => "E07000217",
    "Fareham" => "E07000087",
    "Gosport" => "E07000088",
    "Hart" => "E07000089",
    "Havant" => "E07000090",
    "New Forest" => "E07000091",
    "Rushmoor" => "E07000092",
    "Test Valley" => "E07000093",
    "Winchester" => "E07000094",
    "Broxbourne" => "E07000095",
    "Dacorum" => "E07000096",
    "Hertsmere" => "E07000098",
    "North Hertfordshire" => "E07000099",
    "Three Rivers" => "E07000102",
    "Watford" => "E07000103",
    "Ashford" => "E07000105",
    "Canterbury" => "E07000106",
    "Dartford" => "E07000107",
    "Dover" => "E07000108",
    "Gravesham" => "E07000109",
    "Maidstone" => "E07000110",
    "Sevenoaks" => "E07000111",
    "Folkestone and Hythe" => "E07000112",
    "Swale" => "E07000113",
    "Thanet" => "E07000114",
    "Tonbridge and Malling" => "E07000115",
    "Tunbridge Wells" => "E07000116",
    "Burnley" => "E07000117",
    "Chorley" => "E07000118",
    "Fylde" => "E07000119",
    "Hyndburn" => "E07000120",
    "Lancaster" => "E07000121",
    "Pendle" => "E07000122",
    "Preston" => "E07000123",
    "Ribble Valley" => "E07000124",
    "Rossendale" => "E07000125",
    "South Ribble" => "E07000126",
    "West Lancashire" => "E07000127",
    "Wyre" => "E07000128",
    "Blaby" => "E07000129",
    "Charnwood" => "E07000130",
    "Harborough" => "E07000131",
    "Hinckley and Bosworth" => "E07000132",
    "Melton" => "E07000133",
    "North West Leicestershire" => "E07000134",
    "Oadby and Wigston" => "E07000135",
    "Boston" => "E07000136",
    "East Lindsey" => "E07000137",
    "Lincoln" => "E07000138",
    "North Kesteven" => "E07000139",
    "South Holland" => "E07000140",
    "South Kesteven" => "E07000141",
    "West Lindsey" => "E07000142",
    "Breckland" => "E07000143",
    "Broadland" => "E07000144",
    "Great Yarmouth" => "E07000145",
    "Bradford" => "E08000032",
    "Calderdale" => "E08000033",
    "Kirklees" => "E08000034",
    "Leeds" => "E08000035",
    "Wakefield" => "E08000036",
    "Gateshead" => "E08000037",
    "City of London" => "E09000001",
    "Barking and Dagenham" => "E09000002",
    "Barnet" => "E09000003",
    "Bexley" => "E09000004",
    "Brent" => "E09000005",
    "Bromley" => "E09000006",
    "Camden" => "E09000007",
    "Croydon" => "E09000008",
    "Ealing" => "E09000009",
    "Enfield" => "E09000010",
    "Greenwich" => "E09000011",
    "Hackney" => "E09000012",
    "Hammersmith and Fulham" => "E09000013",
    "Haringey" => "E09000014",
    "Harrow" => "E09000015",
    "Havering" => "E09000016",
    "Hillingdon" => "E09000017",
    "Hounslow" => "E09000018",
    "Islington" => "E09000019",
    "Kensington and Chelsea" => "E09000020",
    "Kingston upon Thames" => "E09000021",
    "Lambeth" => "E09000022",
    "Lewisham" => "E09000023",
    "Merton" => "E09000024",
    "Newham" => "E09000025",
    "Redbridge" => "E09000026",
    "Richmond upon Thames" => "E09000027",
    "Southwark" => "E09000028",
    "Sutton" => "E09000029",
    "Tower Hamlets" => "E09000030",
    "Waltham Forest" => "E09000031",
    "Wandsworth" => "E09000032",
    "Westminster" => "E09000033",
    "Antrim and Newtownabbey" => "N09000001",
    "Armagh City, Banbridge and Craigavon" => "N09000002",
    "Belfast" => "N09000003",
    "Causeway Coast and Glens" => "N09000004",
    "Derry City and Strabane" => "N09000005",
    "Fermanagh and Omagh" => "N09000006",
    "Lisburn and Castlereagh" => "N09000007",
    "Mid and East Antrim" => "N09000008",
    "Mid Ulster" => "N09000009",
    "Newry, Mourne and Down" => "N09000010",
    "Ards and North Down" => "N09000011",
    "Clackmannanshire" => "S12000005",
    "Dumfries and Galloway" => "S12000006",
    "East Ayrshire" => "S12000008",
    "East Lothian" => "S12000010",
    "East Renfrewshire" => "S12000011",
  }.freeze

  ARMED_FORCES = {
    "A current or former regular in the UK Armed Forces (exc. National Service)" => 1,
    "No" => 2,
    "Tenant prefers not to say" => 3,
    "A current or former reserve in the UK Armed Forces (exc. National Service)" => 4,
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
end
