# Country → State → City Selection Flow

## Overview

The Country, State, and City fields in `ProfileFragment` use a **cascading dropdown system** driven entirely by **local JSON files** (`res/raw/`). No network call is made for location data. All three fields use `AutoCompleteTextView` with dropdown lists.

---

## Data Sources

| File | Location | Structure |
|------|----------|-----------|
| `countries.json` | `res/raw/countries.json` | JSON Array — `[{ "name": "India", "code": "IN" }, ...]` |
| `states_cities.json` | `res/raw/states_cities.json` | JSON Object — `{ "countryCode": { "StateName": ["City1", "City2", ...] } }` |

Both files are loaded **once on fragment load** inside `setupCountryStateCityDropdowns()` → `loadCountriesData()` + `loadStatesCitiesData()`.

---

## Countries Available (`countries.json`)

10 countries total:

| Country Name | Code |
|-------------|------|
| India | IN |
| United States | US |
| United Kingdom | UK |
| Canada | CA |
| Australia | AU |
| Germany | DE |
| France | FR |
| Japan | JP |
| China | CN |
| Brazil | BR |

> **Note:** Only `IN`, `US`, `UK` have states and cities in `states_cities.json`. `CA`, `AU`, `DE`, `FR`, `JP`, `CN`, `BR` have no state/city data — selecting them shows Toast `"No states available for selected country"`.

---

## States & Cities Available (`states_cities.json`)

### 🇮🇳 India (`IN`) — 32 States / UTs

