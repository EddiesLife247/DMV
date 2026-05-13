--[[
    eb_dmv - Silver Cloud RP DMV License System
    Author: EddiesLife247 / EB IT Support
    Framework: QBX Core + ox_lib + ox_target
--]]

Config = {}

-- ─────────────────────────────────────────────
--  GENERAL SETTINGS
-- ─────────────────────────────────────────────
Config.Debug = true  -- set true to see prints

-- ─────────────────────────────────────────────
--  JOB-BASED PERMISSIONS
--  If true, players in Config.PoliceJobs / Config.AdminJobs
--  can use commands without needing the ace permission
-- ─────────────────────────────────────────────
Config.UseJobPermissions = true

-- ─────────────────────────────────────────────
--  SEATBELT
-- ─────────────────────────────────────────────

-- Whether seatbelt is required during the practical test
Config.SeatbeltRequired = false -- NOT WORKING DO NOT ENABLE YET.

-- Which built-in method to use.
-- Options: "jim-mechanic", "jg-hud", "qbx_seatbelt", "native"
-- Ignored if Config.SeatbeltCheckCustom is defined.
Config.SeatbeltResource = "jim-mechanic"

-- CUSTOM OVERRIDE (optional)
-- Define this function to completely replace the built-in seatbelt check.
-- Must return true if the seatbelt IS on, false if not.
-- This lives in config.lua so it is never escrowed.
-- Example:
-- Config.SeatbeltCheckCustom = function()
--     return exports['my-seatbelt-resource']:IsBuckled()
-- end
Config.SeatbeltCheckCustom = nil

-- How long (seconds) the player has to reach each waypoint during practicals
Config.WaypointTimeouts = {
    car        = 90,
    bus_hgv    = 120,
    plane      = 500,
    helicopter = 500,
}

-- Pass mark (out of 15 questions for theory test)
Config.PassMark = 12

-- License item names stored in player metadata (adjust to match your items/metadata)
-- Maps eb_dmv licence types to QBX metadata.licences keys
Config.LicenseMetaKeys = {
    car        = "licensecar",
    bus_hgv    = "licensebushgv",
    plane      = "licenseplane",
    helicopter = "licensehelicopter",
}

Config.VehicleKeysResource = "Renewed-Vehiclekeys"

-- ─────────────────────────────────────────────
--  POLICE / SUSPENSION SETTINGS
-- ─────────────────────────────────────────────

-- If true, players with an active warrant in tk_mdt cannot start a test
Config.DenyOnWarrant = true

-- If true, suspended players cannot start a test
Config.SuspensionEnabled = true

-- Suspension is stored as a Unix timestamp in the DB
-- Police use /dmvsuspend <id> <licencetype> <minutes> [reason]
Config.SuspendCommand    = "dmvsuspend"
Config.UnsuspendCommand  = "dmvunsuspend"
Config.PoliceJobs = {
  'Police',
  'fib'
}
Config.PoliceAce        = "eb_dmv.police"


-- ─────────────────────────────────────────────
--  COSTS  (set to 0 for free)
-- ─────────────────────────────────────────────
Config.Costs = {
    car        = { theory = 50,   practical = 150  },
    bus_hgv    = { theory = 75,   practical = 250  },
    plane      = { theory = 100,  practical = 500  },
    helicopter = { theory = 100,  practical = 500  },
}

-- ─────────────────────────────────────────────
--  ENABLE / DISABLE TEST STAGES
-- ─────────────────────────────────────────────
Config.TheoryEnabled    = true   -- false = skip theory, go straight to practical
Config.PracticalEnabled = true   -- false = pass theory = instant licence grant
-- Maximum warnings before a test failure (speed, seatbelt)
Config.MaxWarnings = 3
-- ─────────────────────────────────────────────
--  ADMIN COMMAND
--  /dmvgrant <id> <licencetype> <stage>
--  stage: "theory", "practical", "both"
--  Requires ace permission: eb_dmv.admin
-- ─────────────────────────────────────────────
Config.AdminCommand = "dmvgrant"
Config.AdminAce     = "admin"
Config.AdminJobs    = { "admin", "superadmin" }

