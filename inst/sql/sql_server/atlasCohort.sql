primary_events 
as
(
  -- Begin Primary Events
  select 
    P.ordinal as event_id, 
    P.person_id, 
    P.start_date, 
    P.end_date, 
    op_start_date, 
    op_end_date, 
    cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
  from
  (
    select E.person_id, E.start_date, E.end_date,
           row_number() over (partition by E.person_id order by E.sort_date asc) ordinal,
           OP.observation_period_start_date as op_start_date, 
           OP.observation_period_end_date as op_end_date, 
           cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
    from 
    (
      -- Begin Drug Exposure Criteria
      select 
        C.person_id, 
        C.drug_exposure_id as event_id, 
        C.drug_exposure_start_date as start_date,
        coalesce(C.DRUG_EXPOSURE_END_DATE, DATEADD(day,C.DAYS_SUPPLY,DRUG_EXPOSURE_START_DATE), DATEADD(day,1,C.DRUG_EXPOSURE_START_DATE)) as end_date,
        C.visit_occurrence_id,C.drug_exposure_start_date as sort_date
      from @cdm_database_schema.DRUG_EXPOSURE C
      -- End Drug Exposure Criteria
    ) E
	  JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id 
	    and E.start_date >=  OP.observation_period_start_date 
	    and E.start_date <= op.observation_period_end_date
    WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE 
      AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
  ) P
  WHERE P.ordinal = 1
-- End Primary Events
),
qualified_events as
(
  SELECT 
    event_id, 
    person_id, 
    start_date, 
    end_date, 
    op_start_date, 
    op_end_date, 
    visit_occurrence_id
  FROM 
  (
    select 
      pe.event_id, 
      pe.person_id, 
      pe.start_date, 
      pe.end_date, 
      pe.op_start_date,
      pe.op_end_date, 
      row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, 
      cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
    FROM primary_events pe
    
  ) QE
)