| State / UT | Cities (10 each) |
|------------|-----------------|
| Andhra Pradesh | Visakhapatnam, Vijayawada, Guntur, Nellore, Kurnool, Rajahmundry, Tirupati, Kadapa, Anantapur, Kakinada |
| Arunachal Pradesh | Itanagar, Naharlagun, Pasighat, Namsai, Tawang, Bomdila, Ziro, Tezu, Changlang, Along |
| Assam | Guwahati, Silchar, Dibrugarh, Jorhat, Nagaon, Tinsukia, Tezpur, Bongaigaon, Karimganj, Dhubri |
| Bihar | Patna, Gaya, Bhagalpur, Muzaffarpur, Darbhanga, Purnia, Arrah, Bihar Sharif, Katihar, Munger |
| Chhattisgarh | Raipur, Bhilai, Bilaspur, Korba, Durg, Rajnandgaon, Jagdalpur, Raigarh, Ambikapur, Mahasamund |
| Goa | Panaji, Margao, Vasco da Gama, Mapusa, Ponda, Bicholim, Curchorem, Sanquelim, Cuncolim, Quepem |
| Gujarat | Ahmedabad, Surat, Vadodara, Rajkot, Bhavnagar, Jamnagar, Junagadh, Gandhinagar, Anand, Nadiad |
| Haryana | Faridabad, Gurgaon, Panipat, Ambala, Yamunanagar, Rohtak, Hisar, Karnal, Sonipat, Panchkula |
| Himachal Pradesh | Shimla, Dharamshala, Solan, Mandi, Palampur, Kullu, Hamirpur, Una, Bilaspur, Chamba |
| Jharkhand | Ranchi, Jamshedpur, Dhanbad, Bokaro, Deoghar, Hazaribagh, Giridih, Ramgarh, Medininagar, Chirkunda |
| Karnataka | Bengaluru, Mysuru, Mangaluru, Hubballi, Belagavi, Kalaburagi, Davangere, Ballari, Vijayapura, Shivamogga |
| Kerala | Thiruvananthapuram, Kochi, Kozhikode, Thrissur, Kollam, Palakkad, Alappuzha, Malappuram, Kannur, Kottayam |
| Madhya Pradesh | Indore, Bhopal, Jabalpur, Gwalior, Ujjain, Sagar, Dewas, Satna, Ratlam, Rewa |
| Maharashtra | Mumbai, Pune, Nagpur, Thane, Nashik, Aurangabad, Solapur, Kolhapur, Amravati, Navi Mumbai |
| Manipur | Imphal, Thoubal, Bishnupur, Churachandpur, Kakching, Ukhrul, Senapati, Tamenglong, Chandel, Jiribam |
| Meghalaya | Shillong, Tura, Nongstoin, Jowai, Baghmara, Williamnagar, Nongpoh, Mairang, Resubelpara, Khliehriat |
| Mizoram | Aizawl, Lunglei, Champhai, Serchhip, Kolasib, Lawngtlai, Saiha, Mamit, Khawzawl, Saitual |
| Nagaland | Kohima, Dimapur, Mokokchung, Tuensang, Wokha, Zunheboto, Phek, Mon, Longleng, Kiphire |
| Odisha | Bhubaneswar, Cuttack, Rourkela, Berhampur, Sambalpur, Puri, Balasore, Bhadrak, Baripada, Jharsuguda |
| Punjab | Ludhiana, Amritsar, Jalandhar, Patiala, Bathinda, Mohali, Hoshiarpur, Batala, Pathankot, Moga |
| Rajasthan | Jaipur, Jodhpur, Kota, Bikaner, Udaipur, Ajmer, Bhilwara, Alwar, Bharatpur, Sikar |
| Sikkim | Gangtok, Namchi, Gyalshing, Mangan, Jorethang, Rangpo, Singtam, Pakyong, Ravangla, Rongli |
| Tamil Nadu | Chennai, Coimbatore, Madurai, Tiruchirappalli, Salem, Tirunelveli, Tiruppur, Erode, Vellore, Thoothukudi |
| Telangana | Hyderabad, Warangal, Nizamabad, Khammam, Karimnagar, Ramagundam, Mahbubnagar, Nalgonda, Adilabad, Suryapet |
| Tripura | Agartala, Udaipur, Dharmanagar, Kailasahar, Belonia, Khowai, Ambassa, Teliamura, Santirbazar, Kumarghat |
| Uttar Pradesh | Lucknow, Kanpur, Ghaziabad, Agra, Varanasi, Meerut, Allahabad, Bareilly, Aligarh, Moradabad |
| Uttarakhand | Dehradun, Haridwar, Roorkee, Haldwani, Rudrapur, Kashipur, Rishikesh, Ramnagar, Pithoragarh, Nainital |
| West Bengal | Kolkata, Howrah, Durgapur, Asansol, Siliguri, Bardhaman, Malda, Baharampur, Habra, Kharagpur |
| Andaman and Nicobar Islands | Port Blair, Diglipur, Rangat, Mayabunder, Car Nicobar, Hut Bay, Nancowry, Campbell Bay, Long Island, Neil Island |
| Chandigarh | Chandigarh |
| Dadra and Nagar Haveli and Daman and Diu | Daman, Diu, Silvassa |
| Delhi | New Delhi, South Delhi, North Delhi, East Delhi, West Delhi, Central Delhi, North East Delhi, North West Delhi, South East Delhi, South West Delhi |
| Jammu and Kashmir | Srinagar, Jammu, Anantnag, Baramulla, Sopore, Kathua, Udhampur, Pulwama, Rajouri, Kupwara |
| Ladakh | Leh, Kargil, Nubra, Zanskar, Drass, Nyoma, Khalsi, Khaltse, Saspol, Chuchot |
| Lakshadweep | Kavaratti, Agatti, Amini, Andrott, Kalpeni, Kadmat, Kiltan, Chetlat, Bitra, Minicoy |
| Puducherry | Puducherry, Karaikal, Mahe, Yanam |

---

### 🇺🇸 United States (`US`) — 4 States

| State | Cities |
|-------|--------|
| California | Los Angeles, San Francisco, San Diego, San Jose, Sacramento |
| Texas | Houston, Dallas, Austin, San Antonio, Fort Worth |
| New York | New York City, Buffalo, Rochester, Albany, Syracuse |
| Florida | Miami, Orlando, Tampa, Jacksonville, Fort Lauderdale |

---

### 🇬🇧 United Kingdom (`UK`) — 4 Regions

| Region | Cities |
|--------|--------|
| England | London, Manchester, Birmingham, Liverpool, Leeds |
| Scotland | Edinburgh, Glasgow, Aberdeen, Dundee, Inverness |
| Wales | Cardiff, Swansea, Newport, Wrexham, Barry |
| Northern Ireland | Belfast, Derry, Lisburn, Newry, Bangor |

---

### ❌ No State/City Data (Before Update)

