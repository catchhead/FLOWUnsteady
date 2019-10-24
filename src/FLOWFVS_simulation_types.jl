#=##############################################################################
# DESCRIPTION
    Simulation interface connecting vehicles and maneuvers.

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Oct 2019
  * License   : MIT
=###############################################################################



################################################################################
# SIMULATION TYPE
################################################################################
"""
    `Simulation(vehicle, maneuver, Vref::Real, RPMref::R, ttot:R)`

Simulation interface. This type carries the simulation's options and connects
vehicle and maneuver together.
"""
mutable struct Simulation{V<:AbstractVehicle, M<:AbstractManeuver, R<:Real}
    # USER INPUTS: Simulation setup
    vehicle::V              # Vehicle
    maneuver::M             # Maneuver to be performed
    Vref::R                 # Reference velocity in this maneuver
    RPMref::R               # Reference RPM in this maneuver
    ttot::R                 # Total time in which to perform the maneuver


    # INTERNAL PROPERTIES: Runtime parameters
    t::R                    # Dimensional time
    nt::Int                 # Current time step number

    Simulation{V, M, R}(
                            vehicle, maneuver, Vref, RPMref, ttot;
                            t=zero(R), nt=0
                        ) where {V, M, R} = _check(vehicle, maneuver) ? new(
                            vehicle, maneuver, Vref, RPMref, ttot,
                            t, nt
                        ) : nothing
end


# Implicit V and M constructor
Simulation(v::AbstractVehicle, m::AbstractManeuver, n::Real, args...
             ) = Simulation{typeof(v), typeof(m), typeof(n)}(v, m, n, args...)




##### FUNCTIONS  ###############################################################

"""
    `nextstep_kinematic(self::Simulation, dt::Real)`

Takes a kinematic time step `dt` where the new velocity and angular velocity
is calculated and the vehicle is translated and rotated according to it. It also
updates the tilt angle and RPM of every system.

NOTE: No solver is run in this process, rather it uses the current aerodynamic
solution to calculate acceleration and moment.
"""
function nextstep_kinematic(self::Simulation, dt::Real)

    # Linear velocity increment
    dV = calc_dV(self.maneuver, self.vehicle, self.t, dt, self.ttot, self.Vref)

    # Angular velocity increment
    dW = calc_dW(self.maneuver, self.vehicle, self.t, dt, self.ttot)

    # Update vehicle linear and angular velocity
    add_dV(self.vehicle, dV)
    add_dW(self.vehicle, dW)

    # Translates and rotates the vehicle according to current velocity
    nextstep_kinematic(self.vehicle, dt)

    # Rotate tilting systems
    angles = get_angles(self.maneuver, self.t/self.ttot)
    tilt_systems(self.vehicle, angles)

    # TODO: Have the rotor solver update rotor RPMs


    self.t += dt
    self.nt += 1
end


function save_vtk(self::Simulation, filename; optargs...)
    return save_vtk(self.vehicle, filename; num=self.nt, optargs...)
end



##### INTERNAL FUNCTIONS  ######################################################
"""
Checks that vehicle and maneuver are compatible.
"""
function _check(vehicle::AbstractVehicle, maneuver::AbstractManeuver;
                                                            raise_error=true)
    res = get_ntltsys(vehicle)==get_ntltsys(maneuver)
    res *= get_nrtrsys(vehicle)==get_nrtrsys(maneuver)

    if raise_error && res==false
        error("Encountered incompatible Vehicle and Maneuver!")
    end

    return res
end
##### END OF SIMULATION  #######################################################
