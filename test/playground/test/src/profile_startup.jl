using Profile

# Start profiling
@profile begin
    using AISH
    AISH.initialize_ai_state()
end

# Save profile data
Profile.print()