These countries previously had no data. All have been added to `LocationData.swift`:

---

### 🇨🇦 Canada (`CA`) — 10 Provinces

| Province | Cities (10 each) |
|----------|-----------------|
| Ontario | Toronto, Ottawa, Mississauga, Brampton, Hamilton, London, Markham, Vaughan, Kitchener, Windsor |
| Quebec | Montreal, Quebec City, Laval, Gatineau, Longueuil, Sherbrooke, Saguenay, Levis, Trois-Rivieres, Terrebonne |
| British Columbia | Vancouver, Surrey, Burnaby, Richmond, Kelowna, Abbotsford, Coquitlam, Langley, Saanich, Delta |
| Alberta | Calgary, Edmonton, Red Deer, Lethbridge, St. Albert, Medicine Hat, Grande Prairie, Airdrie, Spruce Grove, Leduc |
| Manitoba | Winnipeg, Brandon, Steinbach, Thompson, Portage la Prairie, Winkler, Selkirk, Morden, Dauphin, The Pas |
| Saskatchewan | Saskatoon, Regina, Prince Albert, Moose Jaw, Swift Current, Yorkton, North Battleford, Estevan, Weyburn, Lloydminster |
| Nova Scotia | Halifax, Dartmouth, Sydney, Truro, New Glasgow, Glace Bay, Waterville, Amherst, Bridgewater, Yarmouth |
| New Brunswick | Moncton, Saint John, Fredericton, Miramichi, Dieppe, Quispamsis, Riverview, Bathurst, Edmundston, Campbellton |
| Newfoundland and Labrador | St. John's, Corner Brook, Mount Pearl, Conception Bay South, Grand Falls-Windsor, Gander, Paradise, Happy Valley-Goose Bay, Labrador City, Stephenville |
| Prince Edward Island | Charlottetown, Summerside, Stratford, Cornwall, Montague, Kensington, Souris, Alberton, O'Leary, Georgetown |

---

### 🇦🇺 Australia (`AU`) — 8 States / Territories

| State / Territory | Cities (10 each) |
|------------------|-----------------|
| New South Wales | Sydney, Newcastle, Wollongong, Central Coast, Maitland, Albury, Wagga Wagga, Port Macquarie, Tamworth, Orange |
| Victoria | Melbourne, Geelong, Ballarat, Bendigo, Shepparton, Mildura, Warrnambool, Wodonga, Sunbury, Traralgon |
| Queensland | Brisbane, Gold Coast, Sunshine Coast, Townsville, Cairns, Toowoomba, Mackay, Rockhampton, Bundaberg, Hervey Bay |
| Western Australia | Perth, Fremantle, Bunbury, Geraldton, Mandurah, Joondalup, Rockingham, Kalgoorlie, Albany, Broome |
| South Australia | Adelaide, Mount Gambier, Whyalla, Murray Bridge, Port Augusta, Port Lincoln, Victor Harbor, Port Pirie, Gawler, Salisbury |
| Tasmania | Hobart, Launceston, Devonport, Burnie, Glenorchy, Clarence, Sorell, New Norfolk, George Town, Ulverstone |
| Australian Capital Territory | Canberra, Belconnen, Tuggeranong, Gungahlin, Woden, Weston Creek, Molonglo Valley, Fyshwick, Queanbeyan, Hall |
| Northern Territory | Darwin, Alice Springs, Palmerston, Katherine, Nhulunbuy, Tennant Creek, Jabiru, Yulara, Borroloola, Pine Creek |

---

### 🇩🇪 Germany (`DE`) — 8 States

