SELECT trips_running.trip_id, arrival_time FROM

(SELECT trip_id FROM stop_times WHERE stop_id=(SELECT stop_id FROM stops WHERE stop_code='[stopNumber]')

INTERSECT

SELECT trip_id FROM trips WHERE service_id IN ( SELECT service_id FROM calendar WHERE [dayOfWeek]='1'
                                                EXCEPT
                                                SELECT service_id FROM calendar_dates WHERE date='[date]' AND exception_type='2'
                                                UNION
                                                SELECT service_id FROM calendar_dates WHERE date='[date]' AND exception_type='1')
) AS trips_running

INNER JOIN (SELECT * FROM stop_times WHERE stop_id=(SELECT stop_id FROM stops WHERE stop_code='[stopNumber]')) AS all_trips

ON trips_running.trip_id=all_trips.trip_id

WHERE arrival_time >= [secondsSinceMidnight]
ORDER BY arrival_time