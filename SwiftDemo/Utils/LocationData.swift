import Foundation

struct CountryLocationData {

    // MARK: - Countries
    static let countries: [(name: String, code: String)] = [
        ("India", "IN"),
        ("United States", "US"),
        ("United Kingdom", "UK"),
        ("Canada", "CA"),
        ("Australia", "AU"),
        ("Germany", "DE"),
        ("France", "FR"),
        ("Japan", "JP"),
        ("China", "CN"),
        ("Brazil", "BR")
    ]

    static func countryCode(for name: String) -> String {
        countries.first { $0.name == name }?.code ?? ""
    }

    static func states(for countryCode: String) -> [String] {
        (statesAndCities[countryCode] ?? [:]).keys.sorted()
    }

    static func cities(for countryCode: String, state: String) -> [String] {
        statesAndCities[countryCode]?[state] ?? []
    }

    // MARK: - States & Cities

    static let statesAndCities: [String: [String: [String]]] = [
        "IN": india,
        "US": unitedStates,
        "UK": unitedKingdom,
        "CA": canada,
        "AU": australia,
        "DE": germany,
        "FR": france,
        "JP": japan,
        "CN": china,
        "BR": brazil
    ]

    // MARK: India
    private static let india: [String: [String]] = [
        "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur", "Nellore", "Kurnool", "Rajahmundry", "Tirupati", "Kadapa", "Anantapur", "Kakinada"],
        "Arunachal Pradesh": ["Itanagar", "Naharlagun", "Pasighat", "Namsai", "Tawang", "Bomdila", "Ziro", "Tezu", "Changlang", "Along"],
        "Assam": ["Guwahati", "Silchar", "Dibrugarh", "Jorhat", "Nagaon", "Tinsukia", "Tezpur", "Bongaigaon", "Karimganj", "Dhubri"],
        "Bihar": ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur", "Darbhanga", "Purnia", "Arrah", "Bihar Sharif", "Katihar", "Munger"],
        "Chhattisgarh": ["Raipur", "Bhilai", "Bilaspur", "Korba", "Durg", "Rajnandgaon", "Jagdalpur", "Raigarh", "Ambikapur", "Mahasamund"],
        "Goa": ["Panaji", "Margao", "Vasco da Gama", "Mapusa", "Ponda", "Bicholim", "Curchorem", "Sanquelim", "Cuncolim", "Quepem"],
        "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Junagadh", "Gandhinagar", "Anand", "Nadiad"],
        "Haryana": ["Faridabad", "Gurgaon", "Panipat", "Ambala", "Yamunanagar", "Rohtak", "Hisar", "Karnal", "Sonipat", "Panchkula"],
        "Himachal Pradesh": ["Shimla", "Dharamshala", "Solan", "Mandi", "Palampur", "Kullu", "Hamirpur", "Una", "Bilaspur", "Chamba"],
        "Jharkhand": ["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro", "Deoghar", "Hazaribagh", "Giridih", "Ramgarh", "Medininagar", "Chirkunda"],
        "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi", "Belagavi", "Kalaburagi", "Davangere", "Ballari", "Vijayapura", "Shivamogga"],
        "Kerala": ["Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam", "Palakkad", "Alappuzha", "Malappuram", "Kannur", "Kottayam"],
        "Madhya Pradesh": ["Indore", "Bhopal", "Jabalpur", "Gwalior", "Ujjain", "Sagar", "Dewas", "Satna", "Ratlam", "Rewa"],
        "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Thane", "Nashik", "Aurangabad", "Solapur", "Kolhapur", "Amravati", "Navi Mumbai"],
        "Manipur": ["Imphal", "Thoubal", "Bishnupur", "Churachandpur", "Kakching", "Ukhrul", "Senapati", "Tamenglong", "Chandel", "Jiribam"],
        "Meghalaya": ["Shillong", "Tura", "Nongstoin", "Jowai", "Baghmara", "Williamnagar", "Nongpoh", "Mairang", "Resubelpara", "Khliehriat"],
        "Mizoram": ["Aizawl", "Lunglei", "Champhai", "Serchhip", "Kolasib", "Lawngtlai", "Saiha", "Mamit", "Khawzawl", "Saitual"],
        "Nagaland": ["Kohima", "Dimapur", "Mokokchung", "Tuensang", "Wokha", "Zunheboto", "Phek", "Mon", "Longleng", "Kiphire"],
        "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur", "Sambalpur", "Puri", "Balasore", "Bhadrak", "Baripada", "Jharsuguda"],
        "Punjab": ["Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Bathinda", "Mohali", "Hoshiarpur", "Batala", "Pathankot", "Moga"],
        "Rajasthan": ["Jaipur", "Jodhpur", "Kota", "Bikaner", "Udaipur", "Ajmer", "Bhilwara", "Alwar", "Bharatpur", "Sikar"],
        "Sikkim": ["Gangtok", "Namchi", "Gyalshing", "Mangan", "Jorethang", "Rangpo", "Singtam", "Pakyong", "Ravangla", "Rongli"],
        "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Tiruppur", "Erode", "Vellore", "Thoothukudi"],
        "Telangana": ["Hyderabad", "Warangal", "Nizamabad", "Khammam", "Karimnagar", "Ramagundam", "Mahbubnagar", "Nalgonda", "Adilabad", "Suryapet"],
        "Tripura": ["Agartala", "Udaipur", "Dharmanagar", "Kailasahar", "Belonia", "Khowai", "Ambassa", "Teliamura", "Santirbazar", "Kumarghat"],
        "Uttar Pradesh": ["Lucknow", "Kanpur", "Ghaziabad", "Agra", "Varanasi", "Meerut", "Allahabad", "Bareilly", "Aligarh", "Moradabad"],
        "Uttarakhand": ["Dehradun", "Haridwar", "Roorkee", "Haldwani", "Rudrapur", "Kashipur", "Rishikesh", "Ramnagar", "Pithoragarh", "Nainital"],
        "West Bengal": ["Kolkata", "Howrah", "Durgapur", "Asansol", "Siliguri", "Bardhaman", "Malda", "Baharampur", "Habra", "Kharagpur"],
        "Andaman and Nicobar Islands": ["Port Blair", "Diglipur", "Rangat", "Mayabunder", "Car Nicobar", "Hut Bay", "Nancowry", "Campbell Bay", "Long Island", "Neil Island"],
        "Chandigarh": ["Chandigarh"],
        "Dadra and Nagar Haveli and Daman and Diu": ["Daman", "Diu", "Silvassa"],
        "Delhi": ["New Delhi", "South Delhi", "North Delhi", "East Delhi", "West Delhi", "Central Delhi", "North East Delhi", "North West Delhi", "South East Delhi", "South West Delhi"],
        "Jammu and Kashmir": ["Srinagar", "Jammu", "Anantnag", "Baramulla", "Sopore", "Kathua", "Udhampur", "Pulwama", "Rajouri", "Kupwara"],
        "Ladakh": ["Leh", "Kargil", "Nubra", "Zanskar", "Drass", "Nyoma", "Khalsi", "Khaltse", "Saspol", "Chuchot"],
        "Lakshadweep": ["Kavaratti", "Agatti", "Amini", "Andrott", "Kalpeni", "Kadmat", "Kiltan", "Chetlat", "Bitra", "Minicoy"],
        "Puducherry": ["Puducherry", "Karaikal", "Mahe", "Yanam"]
    ]

    // MARK: United States
    private static let unitedStates: [String: [String]] = [
        "California": ["Los Angeles", "San Francisco", "San Diego", "San Jose", "Sacramento", "Fresno", "Long Beach", "Oakland", "Bakersfield", "Anaheim"],
        "Texas": ["Houston", "Dallas", "Austin", "San Antonio", "Fort Worth", "El Paso", "Arlington", "Corpus Christi", "Plano", "Lubbock"],
        "New York": ["New York City", "Buffalo", "Rochester", "Albany", "Syracuse", "Yonkers", "New Rochelle", "Mount Vernon", "Schenectady", "Utica"],
        "Florida": ["Miami", "Orlando", "Tampa", "Jacksonville", "Fort Lauderdale", "Tallahassee", "St. Petersburg", "Hialeah", "Port St. Lucie", "Cape Coral"],
        "Illinois": ["Chicago", "Aurora", "Naperville", "Joliet", "Rockford", "Springfield", "Elgin", "Peoria", "Champaign", "Waukegan"],
        "Pennsylvania": ["Philadelphia", "Pittsburgh", "Allentown", "Erie", "Reading", "Scranton", "Bethlehem", "Lancaster", "Harrisburg", "Altoona"],
        "Ohio": ["Columbus", "Cleveland", "Cincinnati", "Toledo", "Akron", "Dayton", "Parma", "Canton", "Youngstown", "Lorain"],
        "Georgia": ["Atlanta", "Augusta", "Columbus", "Macon", "Savannah", "Athens", "Sandy Springs", "Roswell", "Albany", "Johns Creek"]
    ]

    // MARK: United Kingdom
    private static let unitedKingdom: [String: [String]] = [
        "England": ["London", "Manchester", "Birmingham", "Liverpool", "Leeds", "Sheffield", "Bristol", "Newcastle", "Leicester", "Nottingham"],
        "Scotland": ["Edinburgh", "Glasgow", "Aberdeen", "Dundee", "Inverness", "Stirling", "Perth", "Paisley", "East Kilbride", "Livingston"],
        "Wales": ["Cardiff", "Swansea", "Newport", "Wrexham", "Barry", "Neath", "Rhondda", "Bridgend", "Llanelli", "Merthyr Tydfil"],
        "Northern Ireland": ["Belfast", "Derry", "Lisburn", "Newry", "Bangor", "Armagh", "Ballymena", "Craigavon", "Newtownabbey", "Carrickfergus"]
    ]

    // MARK: Canada
    private static let canada: [String: [String]] = [
        "Ontario": ["Toronto", "Ottawa", "Mississauga", "Brampton", "Hamilton", "London", "Markham", "Vaughan", "Kitchener", "Windsor"],
        "Quebec": ["Montreal", "Quebec City", "Laval", "Gatineau", "Longueuil", "Sherbrooke", "Saguenay", "Levis", "Trois-Rivieres", "Terrebonne"],
        "British Columbia": ["Vancouver", "Surrey", "Burnaby", "Richmond", "Kelowna", "Abbotsford", "Coquitlam", "Langley", "Saanich", "Delta"],
        "Alberta": ["Calgary", "Edmonton", "Red Deer", "Lethbridge", "St. Albert", "Medicine Hat", "Grande Prairie", "Airdrie", "Spruce Grove", "Leduc"],
        "Manitoba": ["Winnipeg", "Brandon", "Steinbach", "Thompson", "Portage la Prairie", "Winkler", "Selkirk", "Morden", "Dauphin", "The Pas"],
        "Saskatchewan": ["Saskatoon", "Regina", "Prince Albert", "Moose Jaw", "Swift Current", "Yorkton", "North Battleford", "Estevan", "Weyburn", "Lloydminster"],
        "Nova Scotia": ["Halifax", "Dartmouth", "Sydney", "Truro", "New Glasgow", "Glace Bay", "Waterville", "Amherst", "Bridgewater", "Yarmouth"],
        "New Brunswick": ["Moncton", "Saint John", "Fredericton", "Miramichi", "Dieppe", "Quispamsis", "Riverview", "Bathurst", "Edmundston", "Campbellton"],
        "Newfoundland and Labrador": ["St. John's", "Corner Brook", "Mount Pearl", "Conception Bay South", "Grand Falls-Windsor", "Gander", "Paradise", "Happy Valley-Goose Bay", "Labrador City", "Stephenville"],
        "Prince Edward Island": ["Charlottetown", "Summerside", "Stratford", "Cornwall", "Montague", "Kensington", "Souris", "Alberton", "O'Leary", "Georgetown"]
    ]

    // MARK: Australia
    private static let australia: [String: [String]] = [
        "New South Wales": ["Sydney", "Newcastle", "Wollongong", "Central Coast", "Maitland", "Albury", "Wagga Wagga", "Port Macquarie", "Tamworth", "Orange"],
        "Victoria": ["Melbourne", "Geelong", "Ballarat", "Bendigo", "Shepparton", "Mildura", "Warrnambool", "Wodonga", "Sunbury", "Traralgon"],
        "Queensland": ["Brisbane", "Gold Coast", "Sunshine Coast", "Townsville", "Cairns", "Toowoomba", "Mackay", "Rockhampton", "Bundaberg", "Hervey Bay"],
        "Western Australia": ["Perth", "Fremantle", "Bunbury", "Geraldton", "Mandurah", "Joondalup", "Rockingham", "Kalgoorlie", "Albany", "Broome"],
        "South Australia": ["Adelaide", "Mount Gambier", "Whyalla", "Murray Bridge", "Port Augusta", "Port Lincoln", "Victor Harbor", "Port Pirie", "Gawler", "Salisbury"],
        "Tasmania": ["Hobart", "Launceston", "Devonport", "Burnie", "Glenorchy", "Clarence", "Sorell", "New Norfolk", "George Town", "Ulverstone"],
        "Australian Capital Territory": ["Canberra", "Belconnen", "Tuggeranong", "Gungahlin", "Woden", "Weston Creek", "Molonglo Valley", "Fyshwick", "Queanbeyan", "Hall"],
        "Northern Territory": ["Darwin", "Alice Springs", "Palmerston", "Katherine", "Nhulunbuy", "Tennant Creek", "Jabiru", "Yulara", "Borroloola", "Pine Creek"]
    ]

    // MARK: Germany
    private static let germany: [String: [String]] = [
        "Bavaria": ["Munich", "Nuremberg", "Augsburg", "Würzburg", "Regensburg", "Ingolstadt", "Fürth", "Erlangen", "Bayreuth", "Bamberg"],
        "North Rhine-Westphalia": ["Cologne", "Düsseldorf", "Dortmund", "Essen", "Duisburg", "Bochum", "Wuppertal", "Bielefeld", "Bonn", "Münster"],
        "Baden-Württemberg": ["Stuttgart", "Mannheim", "Karlsruhe", "Freiburg", "Heidelberg", "Heilbronn", "Ulm", "Pforzheim", "Reutlingen", "Tübingen"],
        "Hesse": ["Frankfurt", "Wiesbaden", "Kassel", "Darmstadt", "Hanau", "Offenbach", "Marburg", "Giessen", "Fulda", "Wetzlar"],
        "Lower Saxony": ["Hanover", "Braunschweig", "Osnabrück", "Oldenburg", "Göttingen", "Wolfsburg", "Salzgitter", "Hildesheim", "Delmenhorst", "Wilhelmshaven"],
        "Berlin": ["Berlin", "Mitte", "Charlottenburg", "Prenzlauer Berg", "Kreuzberg", "Friedrichshain", "Schöneberg", "Tempelhof", "Neukölln", "Pankow"],
        "Hamburg": ["Hamburg", "Altona", "Eimsbüttel", "Wandsbek", "Bergedorf", "Harburg", "Hamburg-Nord", "Hamburg-Mitte", "Rahlstedt", "Billstedt"],
        "Saxony": ["Dresden", "Leipzig", "Chemnitz", "Zwickau", "Plauen", "Görlitz", "Freiberg", "Bautzen", "Pirna", "Meissen"]
    ]

    // MARK: France
    private static let france: [String: [String]] = [
        "Île-de-France": ["Paris", "Versailles", "Boulogne-Billancourt", "Saint-Denis", "Montreuil", "Argenteuil", "Créteil", "Nanterre", "Vitry-sur-Seine", "Saint-Maur-des-Fossés"],
        "Auvergne-Rhône-Alpes": ["Lyon", "Grenoble", "Clermont-Ferrand", "Saint-Étienne", "Annecy", "Villeurbanne", "Chambéry", "Valence", "Annemasse", "Roanne"],
        "Nouvelle-Aquitaine": ["Bordeaux", "Limoges", "Poitiers", "Pau", "Bayonne", "Brive-la-Gaillarde", "Périgueux", "Niort", "Angoulême", "La Rochelle"],
        "Occitanie": ["Toulouse", "Montpellier", "Nîmes", "Perpignan", "Béziers", "Narbonne", "Albi", "Carcassonne", "Rodez", "Montauban"],
        "Provence-Alpes-Côte d'Azur": ["Marseille", "Nice", "Toulon", "Aix-en-Provence", "Avignon", "Cannes", "Antibes", "La Seyne-sur-Mer", "Nîmes", "Grasse"],
        "Normandie": ["Rouen", "Caen", "Le Havre", "Cherbourg", "Évreux", "Alençon", "Saint-Lô", "Lisieux", "Dieppe", "Coutances"],
        "Grand Est": ["Strasbourg", "Reims", "Metz", "Nancy", "Mulhouse", "Colmar", "Troyes", "Chalons-en-Champagne", "Épinal", "Thionville"],
        "Pays de la Loire": ["Nantes", "Le Mans", "Saint-Nazaire", "Angers", "La Roche-sur-Yon", "Laval", "Cholet", "Saint-Herblain", "Rezé", "Saint-Quentin-en-Yvelines"]
    ]

    // MARK: Japan
    private static let japan: [String: [String]] = [
        "Tokyo": ["Tokyo", "Shibuya", "Shinjuku", "Hachioji", "Tachikawa", "Musashino", "Mitaka", "Fuchu", "Machida", "Koganei"],
        "Osaka": ["Osaka", "Sakai", "Higashiosaka", "Hirakata", "Toyonaka", "Suita", "Takatsuki", "Yao", "Neyagawa", "Ibaraki"],
        "Kanagawa": ["Yokohama", "Kawasaki", "Sagamihara", "Fujisawa", "Yokosuka", "Chigasaki", "Hiratsuka", "Atsugi", "Yamato", "Odawara"],
        "Aichi": ["Nagoya", "Toyota", "Okazaki", "Ichinomiya", "Nagakute", "Kasugai", "Toyohashi", "Anjo", "Nishio", "Komaki"],
        "Hokkaido": ["Sapporo", "Asahikawa", "Hakodate", "Kushiro", "Obihiro", "Kitami", "Otaru", "Tomakomai", "Wakkanai", "Muroran"],
        "Fukuoka": ["Fukuoka", "Kitakyushu", "Kurume", "Omuta", "Iizuka", "Nogata", "Munakata", "Dazaifu", "Kasuga", "Onojo"],
        "Kyoto": ["Kyoto", "Uji", "Kameoka", "Muko", "Nagaokakyo", "Maizuru", "Fukuchiyama", "Ayabe", "Miyazu", "Joyo"],
        "Hyogo": ["Kobe", "Himeji", "Nishinomiya", "Amagasaki", "Akashi", "Itami", "Kakogawa", "Takarazuka", "Sanda", "Ashiya"]
    ]

    // MARK: China
    private static let china: [String: [String]] = [
        "Guangdong": ["Guangzhou", "Shenzhen", "Dongguan", "Foshan", "Zhuhai", "Shantou", "Zhongshan", "Jiangmen", "Huizhou", "Zhanjiang"],
        "Zhejiang": ["Hangzhou", "Ningbo", "Wenzhou", "Shaoxing", "Jinhua", "Jiaxing", "Huzhou", "Quzhou", "Taizhou", "Lishui"],
        "Jiangsu": ["Nanjing", "Suzhou", "Wuxi", "Changzhou", "Nantong", "Xuzhou", "Yangzhou", "Zhenjiang", "Taizhou", "Lianyungang"],
        "Shandong": ["Jinan", "Qingdao", "Zibo", "Yantai", "Weifang", "Jining", "Taian", "Weihai", "Linyi", "Laiwu"],
        "Sichuan": ["Chengdu", "Mianyang", "Deyang", "Luzhou", "Nanchong", "Leshan", "Yibin", "Guang'an", "Zigong", "Panzhihua"],
        "Beijing": ["Beijing", "Chaoyang", "Haidian", "Xicheng", "Dongcheng", "Fengtai", "Shijingshan", "Mentougou", "Fangshan", "Tongzhou"],
        "Shanghai": ["Shanghai", "Huangpu", "Xuhui", "Changning", "Jing'an", "Putuo", "Hongkou", "Yangpu", "Baoshan", "Minhang"],
        "Hubei": ["Wuhan", "Huangshi", "Yichang", "Xiangyang", "Jingzhou", "Xiaogan", "Ezhou", "Jingmen", "Huanggang", "Shiyan"]
    ]

    // MARK: Brazil
    private static let brazil: [String: [String]] = [
        "São Paulo": ["São Paulo", "Guarulhos", "Campinas", "São Bernardo do Campo", "Santo André", "Osasco", "Ribeirão Preto", "Sorocaba", "Mauá", "São José dos Campos"],
        "Rio de Janeiro": ["Rio de Janeiro", "São Gonçalo", "Duque de Caxias", "Nova Iguaçu", "Niterói", "Belford Roxo", "São João de Meriti", "Campos dos Goytacazes", "Petrópolis", "Volta Redonda"],
        "Minas Gerais": ["Belo Horizonte", "Contagem", "Juiz de Fora", "Betim", "Montes Claros", "Uberlândia", "Ribeirão das Neves", "Uberaba", "Governador Valadares", "Ipatinga"],
        "Bahia": ["Salvador", "Feira de Santana", "Vitória da Conquista", "Camaçari", "Juazeiro", "Itabuna", "Lauro de Freitas", "Ilhéus", "Jequié", "Teixeira de Freitas"],
        "Paraná": ["Curitiba", "Londrina", "Maringá", "Ponta Grossa", "Cascavel", "São José dos Pinhais", "Foz do Iguaçu", "Colombo", "Guarapuava", "Paranaguá"],
        "Rio Grande do Sul": ["Porto Alegre", "Caxias do Sul", "Pelotas", "Canoas", "Santa Maria", "Gravataí", "Viamão", "Novo Hamburgo", "São Leopoldo", "Rio Grande"],
        "Pernambuco": ["Recife", "Caruaru", "Petrolina", "Olinda", "Paulista", "Jaboatão dos Guararapes", "Cabo de Santo Agostinho", "Vitória de Santo Antão", "Garanhuns", "Camaragibe"],
        "Ceará": ["Fortaleza", "Caucaia", "Juazeiro do Norte", "Maracanaú", "Sobral", "Crato", "Itapipoca", "Maranguape", "Iguatu", "Quixadá"]
    ]
}
