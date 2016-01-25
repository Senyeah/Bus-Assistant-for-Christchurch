SELECT trip_id, routes.route_id, route_long_name, trip_headsign

FROM ( SELECT *
       FROM  ( SELECT shape_id, trip_id, route_id, trip_headsign
               FROM trips
               GROUP BY shape_id
            ) AS unique_trips

       INNER JOIN ( SELECT DISTINCT shape_id
                    FROM stop_times, trips
                    WHERE stop_id='[stopTag]' AND stop_times.trip_id=trips.trip_id
                  ) AS trips_through_stop

       ON unique_trips.shape_id=trips_through_stop.shape_id

       GROUP BY trip_headsign
       ORDER BY route_id
     ) AS unique_trips_through_stop

INNER JOIN routes ON routes.route_id=unique_trips_through_stop.route_id