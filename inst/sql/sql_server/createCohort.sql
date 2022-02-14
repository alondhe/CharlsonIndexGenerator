cohort_primary_events
as
(
  select distinct
    person_id as subject_id,
    drug_exposure_start_date as cohort_start_date,
    drug_exposure_end_date as cohort_end_date
  from @cdmDatabaseSchema.drug_exposure
  where drug_concept_id in (@drugConceptIds)
  
  
  
  
),
qualified_events 
as
(
  select
    row_number() over cohort_start_date partition by subject_id,
    cohort_start_date,
    cohort_end_date
  from cohort_primary_events
  where rn = 1
)

  