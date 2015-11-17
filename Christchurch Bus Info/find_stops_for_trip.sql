SELECT stops.stop_code, stops.stop_name, is_major_stop, stop_sequence

FROM ( SELECT stops.stop_id, '0' AS is_major_stop, stop_sequence
       FROM stops, stop_times times1
       WHERE times1.trip_id='[tripID]' AND
             times1.stop_id=stops.stop_id

       EXCEPT

       SELECT major_stops.stop_id, '0' AS is_major_stop, times2.stop_sequence
       FROM major_stops, stop_times times2, trips

       WHERE major_stops.route_tag=trips.shape_id AND
             major_stops.stop_id=times2.stop_id AND
             trips.trip_id=times2.trip_id AND
             trips.trip_id='[tripID]'

       UNION

       SELECT major_stops.stop_id, '1' AS is_major_stop, stop_times.stop_sequence
       FROM major_stops, stop_times, trips

       WHERE major_stops.route_tag=trips.shape_id AND
             major_stops.stop_id=stop_times.stop_id AND
             trips.trip_id=stop_times.trip_id AND
             trips.trip_id='[tripID]'

     ) AS stop_tags_for_trip

INNER JOIN stops ON stop_tags_for_trip.stop_id=stops.stop_id
ORDER BY stop_sequence