| State | Cities (10 each) |
|-------|-----------------|
| Bavaria | Munich, Nuremberg, Augsburg, Würzburg, Regensburg, Ingolstadt, Fürth, Erlangen, Bayreuth, Bamberg |
| North Rhine-Westphalia | Cologne, Düsseldorf, Dortmund, Essen, Duisburg, Bochum, Wuppertal, Bielefeld, Bonn, Münster |
| Baden-Württemberg | Stuttgart, Mannheim, Karlsruhe, Freiburg, Heidelberg, Heilbronn, Ulm, Pforzheim, Reutlingen, Tübingen |
| Hesse | Frankfurt, Wiesbaden, Kassel, Darmstadt, Hanau, Offenbach, Marburg, Giessen, Fulda, Wetzlar |
| Lower Saxony | Hanover, Braunschweig, Osnabrück, Oldenburg, Göttingen, Wolfsburg, Salzgitter, Hildesheim, Delmenhorst, Wilhelmshaven |
| Berlin | Berlin, Mitte, Charlottenburg, Prenzlauer Berg, Kreuzberg, Friedrichshain, Schöneberg, Tempelhof, Neukölln, Pankow |
| Hamburg | Hamburg, Altona, Eimsbüttel, Wandsbek, Bergedorf, Harburg, Hamburg-Nord, Hamburg-Mitte, Rahlstedt, Billstedt |
| Saxony | Dresden, Leipzig, Chemnitz, Zwickau, Plauen, Görlitz, Freiberg, Bautzen, Pirna, Meissen |

---

### 🇫🇷 France (`FR`) — 8 Regions

| Region | Cities (10 each) |
|--------|-----------------|
| Île-de-France | Paris, Versailles, Boulogne-Billancourt, Saint-Denis, Montreuil, Argenteuil, Créteil, Nanterre, Vitry-sur-Seine, Saint-Maur-des-Fossés |
| Auvergne-Rhône-Alpes | Lyon, Grenoble, Clermont-Ferrand, Saint-Étienne, Annecy, Villeurbanne, Chambéry, Valence, Annemasse, Roanne |
| Nouvelle-Aquitaine | Bordeaux, Limoges, Poitiers, Pau, Bayonne, Brive-la-Gaillarde, Périgueux, Niort, Angoulême, La Rochelle |
| Occitanie | Toulouse, Montpellier, Nîmes, Perpignan, Béziers, Narbonne, Albi, Carcassonne, Rodez, Montauban |
| Provence-Alpes-Côte d'Azur | Marseille, Nice, Toulon, Aix-en-Provence, Avignon, Cannes, Antibes, La Seyne-sur-Mer, Grasse, Fréjus |
| Normandie | Rouen, Caen, Le Havre, Cherbourg, Évreux, Alençon, Saint-Lô, Lisieux, Dieppe, Coutances |
| Grand Est | Strasbourg, Reims, Metz, Nancy, Mulhouse, Colmar, Troyes, Chalons-en-Champagne, Épinal, Thionville |
| Pays de la Loire | Nantes, Le Mans, Saint-Nazaire, Angers, La Roche-sur-Yon, Laval, Cholet, Saint-Herblain, Rezé, Saumur |

---

### 🇯🇵 Japan (`JP`) — 8 Prefectures

| Prefecture | Cities (10 each) |
|-----------|-----------------|
| Tokyo | Tokyo, Shibuya, Shinjuku, Hachioji, Tachikawa, Musashino, Mitaka, Fuchu, Machida, Koganei |
| Osaka | Osaka, Sakai, Higashiosaka, Hirakata, Toyonaka, Suita, Takatsuki, Yao, Neyagawa, Ibaraki |
| Kanagawa | Yokohama, Kawasaki, Sagamihara, Fujisawa, Yokosuka, Chigasaki, Hiratsuka, Atsugi, Yamato, Odawara |
| Aichi | Nagoya, Toyota, Okazaki, Ichinomiya, Nagakute, Kasugai, Toyohashi, Anjo, Nishio, Komaki |
| Hokkaido | Sapporo, Asahikawa, Hakodate, Kushiro, Obihiro, Kitami, Otaru, Tomakomai, Wakkanai, Muroran |
| Fukuoka | Fukuoka, Kitakyushu, Kurume, Omuta, Iizuka, Nogata, Munakata, Dazaifu, Kasuga, Onojo |
| Kyoto | Kyoto, Uji, Kameoka, Muko, Nagaokakyo, Maizuru, Fukuchiyama, Ayabe, Miyazu, Joyo |
| Hyogo | Kobe, Himeji, Nishinomiya, Amagasaki, Akashi, Itami, Kakogawa, Takarazuka, Sanda, Ashiya |

---

### 🇨🇳 China (`CN`) — 8 Provinces / Municipalities

