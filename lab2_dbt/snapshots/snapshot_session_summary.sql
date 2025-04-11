{% snapshot snapshot_session_summary %}
{{
 config(
 target_schema='snapshot',
 unique_key='symbol || \'_\' || TO_VARCHAR(date)',
 strategy='check',
 check_cols = 'all',
 invalidate_hard_deletes=True
 )
}}
SELECT * FROM {{ ref('session_summary') }}
{% endsnapshot %} 
