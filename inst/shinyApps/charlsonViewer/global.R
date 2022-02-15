charlsonIntro <- "The Charlson comorbidity index was developed to predict mortality rates based on prior
diagnoses. Several researchers have applied the Charlson index to administrative
claims databases and other observational sources. In short, the index is a weighted
sum of the occurrence of 17 medical conditions of interest."

appIntro <- "This application applies the Charlson Comorbidity Index to a drug cohort of interest. All data analyses are performed against data transformed to the OMOP Common Data Model v5.4"

step1 <- "Fill out the connection details for your CDM database. If you'd like to simply demo this tool without connecting to your environment, select the synthetic \"Eunomia\" DBMS type."
step2 <- "Select 1 or more drug concepts rows for creation of an exposed population, indexed on the date of first exposure. Selected rows appear in blue."
step3 <- "Below are a box plot of the Charlson Index scores for this cohort, as well as a listing of the scores per Person Id."


charlsonSteps <- c(
  "From the Charlson method, we assign scoring weights to 17 diagnostic categories",
  "Using the OMOP Vocabulary, we identify appropriate ancestor concept ids based on these diagnostic categories. 
  This will help us obtain all appropriate condition concept ids for each diagnostic category",
  "We join the cohort to the condition_era table and to the Charlson concepts and scoring tables, 
  looking for condition eras (span of time when the Person is assumed to have a given condition) that 
  precede or coincide with the exposure to the drugs of interest",
  "We then sum all of the weights of each Charlson category fulfilled by the patients to get the final Charlson score"
)


references <- c(
"Charlson M, Szatrowski TP, Peterson J, Gold J. Validation of a combined comorbidity index. J Clin Epidemiol 1994;47(11):1245-51.",
"Quan H, Sundararajan V, Halfon P, Fong A, Burnand B, Luthi JC, et al. Coding algorithms for defining comorbidities in ICD-9-CM and ICD-10 administrative data. Med Care 2005;43(11):1130-9.",
"Deyo RA, Cherkin DC, Ciol MA. Adapting a clinical comorbidity index for use with ICD-9-CM administrative databases. J Clin Epidemiol 1992;45(6):613-9.",
"Romano PS, Roos LL, Jollis JG. Adapting a clinical comorbidity index for use with ICD-9-CM administrative data: differing perspectives. J Clin Epidemiol 1993;46(10):1075-9; discussion 1081-90.",
"Schneeweiss S, Seeger JD, Maclure M, Wang PS, Avorn J, Glynn RJ. Performance of comorbidity scores to control for confounding in epidemiologic studies using claims data. Am J Epidemiol 2001;154(9):854-64.",
"Schneeweiss S, Maclure M. Use of comorbidity scores for control of confounding in studies using administrative databases. Int J Epidemiol 2000;29(5):891-8.",
"D'Hoore W, Bouckaert A, Tilquin C. Practical considerations on the use of the Charlson comorbidity index with administrative data bases. J Clin Epidemiol 1996;49(12):1429-33.",
"D'Hoore W, Sicotte C, Tilquin C. Risk adjustment in outcome assessment: the Charlson comorbidity index. Methods Inf Med 1993;32(5):382-7."
)

.factorizeDf <- function(df) {
  df[sapply(df, is.character)] <- lapply(df[sapply(df, is.character)], as.factor)
  return(df)
}

.createSqlListString <- function(array) {
  paste(lapply(unique(array), function(l) shQuote(l)), collapse = ",")
}

dbmsChoices <- c("eunomia", SqlRender::listSupportedDialects()$dialect)

charlsonConcepts <- read.csv(system.file("csv/charlsonConcepts.csv", package = "CharlsonIndexGenerator"), 
                     as.is = TRUE, stringsAsFactors = FALSE)

charlsonScoring <- read.csv(system.file("csv/charlsonScoring.csv", package = "CharlsonIndexGenerator"), 
                            as.is = TRUE, stringsAsFactors = FALSE) |>
  dplyr::mutate(diag_category_name = gsub(pattern = "'", replacement = "", x = diag_category_name))