| Province | Cities (10 each) |
|---------|-----------------|
| Guangdong | Guangzhou, Shenzhen, Dongguan, Foshan, Zhuhai, Shantou, Zhongshan, Jiangmen, Huizhou, Zhanjiang |
| Zhejiang | Hangzhou, Ningbo, Wenzhou, Shaoxing, Jinhua, Jiaxing, Huzhou, Quzhou, Taizhou, Lishui |
| Jiangsu | Nanjing, Suzhou, Wuxi, Changzhou, Nantong, Xuzhou, Yangzhou, Zhenjiang, Taizhou, Lianyungang |
| Shandong | Jinan, Qingdao, Zibo, Yantai, Weifang, Jining, Taian, Weihai, Linyi, Laiwu |
| Sichuan | Chengdu, Mianyang, Deyang, Luzhou, Nanchong, Leshan, Yibin, Guang'an, Zigong, Panzhihua |
| Beijing | Beijing, Chaoyang, Haidian, Xicheng, Dongcheng, Fengtai, Shijingshan, Mentougou, Fangshan, Tongzhou |
| Shanghai | Shanghai, Huangpu, Xuhui, Changning, Jing'an, Putuo, Hongkou, Yangpu, Baoshan, Minhang |
| Hubei | Wuhan, Huangshi, Yichang, Xiangyang, Jingzhou, Xiaogan, Ezhou, Jingmen, Huanggang, Shiyan |

---

### 🇧🇷 Brazil (`BR`) — 8 States

| State | Cities (10 each) |
|-------|-----------------|
| São Paulo | São Paulo, Guarulhos, Campinas, São Bernardo do Campo, Santo André, Osasco, Ribeirão Preto, Sorocaba, Mauá, São José dos Campos |
| Rio de Janeiro | Rio de Janeiro, São Gonçalo, Duque de Caxias, Nova Iguaçu, Niterói, Belford Roxo, São João de Meriti, Campos dos Goytacazes, Petrópolis, Volta Redonda |
| Minas Gerais | Belo Horizonte, Contagem, Juiz de Fora, Betim, Montes Claros, Uberlândia, Ribeirão das Neves, Uberaba, Governador Valadares, Ipatinga |
| Bahia | Salvador, Feira de Santana, Vitória da Conquista, Camaçari, Juazeiro, Itabuna, Lauro de Freitas, Ilhéus, Jequié, Teixeira de Freitas |
| Paraná | Curitiba, Londrina, Maringá, Ponta Grossa, Cascavel, São José dos Pinhais, Foz do Iguaçu, Colombo, Guarapuava, Paranaguá |
| Rio Grande do Sul | Porto Alegre, Caxias do Sul, Pelotas, Canoas, Santa Maria, Gravataí, Viamão, Novo Hamburgo, São Leopoldo, Rio Grande |
| Pernambuco | Recife, Caruaru, Petrolina, Olinda, Paulista, Jaboatão dos Guararapes, Cabo de Santo Agostinho, Vitória de Santo Antão, Garanhuns, Camaragibe |
| Ceará | Fortaleza, Caucaia, Juazeiro do Norte, Maracanaú, Sobral, Crato, Itapipoca, Maranguape, Iguatu, Quixadá |

---

## UI — View Details

| Field | View Type | View ID | XML Properties |
|-------|-----------|---------|----------------|
| Country | `AutoCompleteTextView` | `etCountry` | `inputType="none"`, `focusable="false"`, `cursorVisible="false"`, `drawableEnd` = dropdown arrow, `completionThreshold="1"` |
| State | `AutoCompleteTextView` | `etState` | Same as country + `android:enabled="false"` (default disabled) |
| City | `AutoCompleteTextView` | `etCity` | Same as state + `android:enabled="false"` (default disabled) |

All three use `@drawable/input_box_background_shadow` background, `padding="15dp"`, `elevation="4dp"`, `marginBottom="20dp"`.

---

## Complete Selection Flow

### Normal (User selects fresh)

