with users_clean as (
  select
    user_id,
    promo_signup_flag,
    signup_datetime,
    to_date(
      lpad(split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 1), 2, '0') || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 2), 2, '0') || '-' ||
      case
        when length(split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)) = 2
          then '20' || split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)
        when length(split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)) = 4
          then split_part(regexp_replace(split_part(trim(signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)
        else null
      end,
      'dd-mm-yyyy'
    )::timestamp as signup_ts
  from cohort_users_raw
),
events_clean as (
  select
    user_id,
    event_type,
    event_datetime,
    to_date(
      lpad(split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 1), 2, '0') || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 2), 2, '0') || '-' ||
      case
        when length(split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)) = 2
          then '20' || split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)
        when length(split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)) = 4
          then split_part(regexp_replace(split_part(trim(event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 3)
        else null
      end,
      'dd-mm-yyyy'
    )::timestamp as event_ts
  from cohort_events_raw
),
joined_data as (
  select
    u.user_id,
    u.promo_signup_flag,
    date_trunc('month', u.signup_ts)::date as cohort_month,
    date_trunc('month', e.event_ts)::date as activity_month,
    extract(
      month from age(
        date_trunc('month', e.event_ts),
        date_trunc('month', u.signup_ts)
      )
    ) as month_offset
  from users_clean u
  join events_clean e
    on u.user_id = e.user_id
  where u.signup_ts is not null
    and e.event_ts is not null
    and e.event_type is not null
    and e.event_type <> 'test_event'
    and date_trunc('month', e.event_ts)::date between date '2025-01-01' and date '2025-06-01'
)
select
  promo_signup_flag,
  cohort_month,
  month_offset,
  count(distinct user_id) as users_total
from joined_data
group by
  promo_signup_flag,
  cohort_month,
  month_offset
order by
  promo_signup_flag,
  cohort_month,
  month_offset;