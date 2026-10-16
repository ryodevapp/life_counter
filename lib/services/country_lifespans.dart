/// Source: WHO Global Health Observatory (GHO), Global Health Estimates,
/// estimates for the year 2023 (latest available; data refreshed 2026-10-01).
///   - Life expectancy at birth (WHOSIS_000001):
///     https://www.who.int/data/gho/data/indicators/indicator-details/GHO/life-expectancy-at-birth-(years)
///   - Healthy life expectancy (HALE) at birth (WHOSIS_000002):
///     https://www.who.int/data/gho/data/indicators/indicator-details/GHO/gho-ghe-hale-healthy-life-expectancy
///   - API used: https://ghoapi.azureedge.net/api/WHOSIS_000001 , https://ghoapi.azureedge.net/api/WHOSIS_000002
///
/// Exceptions (not covered by WHO GHO):
///   - TW (Taiwan): life expectancy = Ministry of the Interior, 2023 (ROC 112)
///     abridged life table (male 76.94 / female 83.74 / both 80.23)
///     https://www.moi.gov.tw/News_Content.aspx?n=4&s=320039&sms=9009
///     healthy = Ministry of Health and Welfare, 2022 (ROC 111) healthy life
///     expectancy (male 69.92 / female 75.07 / both 72.43; national method, not
///     WHO-comparable, latest found). https://www.cna.com.tw/news/ahel/202405260183.aspx
///   - HK (Hong Kong): life expectancy = Census and Statistics Department, 2023
///     (male 82.54 / female 88.09), both-sexes 85.25 via World Bank
///     (SP.DYN.LE00.*, sourced from C&SD).
///     https://api.worldbank.org/v2/country/HKG/indicator/SP.DYN.LE00.IN
///     healthy = ESTIMATE ONLY (no official/WHO HALE): HK life expectancy x
///     Singapore's WHO 2023 HALE/LE ratio for the same sex.
///
/// Note: JP here is WHO's figure. Japan's MHLW figures differ
/// (life expectancy 2025: male 81.35 / female 87.33; healthy life expectancy
/// 2022: male 72.57 / female 75.45) because the methods differ.
class CountryLifespan {
  const CountryLifespan({
    required this.male,
    required this.female,
    required this.both,
    required this.healthyMale,
    required this.healthyFemale,
    required this.healthyBoth,
  });

  final double male, female, both, healthyMale, healthyFemale, healthyBoth;
}

/// Keys: ISO 3166-1 alpha-2.
const countryLifespans = <String, CountryLifespan>{
  'US': CountryLifespan(male: 76.2, female: 80.9, both: 78.5, healthyMale: 63.8, healthyFemale: 65.4, healthyBoth: 64.6),
  'GB': CountryLifespan(male: 78.9, female: 82.6, both: 80.7, healthyMale: 67.9, healthyFemale: 68.4, healthyBoth: 68.2),
  'CA': CountryLifespan(male: 79.3, female: 83.4, both: 81.4, healthyMale: 67.5, healthyFemale: 68.4, healthyBoth: 67.9),
  'AU': CountryLifespan(male: 81.2, female: 84.8, both: 83.0, healthyMale: 69.1, healthyFemale: 69.9, healthyBoth: 69.5),
  'NZ': CountryLifespan(male: 79.3, female: 82.2, both: 80.7, healthyMale: 68.0, healthyFemale: 68.0, healthyBoth: 68.0),
  'IE': CountryLifespan(male: 80.8, female: 84.0, both: 82.4, healthyMale: 70.0, healthyFemale: 70.5, healthyBoth: 70.2),
  'DE': CountryLifespan(male: 78.8, female: 83.2, both: 81.0, healthyMale: 68.4, healthyFemale: 69.8, healthyBoth: 69.1),
  'FR': CountryLifespan(male: 79.9, female: 85.0, both: 82.5, healthyMale: 68.9, healthyFemale: 71.0, healthyBoth: 70.0),
  'ES': CountryLifespan(male: 80.8, female: 85.7, both: 83.3, healthyMale: 70.2, healthyFemale: 72.1, healthyBoth: 71.2),
  'IT': CountryLifespan(male: 81.0, female: 84.8, both: 82.9, healthyMale: 70.6, healthyFemale: 71.7, healthyBoth: 71.2),
  'NL': CountryLifespan(male: 80.2, female: 83.0, both: 81.6, healthyMale: 69.1, healthyFemale: 68.6, healthyBoth: 68.8),
  'SE': CountryLifespan(male: 81.4, female: 84.4, both: 82.9, healthyMale: 70.2, healthyFemale: 70.9, healthyBoth: 70.6),
  'NO': CountryLifespan(male: 81.3, female: 84.1, both: 82.7, healthyMale: 70.3, healthyFemale: 70.5, healthyBoth: 70.4),
  'DK': CountryLifespan(male: 80.4, female: 83.9, both: 82.1, healthyMale: 69.8, healthyFemale: 70.9, healthyBoth: 70.3),
  'FI': CountryLifespan(male: 78.7, female: 83.5, both: 81.1, healthyMale: 68.0, healthyFemale: 70.7, healthyBoth: 69.4),
  'CH': CountryLifespan(male: 82.2, female: 85.4, both: 83.8, healthyMale: 71.0, healthyFemale: 71.4, healthyBoth: 71.2),
  'KR': CountryLifespan(male: 80.6, female: 86.5, both: 83.6, healthyMale: 70.2, healthyFemale: 73.7, healthyBoth: 72.0),
  'TW': CountryLifespan(male: 76.9, female: 83.7, both: 80.2, healthyMale: 69.9, healthyFemale: 75.1, healthyBoth: 72.4), // national stats: LE 2023, healthy 2022
  'CN': CountryLifespan(male: 75.0, female: 81.1, both: 77.9, healthyMale: 66.2, healthyFemale: 69.9, healthyBoth: 68.0),
  'HK': CountryLifespan(male: 82.5, female: 88.1, both: 85.2, healthyMale: 72.5, healthyFemale: 76.3, healthyBoth: 74.3), // LE: C&SD 2023; healthy: estimate
  'SG': CountryLifespan(male: 81.5, female: 85.7, both: 83.6, healthyMale: 71.6, healthyFemale: 74.2, healthyBoth: 72.9),
  'IN': CountryLifespan(male: 69.3, female: 72.8, both: 71.0, healthyMale: 60.4, healthyFemale: 60.9, healthyBoth: 60.6),
  'BR': CountryLifespan(male: 72.8, female: 79.0, both: 75.9, healthyMale: 62.6, healthyFemale: 65.1, healthyBoth: 63.8),
  'MX': CountryLifespan(male: 72.3, female: 78.3, both: 75.3, healthyMale: 61.6, healthyFemale: 64.6, healthyBoth: 63.1),
  'JP': CountryLifespan(male: 81.2, female: 86.5, both: 83.9, healthyMale: 70.9, healthyFemale: 73.5, healthyBoth: 72.2),
};

/// WHO global average, 2023.
const worldLifespan = CountryLifespan(male: 70.6, female: 76.1, both: 73.3, healthyMale: 61.5, healthyFemale: 64.1, healthyBoth: 62.8);