-- ─────────────────────────────────────────────
--  NPC / ox_target PED LOCATIONS
--  Each license type has one examiner ped
-- ─────────────────────────────────────────────
Config.Examiners = {
    car = {
        label  = "Car Licence Examiner",
        model  = "s_m_m_dockwork_01",
        coords = vector4(234.2, -1388.06, 30.55, 146.34),   -- LSIA area / driving school
        blip   = { sprite = 225, colour = 3, scale = 0.8, label = "DMV - Car Licence" },
    },
    bus_hgv = {
        label  = "Bus / HGV Licence Examiner",
        model  = "s_m_m_trucker_01",
        coords = vector4(453.86, -571.9, 28.5, 170.62),
        blip   = { sprite = 513, colour = 5, scale = 0.8, label = "DMV - Bus/HGV Licence" },
    },
    plane = {
        label  = "Pilot Licence Examiner",
        model  = "s_m_m_pilot_01",
        coords = vector4(-1019.49, -2919.08, 13.95, 58.75), -- Sandy airfield / LSIA
        blip   = { sprite = 16,  colour = 27, scale = 0.8, label = "DMV - Pilot Licence" },
    },
    helicopter = {
        label  = "Helicopter Licence Examiner",
        model  = "s_f_y_airhostess_01",
        coords = vector4(-742.38, -1447.01, 5.0, 108.0),     -- Helipad near LS
        blip   = { sprite = 422, colour = 46, scale = 0.8, label = "DMV - Helicopter Licence" },
    },
}

