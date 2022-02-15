charlsonIntro <- "The Charlson comorbidity index was developed to predict mortality rates based on prior
diagnoses. Several researchers have applied the Charlson index to administrative
claims databases and other observational sources. In short, the index is a weighted
sum of the occurrence of 17 medical conditions of interest."

appIntro <- "This application applies the Charlson Comorbidity Index to a drug cohort of interest. All data analyses are performed against data transformed to the OMOP Common Data Model v5.4"


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

dbmsChoices <- c("eunomia", SqlRender::listSupportedDialects()$dialect)

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
allDrugConcepts <- DatabaseConnector::querySql(connection = connection, 
  sql = "select distinct concept_id, concept_name, concept_class_id
         from main.concept
         where domain_id = 'Drug' and standard_concept = 'S' and invalid_reason is null")