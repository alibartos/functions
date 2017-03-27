/*
Bartos
Created: 3/27/17
Last Updated: 3/27/17

Sandbox to create functions

Running list:
-timestamp to date
-business hours

*/


---------------------------------------------------------------------------------FUNCTION: TIMESTAMP TO DATE---------------------------------------------------------------------------------
        CREATE FUNCTION prod_saj_share.work_revopt.timestamp_to_date (t timestamp)
        RETURNS date
        COMMENT = 'convert timestamp to date without rounding error'
        AS '(date_trunc(''DAY'',to_timestamp(t)))::date'
        ;
                
        SELECT prod_saj_share.work_revopt.timestamp_to_date('2017-02-08 14:59:27')
                
        SHOW USER FUNCTIONS IN prod_saj_share.work_revopt
                
                
---------------------------------------------------------------------------------FUNCTION: BUSINESS HOURS---------------------------------------------------------------------------------

        CREATE FUNCTION prod_saj_share.work_revopt.business_hr_conversion (t timestamp)
        RETURNS timestamp
        COMMENT = 'convert a timestamp to business hours (M-F, 8AM-6PM)'
        AS '
                SELECT s.input_datetime_adj
                FROM (
                        SELECT 
                                 CASE
                                        WHEN date_part(hour,input_datetime) < date_part(hour,input_workday_start_actual) AND (input_day NOT IN (''Saturday'',''Sunday''))  THEN input_workday_start_actual --if input before 8AM on weekday, bump to 8AM same day
                                        WHEN (date_part(hour,input_datetime) >= date_part(hour,input_workday_end_actual)) OR (input_day IN (''Saturday'',''Sunday'')) THEN input_start_next_bd --if input after 6PM OR on weekend, bump to 8AM next bd
                                        ELSE input_datetime END AS input_datetime_adj
                        FROM (
                                SELECT s.timestamp_orig::timestamp AS input_datetime
                                        ,b.day AS input_day
                                        ,prod_saj_share.work_revopt.timestamp_to_date(s.timestamp_orig) input_date
                                        ,TO_TIME(s.timestamp_orig) input_time
                                        ,dateadd(min,(5*60),b.date) AS input_workday_start_actual
                                        ,dateadd(min,(15*60),b.date) AS input_workday_end_actual                
                                        ,CASE WHEN (b.day = ''Friday'') THEN dateadd(day,3,(dateadd(min,(5*60),b.date))) 
                                              WHEN (b.day = ''Saturday'') THEN dateadd(day,2,(dateadd(min,(5*60),b.date))) 
                                              WHEN (b.day = ''Sunday'') THEN dateadd(day,1,(dateadd(min,(5*60),b.date)))
                                              ELSE dateadd(day,1,(dateadd(min,(5*60),b.date)))
                                              END AS input_start_next_bd
                                        ,CASE WHEN (b.day = ''Friday'') THEN dateadd(day,3,(dateadd(min,(15*60),b.date))) 
                                              WHEN (b.day = ''Saturday'') THEN dateadd(day,2,(dateadd(min,(15*60),b.date))) 
                                              WHEN (b.day = ''Sunday'') THEN dateadd(day,1,(dateadd(min,(15*60),b.date)))
                                              ELSE dateadd(day,1,(dateadd(min,(15*60),b.date))) 
                                              END AS input_end_next_bd
                                FROM (
                                        SELECT t AS timestamp_orig
                                        ) s
                                LEFT JOIN prod_saj_share.dbo.dw_dm_time_day b ON prod_saj_share.work_revopt.timestamp_to_date(s.timestamp_orig) = b.date::date
                        ) s 
                ) s
                LEFT JOIN prod_saj_share.dbo.dw_dm_time_day tr ON prod_saj_share.work_revopt.timestamp_to_date(s.input_datetime_adj) = tr.date::date
        '
        ;

        SELECT prod_saj_share.work_revopt.business_hr_conversion('2017-03-19 18:59:27')