-- ─────────────────────────────────────────────
--  THEORY QUIZ QUESTIONS  (15 per licence)
-- ─────────────────────────────────────────────
-- Format: { question, answers = {}, correct = index }
Config.Questions = {

    -- ── CAR ──────────────────────────────────
    car = {
        { q = "What is the national speed limit on a single-carriageway road in the UK?",
          a = {"50 mph", "60 mph", "70 mph", "80 mph"}, correct = 2 },
        { q = "What does a flashing amber light at a pelican crossing mean?",
          a = {"Stop and wait", "Give way to pedestrians", "Proceed if the road is clear", "Speed up to clear the crossing"}, correct = 2 },
        { q = "You must not park within how many metres of a junction?",
          a = {"5 metres", "10 metres", "15 metres", "20 metres"}, correct = 2 },
        { q = "What shape is a warning sign in the UK?",
          a = {"Rectangle", "Circle", "Triangle", "Diamond"}, correct = 3 },
        { q = "A solid white line in the centre of the road means:",
          a = {"You may overtake if safe", "No overtaking allowed", "The road is one-way", "Bus lane ahead"}, correct = 2 },
        { q = "When must you use dipped headlights in daylight?",
          a = {"Never – only at night", "When visibility is seriously reduced", "On motorways only", "When driving at 60+ mph"}, correct = 2 },
        { q = "What is the stopping distance at 30 mph in good conditions?",
          a = {"23 metres", "14 metres", "53 metres", "36 metres"}, correct = 1 },
        { q = "A 'no entry' sign is:",
          a = {"A red triangle", "A blue circle", "A red circle with white bar", "A white rectangle"}, correct = 3 },
        { q = "You're driving and feel tired. What should you do?",
          a = {"Open a window and continue", "Turn the radio up", "Stop safely and rest", "Drink coffee and keep going"}, correct = 3 },
        { q = "On a motorway, which lane should you drive in normally?",
          a = {"Middle lane", "Outside lane", "Left lane", "Any lane"}, correct = 3 },
        { q = "What does a broken white line down the centre of the road indicate?",
          a = {"No overtaking", "Hazard ahead", "You may cross if safe", "Lane merge"}, correct = 3 },
        { q = "The legal minimum tyre tread depth for a car is:",
          a = {"1mm", "1.6mm", "2mm", "3mm"}, correct = 2 },
        { q = "You must ALWAYS wear a seatbelt unless:",
          a = {"Travelling under 10 mph", "Reversing", "On a private road", "Driving an automatic"}, correct = 2 },
        { q = "A zebra crossing has:",
          a = {"Traffic lights", "Flashing amber beacons and black/white stripes", "A central island only", "A push button"}, correct = 2 },
        { q = "What does a green traffic light mean?",
          a = {"Stop if possible", "Proceed only if the road is clear and it is safe", "Always go immediately", "Slow down"}, correct = 2 },
    },

    -- ── BUS / HGV ─────────────────────────────
    bus_hgv = {
        { q = "What is the maximum speed for an HGV over 7.5t on a motorway?",
          a = {"50 mph", "60 mph", "70 mph", "80 mph"}, correct = 2 },
        { q = "A vehicle over 3.5 tonnes must have a tachograph because:",
          a = {"It's a luxury option", "It records driver hours and speed", "Insurance requires it", "It improves fuel economy"}, correct = 2 },
        { q = "You are driving an HGV. A low bridge is marked at 13'6\". What does this mean?",
          a = {"Maximum length allowed", "Maximum height allowed", "Minimum clearance for lorries", "Speed limit near the bridge"}, correct = 2 },
        { q = "When should you NOT undertake a bus on the left on a dual carriageway?",
          a = {"Never – it is always legal", "When traffic is slow-moving", "When the bus is stationary", "When the bus is pulling away from a stop"}, correct = 4 },
        { q = "An articulated lorry has a longer stopping distance because:",
          a = {"It's wider", "Tractor and trailer can jack-knife", "The engine is larger", "The cab is heavier"}, correct = 2 },
        { q = "What is the maximum weight an HGV can carry without a special permit in the UK?",
          a = {"32 tonnes", "38 tonnes", "44 tonnes", "50 tonnes"}, correct = 3 },
        { q = "When reversing an articulated vehicle, the trailer turns:",
          a = {"Same direction as the cab wheels", "Opposite direction to the cab steering", "Towards the kerb automatically", "It doesn't turn"}, correct = 2 },
        { q = "You must take a 45-minute break after driving for a maximum of:",
          a = {"3 hours", "4.5 hours", "6 hours", "9 hours"}, correct = 2 },
        { q = "Large vehicles must use which type of mirrors to see alongside the vehicle?",
          a = {"Wide-angle mirrors", "Interior mirror", "Rear-view mirrors", "Spot mirrors"}, correct = 1 },
        { q = "A bus driver must carry out a pre-departure check. Which is NOT included?",
          a = {"Tyre pressures", "Passenger headcount", "Brake test", "Emergency exits"}, correct = 2 },
        { q = "When is it SAFE to use a handheld mobile phone while driving an HGV?",
          a = {"At traffic lights", "On a motorway below 30 mph", "Never while the vehicle is moving", "When parked and engine running"}, correct = 3 },
        { q = "What is the minimum air pressure required for HGV air brakes to operate?",
          a = {"40 psi", "60 psi", "80 psi", "100 psi"}, correct = 3 },
        { q = "How much rest must an HGV driver have in any 24-hour period?",
          a = {"8 hours", "9 hours", "10 hours", "11 hours"}, correct = 4 },
        { q = "A double-decker bus is approaching a narrow bridge. The driver should:",
          a = {"Accelerate through quickly", "Sound the horn and proceed", "Check clearance and be prepared to stop", "Flash headlights and continue"}, correct = 3 },
        { q = "The amber and red rear marker boards on an HGV indicate:",
          a = {"The vehicle is a hazmat carrier", "It's a long or wide load", "Night-time driving only", "A restricted speed vehicle"}, correct = 2 },
    },

    -- ── PLANE ─────────────────────────────────
    plane = {
        { q = "What does a METAR report provide?",
          a = {"Navigation instructions", "Current weather observations at an airfield", "Runway lighting status", "Air traffic control clearances"}, correct = 2 },
        { q = "The altimeter measures:",
          a = {"Airspeed", "Altitude above sea level", "Vertical speed", "Compass heading"}, correct = 2 },
        { q = "What does VFR stand for?",
          a = {"Variable Flight Rules", "Visual Flight Rules", "Verified Fuel Range", "Vertical Flight Rate"}, correct = 2 },
        { q = "A green steady light signal from ATC to a taxiing aircraft means:",
          a = {"Stop", "Cleared for take-off", "Cleared to taxi", "Proceed with caution"}, correct = 3 },
        { q = "What is the minimum visibility for VFR flight in Class G airspace below 3,000 ft?",
          a = {"1 km", "3 km", "5 km", "8 km"}, correct = 2 },
        { q = "What does a transponder squawk code of 7700 indicate?",
          a = {"Radio failure", "General emergency", "Hijack", "IFR flight"}, correct = 2 },
        { q = "When two aircraft are on a collision course, which aircraft has right of way?",
          a = {"The faster aircraft", "The aircraft to the left", "The aircraft to the right", "The higher aircraft"}, correct = 3 },
        { q = "What is a stall in an aircraft?",
          a = {"The engine stopping", "Loss of lift due to exceeding the critical angle of attack", "Running out of fuel", "Losing radio contact"}, correct = 2 },
        { q = "What does the VSI (Vertical Speed Indicator) show?",
          a = {"Ground speed", "Rate of climb or descent", "Altitude", "Bank angle"}, correct = 2 },
        { q = "Before every flight, a pilot must perform a:",
          a = {"Weight and balance check only", "Pre-flight inspection (walk-around check)", "Instrument calibration", "ATC briefing only"}, correct = 2 },
        { q = "The QNH altimeter setting gives altitude above:",
          a = {"The airfield", "Mean sea level", "The cloud base", "1,013 hPa datum"}, correct = 2 },
        { q = "Fuel tanks should be checked for water contamination by:",
          a = {"Smelling the fuel", "Draining a sample and checking for separation", "Checking the gauge only", "Looking at the tank colour"}, correct = 2 },
        { q = "What colour are the navigation lights on the RIGHT (starboard) wing?",
          a = {"Red", "White", "Green", "Blue"}, correct = 3 },
        { q = "A runway number of 27 indicates it aligns with approximately:",
          a = {"270° magnetic (west)", "27° magnetic", "27 km length", "27 mph landing speed"}, correct = 1 },
        { q = "What is hydroplaning on a runway?",
          a = {"Fuelling a seaplane", "The tyre riding on a film of water, reducing braking effectiveness", "Aquatic emergency landing", "Float-plane take-off technique"}, correct = 2 },
    },

    -- ── HELICOPTER ────────────────────────────
    helicopter = {
        { q = "What is the purpose of the tail rotor on a helicopter?",
          a = {"To provide lift", "To counteract torque from the main rotor and allow directional control", "To increase forward speed", "To stabilise altitude"}, correct = 2 },
        { q = "The collective pitch control on a helicopter:",
          a = {"Controls left/right movement", "Changes the pitch angle of all main rotor blades simultaneously", "Controls the tail rotor", "Adjusts engine throttle only"}, correct = 2 },
        { q = "What is 'vortex ring state' (VRS)?",
          a = {"High-speed forward flight mode", "A dangerous descent where the helicopter descends into its own downwash", "Rotor overspeed", "Engine icing condition"}, correct = 2 },
        { q = "Hovering in ground effect (HIGE) is easier than out of ground effect (HOGE) because:",
          a = {"Wind assists the rotor", "Ground reflects rotor wash, improving efficiency", "The engine produces more power", "The tail rotor disengages"}, correct = 2 },
        { q = "Autorotation allows a helicopter to:",
          a = {"Hover without engine power", "Land safely after engine failure using rotor inertia", "Fly inverted", "Gain altitude quickly"}, correct = 2 },
        { q = "The cyclic control moves the helicopter:",
          a = {"Up and down", "In any horizontal direction", "Yaw left and right", "Forward speed only"}, correct = 2 },
        { q = "What does 'LTE' (Loss of Tail Rotor Effectiveness) mean?",
          a = {"Tail rotor becomes more efficient", "Tail rotor loses authority, causing uncontrolled yaw", "Loss of engine torque", "Low fuel warning"}, correct = 2 },
        { q = "A helicopter's maximum gross weight limitation exists to ensure:",
          a = {"Passenger comfort", "Structural integrity and performance remain within safe limits", "Fuel economy", "Noise reduction"}, correct = 2 },
        { q = "Before starting a helicopter engine, a pilot checks the rotor area to ensure:",
          a = {"The rotor is warm", "No personnel or objects are in the rotor path", "The blades are horizontal", "Rotor speed is at minimum"}, correct = 2 },
        { q = "Retreating blade stall occurs at:",
          a = {"Low speeds", "High forward airspeeds when the retreating blade stalls", "During hover", "During auto-rotation"}, correct = 2 },
        { q = "What is the purpose of a HEMS (Helicopter Emergency Medical Service) landing site check?",
          a = {"To check the weather forecast", "To ensure the landing area is clear, firm and free from hazards", "To refuel the helicopter", "To log ATC clearance"}, correct = 2 },
        { q = "The 'dead man's curve' (height-velocity diagram) shows:",
          a = {"Altitudes unsafe to fly above", "Combinations of height and speed from which safe autorotation is not possible", "Speed limits near airports", "Fuel burn rates"}, correct = 2 },
        { q = "When landing a helicopter in a confined area, the approach is typically:",
          a = {"Fast and flat", "Steep and slow, to an out-of-ground-effect hover first", "At the same speed as fixed-wing", "From directly above"}, correct = 2 },
        { q = "Translational lift occurs when a helicopter:",
          a = {"Ascends vertically", "Transitions from hover to forward flight and enters clean airflow", "Enters autorotation", "Shuts down engines"}, correct = 2 },
        { q = "What does the rotor RPM gauge (tachometer) indicate?",
          a = {"Engine temperature", "Rotational speed of the main rotor", "Fuel flow", "Blade pitch angle"}, correct = 2 },
    },
}

