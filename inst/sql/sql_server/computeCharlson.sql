charlson_scoring
as
(
  @charlsonScoringSql
),
charlson_concepts
as
(
  @charlsonConceptSql
),
charlson_concepts_full
as
(
  select 
    CC.diag_category_id,
    CA.descendant_concept_id as concept_id
  from charlson_concepts CC
  join @cdmDatabaseSchema.concept_ancestor CA on CC.ancestor_concept_id = CA.ancestor_concept_id
),
  before_age_adjust
  as
  (
  select 
    subject_id,
    age,
    cohort_start_date,
    cohort_end_date,
    sum(weight) as covariate_value
    from 
    (
      select distinct 
        charlson_scoring.diag_category_id,
  	    charlson_scoring.weight,
  	    cohort.subject_id,
  	    year(cohort.cohort_start_date) - P.year_of_birth as age,
  	    cohort.cohort_start_date,
  	    cohort.cohort_end_date
  	  from final_cohort cohort
  	  join @cdmDatabaseSchema.condition_era on cohort.subject_id = condition_era.person_id
  	  join charlson_concepts_full on condition_era.condition_concept_id = charlson_concepts_full.concept_id
  	  join charlson_scoring on charlson_concepts_full.diag_category_id = charlson_scoring.diag_category_id
  	  join @cdmDatabaseSchema.person P on cohort.subject_id = P.person_id
  	  where condition_era_start_date <= DATEADD(DAY, 0, cohort.cohort_start_date)
    )
  group by subject_id,
    age,
    cohort_start_date,
    cohort_end_date
)
select
  subject_id,
  cohort_start_date,
  cohort_end_date,
  age,
  covariate_value,
  case 
    when age >= 50 and age <= 59 then covariate_value + 1
    when age >= 60 and age <= 69 then covariate_value + 2
    when age >= 70 and age <= 79 then covariate_value + 3
    when age >= 80 then covariate_value + 4
    else covariate_value
  end as age_adjusted_value
from before_age_adjust