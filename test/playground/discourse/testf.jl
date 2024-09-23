
using Makie
using GLMakie

f = Figure(; size=(500, 400))
ax1 = Axis3(f[1, 2], aspect = (1, 1, 1.5),
xlabel = "x [m]", ylabel = "y [m]", zlabel = "z [m]",
title="t = 5 days")

# Sample coordinate data for the black line
coord_x = Float32[0, 1, 2, 3, 4, 5]
coord_y = Float32[0, 1, 2, 1, 0, 1]
coord_z = Float32[0, 1, 2, 3, 2, 1]

hm = lines!(ax1, coord_x, coord_y, coord_z, color=:black, colormap=:black, linewidth=5, colorrange=(-50, 300))

# Sample data for sensor positions
x_axe1, y_axe1 = Float32[1], Float32[1]
x_axe2, y_axe2 = Float32[3], Float32[2]
x_axe3, y_axe3 = Float32[5], Float32[0]

# Sample height data for sensors
h1, h2, h3 = Float32[0.5], Float32[1.5], Float32[2.5]

S1b = scatter!(ax1, x_axe1, y_axe1, h1, color=:red)
S1m = scatter!(ax1, x_axe1, y_axe1, h2, color=:green)
S1h = scatter!(ax1, x_axe1, y_axe1, h3, color=:blue)
S2b = scatter!(ax1, x_axe2, y_axe2, h1, color=:red)
S2m = scatter!(ax1, x_axe2, y_axe2, h2, color=:green)
S2h = scatter!(ax1, x_axe2, y_axe2, h3, color=:blue)
S3b = scatter!(ax1, x_axe3, y_axe3, h1, color=:red)
S3m = scatter!(ax1, x_axe3, y_axe3, h2, color=:green)
S3h = scatter!(ax1, x_axe3, y_axe3, h3, color=:blue)

# Add labels for each scatter
text!(ax1, x_axe1[1], y_axe1[1], h3[1], text="Sensor 1", align=(:left, :bottom))
text!(ax1, x_axe2[1], y_axe2[1], h3[1], text="Sensor 2", align=(:left, :bottom))
text!(ax1, x_axe3[1], y_axe3[1], h3[1], text="Sensor 3", align=(:left, :bottom))

f