-- ─────────────────────────────────────────────
--  PRACTICAL TEST WAYPOINTS
--  Each type has an ordered list of checkpoints
--  coords = vector3, label shown on screen
-- ─────────────────────────────────────────────
-- ─────────────────────────────────────────────
--  WAYPOINT CONDITIONS  (optional per waypoint)
--  These are checked while the player is inside
--  the proximity radius of a waypoint.
--
--  Per-waypoint conditions override the route defaults below.
--  Route defaults apply to all waypoints in that route
--  unless overridden at the waypoint level.
--
--  Available conditions:
--    minHeight      – minimum altitude (z) the vehicle must be at
--    maxHeight      – maximum altitude (z) the vehicle must be at
--    minSpeed       – minimum speed in mph the vehicle must be doing
--    maxSpeed       – maximum speed in mph (overrides route speedLimit for this wp)
--    mustBeLanded   – true = vehicle must be on/near ground (speed < 2, z within 5 of ground)
--    mustBeAirborne – true = vehicle must NOT be on the ground
--    heading        – required heading in degrees (±headingTolerance)
--    headingTolerance – degrees of tolerance for heading check (default 30)
--
--  All conditions are optional. Omit any you don't need.
-- ─────────────────────────────────────────────

Config.RouteConditionDefaults = {
    car     = {},  -- no extra conditions beyond speed limit
    bus_hgv = {},
    plane   = {
        minHeight = 50.0,   -- must be airborne after takeoff checkpoint
    },
    helicopter = {
        minHeight = 15.0,   -- must maintain some altitude during flight
    },
}

