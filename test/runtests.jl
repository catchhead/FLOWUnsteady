# Load simulation engine
include(joinpath(splitdir(@__FILE__)[1], "../src/fvs.jl"))

# ------------ GENERIC MODULES -------------------------------------------------
using Base.Test
using PyPlot
using JLD

# ------------ HEADERS ---------------------------------------------------------
# Load modules
for module_name in ["bertinswing"]
    include("test_"*module_name*".jl")
end

# ------------ TESTS -----------------------------------------------------------
@test bertin_VLM(; wake_coupled=false, nsteps=1, verbose=true, disp_plot=true)
@test bertin_VLM(; wake_coupled=true, nsteps=150, verbose=true, disp_plot=true)
# @test bertin_VLM(; wake_coupled=true, nsteps=150, save_path="temps/bertinswing03/", verbose=true)



# TODO
# * Test VLM regularization
# * Test solution on kinematic velocity
