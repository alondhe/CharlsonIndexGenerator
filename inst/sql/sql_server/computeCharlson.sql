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
)
select 
  subject_id,
  cohort_start_date,
  cohort_end_date,
  sum(weight) as covariate_value
  from 
  (
    select distinct 
      charlson_scoring.diag_category_id,
	    charlson_scoring.weight,
	    cohort.subject_id,
	    cohort.cohort_start_date,
	    cohort.cohort_end_date
	  from final_cohort cohort
	  join @cdmDatabaseSchema.condition_era on cohort.subject_id = condition_era.person_id
	  join charlson_concepts_full on condition_era.condition_concept_id = charlson_concepts_full.concept_id
	  join charlson_scoring on charlson_concepts_full.diag_category_id = charlson_scoring.diag_category_id
	  where condition_era_start_date <= DATEADD(DAY, 0, cohort.cohort_start_date)
  )
group by subject_id