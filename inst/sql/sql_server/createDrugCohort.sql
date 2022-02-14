codesets
as
(
  select 
    concept_id 
  from @cdmDatabaseSchema.concept 
  where concept_id in (@drugConceptIds)
  union  
  select 
    c.concept_id
  from @cdmDatabaseSchema.concept c
  join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (@drugConceptIds)
    and c.invalid_reason is null
  union
  select distinct cr.concept_id_1 as concept_id
  from
  (
    select 
      concept_id 
    from @cdmDatabaseSchema.concept 
    where concept_id in (@drugConceptIds)
    union  
    select 
      c.concept_id
    from @cdmDatabaseSchema.concept c
    join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (@drugConceptIds)
    and c.invalid_reason is null
  ) C
  join @cdmDatabaseSchema.concept_relationship cr on C.concept_id = cr.concept_id_2 
    and cr.relationship_id = 'Maps to'
    and cr.invalid_reason is null
),
primary_events
as
(
  -- Begin Primary Events
  select 
    P.ordinal as event_id, 
    P.person_id, P.start_date, 
    P.end_date, 
    op_start_date, 
    op_end_date, 
    cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
  from
  (
    select 
      E.person_id, 
      E.start_date, 
      E.end_date,
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
        coalesce(C.drug_exposure_end_date, dateadd(day,C.days_supply, drug_exposure_start_date), dateadd(day, 1, C.drug_exposure_start_date)) as end_date,
        C.visit_occurrence_id,
        C.drug_exposure_start_date as sort_date
      from @cdmDatabaseSchema.drug_exposure C
      join codesets cs on C.drug_concept_id = cs.concept_id
    -- End Drug Exposure Criteria
    ) E
	  join @cdmDatabaseSchema.observation_period OP on E.person_id = OP.person_id 
	    and E.start_date >=  OP.observation_period_start_date 
	    and E.start_date <= OP.observation_period_end_date
    where dateadd(day, 0, OP.observation_period_start_date) <= E.start_date 
      and dateadd(day, 0, E.start_date) <= OP.observation_period_end_date
  ) P
  where P.ordinal = 1
  -- End Primary Events
),
qualified_events
as 
(
  select 
    pe.event_id, 
    pe.person_id, 
    pe.start_date, 
    pe.end_date, 
    pe.op_start_date, 
    pe.op_end_date, 
    row_number() over (partition by pe.person_id order by pe.start_date asc) as ordinal, 
    cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  from primary_events pe
),
cohort_ends
as
(
  select 
    event_id, 
    person_id, 
    op_end_date as end_date 
  from qualified_events
),
first_ends
as
(
	select 
	  F.person_id, 
	  F.start_date, 
	  F.end_date
	from
	(
	  select 
	    I.event_id, 
	    I.person_id, 
	    I.start_date, 
	    E.end_date, 
	    row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from qualified_events I
	  join cohort_ends E on I.event_id = E.event_id 
	    and I.person_id = E.person_id 
	    and E.end_date >= I.start_date
	) F
	where F.ordinal = 1
),
cohort_rows
as
(
  select person_id, start_date, end_date
  from first_ends
),
cteEndDates
as -- the magic
(	
	select
		person_id,
		dateadd(day,-1 * 0, event_date)  as end_date
	from
	(
		select
			person_id,
			event_date,
			event_type,
			max(start_ordinal) over (partition by person_id order by event_date, event_type rows unbounded preceding) as start_ordinal, 
			row_number() over (partition by person_id order by event_date, event_type) as overall_ord
		from
		(
			select
				person_id, 
				start_date as event_date, 
				-1 as event_type, 
				row_number() over (partition by person_id order by start_date) as start_ordinal
			from cohort_rows
		
			union ALL

			select
				person_id, 
				dateadd(day, 0, end_date) as end_date, 
				1 as event_type, 
				null
			from cohort_rows
		) RAWDATA
	) e
	where (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds 
as
(
	select
		c.person_id, 
		c.start_date, 
		MIN(e.end_date) as end_date
	from cohort_rows c
	join cteEndDates e on c.person_id = e.person_id and e.end_date >= c.start_date
	group by c.person_id, c.start_date
),
final_cohort
as
(
  select 
    person_id as subject_id, 
    min(start_date) as cohort_start_date, 
    end_date as cohort_end_date
  from cteEnds
  group by person_id, end_date
)