-- Per-waypoint condition overrides
-- These are added inside each waypoint table as a "conditions" key.
-- Example shown below — update Config.PracticalRoutes waypoints to include them:

Config.PracticalRoutes = {

    car = {
        spawnVehicle = "sultan",
        speedLimit   = 120,
        waypoints = {
            { coords = vector3(201.97, -1409.23, 28.66),  label = "Exit DMV onto Innocence Blvd, Keepig Right" },
            { coords = vector3(215.73, -1064.61, 28.6), label = "Go To legion square, Left onto Vespucci Blvd" },
            { coords = vector3(-90.14, -915.07, 28.63), label = "Continue on Vespucci Blvd, Left onto Alta Street" },
            { coords = vector3(-281.94, -1268.04, 29.44),  label = "Continue on Alta Street" },
            { coords = vector3(-148.99, -1521.24, 33.56), label = "Go onto Carson Avenue." },
            { coords = vector3(118.05, -1745.74, 28.27), label = "Continue on Carson Avenue." },
            { coords = vector3(406.82, -1728.35, 28.59), label = "Left onto Roy Lowenstein Blvd to Impound." },
            { coords = vector3(351.83, -1533.6, 28.69), label = "Continue on Innocence Blvd." },
            { coords = vector3(248.96, -1396.05, 29.9), label = "Return to DMV and Park in a space." },
        },
    },

    bus_hgv = {
        spawnVehicle = "packer",
        speedLimit   = 60,
        waypoints = {
            { coords = vector3(250.2, -926.42, 29.17), label = "Go Via Legion Square / Strawberry Avenue" },
            { coords = vector3(116.79, -1356.14, 29.34), label = "Go Via Innocence Blvd" },
            { coords = vector3(82.34, -1306.73, 29.36), label = "Go Via Elgin Avenue" },
            { coords = vector3(306.46, -1234.81, 38.33), label = "Take the Motorway" },
            { coords = vector3(775.63, -1238.94, 26.82), label = "Exit at Popular Street, Taking a Left" },
            { coords = vector3(782.17, -1034.0, 26.55), label = "Go Via Popular Street, Left onto: Vespucci Blvd" },
            { coords = vector3(406.59, -899.43, 30.53), label = "Go Via Sinner Street Back to Examiner" },
            { coords = vector3(444.65, -587.07, 28.59), label = "Return to Examiner" },

        },
    },
plane = {
    spawnVehicle = "velum",
    speedLimit   = nil,
    waypoints = {
        {
            coords = vector3(-928.94, -3341.11, 13.94),
            label  = "Taxi to Runway 30L – max speed 40 mph",
            conditions = {
                mustBeLanded = true,
                maxSpeed     = 50.0,
                minHeight    = false,
            },
        },
        {
            coords =vector3(-1407.44, -3102.9, 40.48),
            label  = "Take off from Runway 33L",
            conditions = {
                mustBeAirborne = true,
                minHeight      = 30.0,
                maxHeight      = 500.0,
            },
        },
        {
            coords = vector3(1760.0, 3240.0, 41.4),
            label  = "Low fly-past over Sandy Airfield – stay between 30 and 500 ft",
            conditions = {
                mustBeAirborne = true,
                minHeight      = 30.0,
                maxHeight      = 500.0,
            },
            timeout = 600,
        },
        {
            coords = vector3(-1550.0, -2580.22, 13.94),
            label  = "Land on Runway 21 at LSIA",
            conditions = {
                mustBeLanded = true,
                maxSpeed     = 70.0,
                minHeight    = false,
            },
            timeout = 600,
        },
        {
            coords = vector3(-1295.33, -2903.07, 13.95),
            label  = "Taxi to Devin Weston Hangar – max speed 40 mph",
            conditions = {
                mustBeLanded = true,
                maxSpeed     = 45.0,
                minHeight    = false,
            },
        },
        {
            coords = vector3(-1014.06, -2948.41, 13.95),
            label  = "Stop at Devin Weston Hangar and speak to the examiner",
            conditions = {
                mustBeLanded = true,
                maxSpeed     = 20.0,
                minHeight    = false,
            },
        },
    },
},
    helicopter = {
        spawnVehicle = "seasparrow",
        speedLimit   = nil,
        waypoints = {
            {
                coords = vector3(-742.0, -1447.0, 30.0),
                label  = "Checkpoint 1 – Lift off from helipad",
                conditions = {
                    mustBeAirborne = true,
                    minHeight      = 20.0,
                },
            },
            {
                coords = vector3(50.0, -745.0, 55.0),
                label  = "Checkpoint 2 – City helipad",
                conditions = {
                    minHeight = 30.0,
                    maxHeight = 200.0,
                },
            },
            {
                coords = vector3(318.0, -601.0, 45.0),
                label  = "Checkpoint 3 – Roof hover zone",
                conditions = {
                    minHeight = 40.0,
                    maxHeight = 100.0,
                    maxSpeed  = 20.0,   -- must be slow/hovering
                },
            },
            {
                coords = vector3(-742.38, -1447.01, 30.0),
                label  = "Return to Helipad – Land",
                conditions = {
                    mustBeLanded = true,
                    maxSpeed     = 10.0,
                },
            },
        },
    },
}