```
Fragment loads
    │
    ├── loadCountriesData()
    │       reads R.raw.countries → List<Country(name, code)>
    │
    └── loadStatesCitiesData()
            reads R.raw.states_cities → Map<countryCode, Map<state, List<city>>>

Setup:
    etCountry adapter = ArrayAdapter(countryNames)
    etState.isEnabled  = false
    etCity.isEnabled   = false

User taps etCountry
    └── showDropDown() → list of 10 country names

User picks a country (e.g. "India")
    ├── selectedCountryCode = "IN"
    ├── etCountry.setText("India", false)
    ├── etState.setText("")  + isEnabled = true
    ├── etCity.setText("")   + isEnabled = false
    └── loadStatesForCountry("IN")
            → statesCitiesData["IN"]?.keys → list of 36 state names
            → etState adapter = ArrayAdapter(stateNames)

User taps etState
    └── showDropDown() → list of states for selected country

User picks a state (e.g. "Karnataka")
    ├── etState.setText("Karnataka", false)
    ├── etCity.setText("") + isEnabled = true
    └── loadCitiesForState("IN", "Karnataka")
            → statesCitiesData["IN"]?["Karnataka"] → ["Bengaluru", "Mysuru", ...]
            → etCity adapter = ArrayAdapter(cityNames)

User taps etCity
    └── showDropDown() → list of 10 cities for selected state

User picks a city (e.g. "Bengaluru")
    └── etCity.setText("Bengaluru", false)
```

---

### Pre-fill from API (Existing Profile Data)

```
fetchUserProfileData() returns:
    profileData.country = "India"
    profileData.state   = "Karnataka"
    profileData.city    = "Bengaluru"
        │
        ▼
loadExistingLocationData("India", "Karnataka", "Bengaluru")
        │
        ├── Find country: countriesList.find { it.name == "India" } → code = "IN"
        │       If NOT found → set raw text on all 3 fields, no cascade
        │
        ├── selectedCountryCode = "IN"
        ├── etCountry.setText("India", false)
        │
        ├── loadStatesForCountry("IN") → sets adapter on etState
        ├── etState.isEnabled = true
        ├── etState.setText("Karnataka", false)
        │
        ├── loadCitiesForState("IN", "Karnataka") → sets adapter on etCity
        ├── etCity.isEnabled = true
        └── etCity.setText("Bengaluru", false)

Result: All 3 fields are pre-filled AND enabled for editing
        (user can change country → state resets → city resets)
```

---

## Edge Cases & Behaviour

| Scenario | Behaviour |
|----------|-----------|
| Country with no states in JSON | Toast `"No states available for selected country"` — state stays empty |
| State with no cities in JSON | Toast `"No cities available for selected state"` — city stays empty |
| Country name from API not found in `countries.json` | Raw text set on all 3 fields, no cascade, no enable/disable logic |
| User changes country after pre-fill | State + city reset to empty, city disabled, new state list loaded |
| User changes state after pre-fill | City resets to empty, new city list loaded |
| City field before state is selected | `isEnabled = false` — tap does nothing |
| State field before country is selected | `isEnabled = false` — tap does nothing |

---

## API Send Format

All three values are sent as their **display name strings** — no codes:

| Field | API Key | Example Value |
|-------|---------|--------------|
| Country | `country` | `"India"` |
| State | `state` | `"Karnataka"` |
| City | `city` | `"Bengaluru"` |

Sent as `multipart/form-data` `RequestBody` in `POST patients/{id}`.

---

## iOS Implementation Notes

1. **No network call** — load both JSON files from app bundle at profile screen init
2. **Data model** — `Country(name: String, code: String)`, `statesCitiesData: [String: [String: [String]]]`
3. **Country picker** — `UIPickerView` or `UITableView` in a modal/action sheet — show only `name`, store `code` internally
4. **On country select** — reset + disable state/city, load states for `code`
5. **State picker** — enabled only after country selected, loads from `statesCitiesData[countryCode]?.keys`
6. **On state select** — reset + enable city, load cities for `statesCitiesData[countryCode]?[state]`
7. **City picker** — enabled only after state selected
8. **Pre-fill** — match API country name → find code → cascade enable all three with pre-selected values
9. **Fallback** — if country name not in local JSON → just display raw text, skip cascade
10. **Send to API** — always send full display name (e.g. `"India"`, `"Karnataka"`, `"Bengaluru"`), never the code
11. **Countries with no state data** (CA, AU, DE, FR, JP, CN, BR) → show alert `"No states available"` and keep state/city disabled

