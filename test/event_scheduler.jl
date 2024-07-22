using Dates

function event_scheduler(events)
    if isempty(events)
        return "No events"
    end

    # Sort events by start time
    sorted_events = sort(events, by = e -> DateTime(e[1], "yyyy-mm-dd HH:MM"))

    for i in 1:length(sorted_events)-1
        current_end = DateTime(sorted_events[i][2], "yyyy-mm-dd HH:MM")
        next_start = DateTime(sorted_events[i+1][1], "yyyy-mm-dd HH:MM")
        
        if current_end > next_start
            return "Conflict"
        end
    end

    return "No conflicts"
end

# Test cases
events1 = [
    ("2023-05-10 09:00", "2023-05-10 10:00"),
    ("2023-05-10 10:30", "2023-05-10 11:30"),
    ("2023-05-10 12:00", "2023-05-10 13:00")
]

events2 = [
    ("2023-05-10 09:00", "2023-05-10 10:30"),
    ("2023-05-10 10:00", "2023-05-10 11:00"),
    ("2023-05-10 12:00", "2023-05-10 13:00")
]

events3 = []

println(event_scheduler(events1))
println(event_scheduler(events2))
println(event_scheduler(events3))




