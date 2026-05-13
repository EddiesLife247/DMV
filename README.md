# DMV - RP DMV Licence System

**Author:** EddiesLife247
**Framework:** QBX Core + ox_lib + ox_target + oxmysql

---

## Features

- 4 licence types: Car, Bus/HGV, Fixed-Wing Pilot, Helicopter
- 15-question theory test per licence (randomised, pass mark configurable)
- Practical test with GPS-guided multi-waypoint routes and per-checkpoint timers
- Per-waypoint conditions (min/max height, speed, airborne, landed, heading)
- Speed enforcement on car and HGV practicals
- Seatbelt enforcement during practicals (supports jim-mechanic, jg-hud, qbx_seatbelt, native)
- Theory pass persisted to DB — survives disconnects
- Practical result delivered by the examiner on return
- Police can suspend licences and block tests for players with active warrants (tk_mdt)
- ox_target examiner peds at 4 locations with map blips
- QBX metadata sync so other resources (tk_mdt etc.) can read licence status
- oxmysql — table auto-created on first server start
- Configurable costs per licence type and stage
- Theory and/or practical can be disabled per server
- Admin command to grant theory/practical/both to any player
- Full lang.lua for easy translation

---

## Dependencies

| Resource             | Required |
|----------------------|----------|
| qbx_core             | ✅        |
| ox_lib               | ✅        |
| ox_target            | ✅        |
| oxmysql              | ✅        |
| Renewed-Vehiclekeys  | ✅ (or qbx_vehiclekeys — see config) |
| tk_mdt               | Optional (warrant check) |

---

## Installation

### 1. Add the resource

Drop the `DMV` folder into your resources directory and add to `server.cfg`:

```
ensure eb_dmv
```

Ensure it loads after its dependencies:

```
ensure qbx_core
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure Renewed-Vehiclekeys
ensure eb_dmv
```

### 2. Database

The `eb_dmv_licenses` table is created automatically on first start. A manual reference copy is included in `eb_dmv.sql`.

### 3. QBX Core — add licence metadata defaults

Open `qbx_core/server/player.lua` and find the `playerData.metadata.licences` block inside `CheckPlayerData`. Replace it with:

```lua
playerData.metadata.licences = playerData.metadata.licences or {
    id                = true,
    weapon            = false,
    licensecar        = false,
    licensebushgv     = false,
    licenseplane      = false,
    licensehelicopter = false,
}
```

This ensures new characters have the correct licence keys in their metadata from creation, and allows resources like tk_mdt to read them correctly.

### 4. server.cfg — ACE permissions

```
# DMV admin command (/dmvgrant)
add_ace group.admin eb_dmv.admin allow

# Police suspension commands (/dmvsuspend, /dmvunsuspend)
add_ace group.police eb_dmv.police allow
```

---

## Configuration (`shared/config.lua`)

| Key | Description |
|-----|-------------|
| `Config.Debug` | Print debug messages to console |
| `Config.PassMark` | Minimum correct answers to pass theory (default 12/15) |
| `Config.WaypointTimeouts` | Seconds per waypoint per licence type |
| `Config.LicenseMetaKeys` | DB column names per licence type |
| `Config.MetadataLicenseKeys` | QBX metadata.licences keys per licence type |
| `Config.Costs` | Theory and practical cost per licence type (set to 0 for free) |
| `Config.TheoryEnabled` | Set false to skip theory and go straight to practical |
| `Config.PracticalEnabled` | Set false to grant licence on theory pass alone |
| `Config.VehicleKeysResource` | `"Renewed-Vehiclekeys"` or `"qbx_vehiclekeys"` |
| `Config.SeatbeltRequired` | Whether seatbelt must be worn during practical |
| `Config.SeatbeltResource` | `"jim-mechanic"`, `"jg-hud"`, `"qbx_seatbelt"`, or `"native"` |
| `Config.SeatbeltCheckCustom` | Optional function override for seatbelt check (never escrowed) |
| `Config.DenyOnWarrant` | Block tests if player has active warrant in tk_mdt |
| `Config.SuspensionEnabled` | Enable police licence suspension system |
| `Config.AdminCommand` | Command name for admin grant (default `dmvgrant`) |
| `Config.SuspendCommand` | Command name for suspension (default `dmvsuspend`) |
| `Config.UnsuspendCommand` | Command name for unsuspend (default `dmvunsuspend`) |
| `Config.Examiners` | Ped model, coords, blip settings per licence type |
| `Config.Questions` | 15 theory questions per licence type |
| `Config.PracticalRoutes` | Spawn vehicle, speed limit, waypoints per licence type |
| `Config.RouteConditionDefaults` | Default waypoint conditions applied to all waypoints in a route |
| `Config.Licenses` | tk_mdt licence label map |

