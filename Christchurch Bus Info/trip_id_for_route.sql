INSERT INTO results (trip_id)
SELECT trip_id FROM trips WHERE route_id='[routeID]' AND direction_id='[direction]' LIMIT 1;