### Waypoint Conditions

Each waypoint in `Config.PracticalRoutes` can have an optional `conditions` table:

```lua
conditions = {
    minHeight        = 50.0,   -- minimum altitude (z)
    maxHeight        = 500.0,  -- maximum altitude (z)
    minSpeed         = 10.0,   -- minimum speed in mph
    maxSpeed         = 30.0,   -- maximum speed in mph
    mustBeLanded     = true,   -- vehicle must be on the ground
    mustBeAirborne   = true,   -- vehicle must not be on the ground
    heading          = 270.0,  -- required heading in degrees
    headingTolerance = 30.0,   -- tolerance in degrees (default 30)
}
```

Conditions are checked once the player enters the waypoint radius. The HUD shows what still needs to be met. The waypoint is not marked as reached until all conditions pass.

---

## Commands

| Command | Permission | Usage |
|---------|------------|-------|
| `/dmvgrant` | `eb_dmv.admin` | `/dmvgrant <playerid> <car\|bus_hgv\|plane\|helicopter> <theory\|practical\|both>` |
| `/dmvsuspend` | `eb_dmv.police` | `/dmvsuspend <playerid> <type> <minutes> [reason]` |
| `/dmvunsuspend` | `eb_dmv.police` | `/dmvunsuspend <playerid> <type>` |

All commands work from the server console (source 0) as well as in-game.

---

## Checking Licences from Other Resources

**Server-side (direct DB query):**
```lua
local result = MySQL.query.await(
    "SELECT * FROM eb_dmv_licenses WHERE citizenid = ?",
    { citizenid }
)
if result and result[1] and (result[1].licensecar == 1 or result[1].licensecar == true) then
    -- Player has a car licence
end
```

**Via QBX metadata (for tk_mdt and other resources):**
```lua
local player = exports.qbx_core:GetPlayer(source)
if player.PlayerData.metadata.licences.licensecar then
    -- Player has a car licence
end
```

**Client-side callback:**
```lua
local licenses = lib.callback.await("eb_dmv:getLicenses", false)
if licenses.licensecar == 1 or licenses.licensecar == true then
    -- Player has a car licence
end
```

> Note: oxmysql returns `TINYINT(1)` columns as booleans in Lua, so always check for both `== 1` and `== true`.

---

## Practical Test Flow

```
Player approaches examiner ped → ox_target interaction
    → Licence menu opens
        → Theory test (15 randomised questions)
            → Pass (≥ pass mark): theory saved to DB, proceed to practical
            → Fail: must retake theory (charge applies each attempt)
        → Practical test
            → Test vehicle spawned, engine off
            → 30 second seatbelt grace period (if enabled)
            → GPS waypoints shown one at a time with countdown timer
            → Waypoint conditions checked on entry (height, speed, etc.)
            → Final waypoint: must stop, engine off, exit vehicle
            → Result saved to DB
        → Return to examiner to collect result
            → Pass: licence granted, QBX metadata updated
            → Fail: theory cleared, must restart from theory
```

---

## File Structure

```
DMV/
├── fxmanifest.lua
├── eb_dmv.sql
├── shared/
│   ├── config.lua
│   └── lang.lua
├── server/
│   └── server.lua
└── client/
    └── client.lua
```