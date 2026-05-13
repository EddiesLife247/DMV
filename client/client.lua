--[[
    eb_dmv – client.lua
]]

local currentLicenses  = {}
local spawnedPeds      = {}
local testActive       = false
local testVehicleNetId = nil
local currentTestType  = nil

-- ─────────────────────────────────────────────
--  UTILITIES
-- ─────────────────────────────────────────────
local function debugPrint(msg)
    if Config.Debug then print("[eb_dmv] " .. tostring(msg)) end
end

local function notify(msg, msgType)
    lib.notify({ title = "DMV", description = msg, type = msgType or "inform", duration = 6000 })
end

local function msToMph(ms) return ms * 2.23694 end

local theoryColMap = {
    car        = "theory_car",
    bus_hgv    = "theory_bus_hgv",
    plane      = "theory_plane",
    helicopter = "theory_helicopter",
}

-- ─────────────────────────────────────────────
--  SEATBELT STATE
-- ─────────────────────────────────────────────
local seatbeltOn = false

AddEventHandler("seatbelt:client:toggleSeatbelt", function(state)
    if Config.SeatbeltRequired and Config.SeatbeltCheckCustom == nil
    and Config.SeatbeltResource == "jim-mechanic" then
        seatbeltOn = state
        debugPrint("jim-mechanic seatbelt toggle: " .. tostring(state))
    end
end)

AddEventHandler("jg-hud:client:seatbeltUpdate", function(state)
    if Config.SeatbeltRequired and Config.SeatbeltCheckCustom == nil
    and Config.SeatbeltResource == "jg-hud" then
        seatbeltOn = state
        debugPrint("jg-hud seatbelt toggle: " .. tostring(state))
    end
end)

AddStateBagChangeHandler("seatbelt", ("player:%d"):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if Config.SeatbeltRequired and Config.SeatbeltCheckCustom == nil
    and Config.SeatbeltResource == "qbx_seatbelt" then
        seatbeltOn = value == true
        debugPrint("qbx_seatbelt statebag: " .. tostring(seatbeltOn))
    end
end)

local function checkSeatbelt()
    if not Config.SeatbeltRequired then
        seatbeltOn = true
        return
    end

    if Config.SeatbeltCheckCustom ~= nil then
        local ok, result = pcall(Config.SeatbeltCheckCustom)
        if ok then
            seatbeltOn = result == true
        else
            seatbeltOn = false
            debugPrint("SeatbeltCheckCustom error: " .. tostring(result))
        end
        return
    end

    if Config.SeatbeltResource == "native" then
        seatbeltOn = not GetPedConfigFlag(PlayerPedId(), 32, true)

    elseif Config.SeatbeltResource == "jim-mechanic" then
        local nativeBelt = not GetPedConfigFlag(PlayerPedId(), 32, true)
        if not seatbeltOn and nativeBelt then
            seatbeltOn = true
        end

    elseif Config.SeatbeltResource == "qbx_seatbelt" then
        seatbeltOn = LocalPlayer.state.seatbelt == true

    elseif Config.SeatbeltResource == "jg-hud" then
        -- fully event-driven, no poll available
    end
end

-- ─────────────────────────────────────────────
--  NET EVENTS FROM SERVER
-- ─────────────────────────────────────────────
RegisterNetEvent("eb_dmv:notify", function(msg, msgType)
    notify(msg, msgType)
end)

RegisterNetEvent("eb_dmv:chargeFailed", function(amount, stage)
    notify(Lang.charge_insufficient:format(amount, stage), "error")
end)

-- ─────────────────────────────────────────────
--  LOAD CURRENT LICENSES
-- ─────────────────────────────────────────────
local function loadLicenses()
    currentLicenses = lib.callback.await("eb_dmv:getLicenses", false) or {}
    debugPrint("Licenses loaded: " .. json.encode(currentLicenses))
end

AddEventHandler("QBX:PlayerLoaded", function()
    Wait(3000)
    loadLicenses()
end)

RegisterNetEvent("eb_dmv:licenseGranted", function(licenseType)
    currentLicenses[Config.LicenseMetaKeys[licenseType]] = 1
    local label = Lang.licenceLabels[licenseType] or licenseType
    notify(Lang.licence_granted:format(label), "success")
end)

-- ─────────────────────────────────────────────
--  PED SPAWNING + BLIPS
-- ─────────────────────────────────────────────
local function spawnExaminerPed(licenseType, data)
    lib.requestModel(data.model)

    local ped = CreatePed(4, GetHashKey(data.model),
        data.coords.x, data.coords.y, data.coords.z - 1.0,
        data.coords.w, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, data.blip.sprite)
    SetBlipColour(blip, data.blip.colour)
    SetBlipScale(blip, data.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.blip.label)
    EndTextCommandSetBlipName(blip)

    exports.ox_target:addLocalEntity(ped, {
        {
            name     = "dmv_examiner_" .. licenseType,
            label    = "Speak to " .. data.label,
            icon     = "fas fa-id-card",
            distance = 2.5,
            onSelect = function()
                openLicenseMenu(licenseType)
            end,
        }
    })

    spawnedPeds[licenseType] = ped
    debugPrint("Spawned examiner ped for: " .. licenseType)
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(1000) end
    Wait(3000)
    loadLicenses()
    for licType, data in pairs(Config.Examiners) do
        spawnExaminerPed(licType, data)
    end
end)

-- ─────────────────────────────────────────────
--  LICENSE MENU
-- ─────────────────────────────────────────────
function openLicenseMenu(licenseType)
    if testActive then
        notify(Lang.already_in_test, "error")
        return
    end

    local label      = Lang.licenceLabels[licenseType] or licenseType
    local metaKey    = Config.LicenseMetaKeys[licenseType]
    local hasLicense = currentLicenses[metaKey] == 1
    local theoryCol  = theoryColMap[licenseType]
    local theoryDone = currentLicenses[theoryCol] == 1

    local pendingType = currentLicenses["pending_result_type"]
    if pendingType == licenseType then
        deliverPendingResult(licenseType)
        return
    end

    local options = {}

    if hasLicense then
        table.insert(options, {
            title    = Lang.menu_already_holds,
            disabled = true,
        })
    elseif theoryDone or not Config.TheoryEnabled then
        local practicalCost = Config.Costs and Config.Costs[licenseType] and Config.Costs[licenseType].practical or 0
        local costStr       = practicalCost > 0
                              and Lang.menu_practical_cost:format(practicalCost)
                              or  Lang.menu_practical_free
        local desc          = not Config.TheoryEnabled
                              and (Lang.menu_practical_no_theory .. costStr)
                              or  (Lang.menu_practical_theory_done .. costStr)

        table.insert(options, {
            title       = Lang.menu_take_practical,
            description = desc,
            icon        = "fas fa-car",
            onSelect    = function()
                startPracticalTest(licenseType)
            end,
        })

        if theoryDone and Config.TheoryEnabled then
            table.insert(options, {
                title       = Lang.menu_theory_status_title,
                description = Lang.menu_theory_status_desc,
                disabled    = true,
            })
        end
    else
        if Config.TheoryEnabled then
            local theoryCost = Config.Costs and Config.Costs[licenseType] and Config.Costs[licenseType].theory or 0
            local costStr    = theoryCost > 0
                               and Lang.menu_practical_cost:format(theoryCost)
                               or  Lang.menu_practical_free
            table.insert(options, {
                title       = Lang.menu_take_theory,
                description = Lang.menu_theory_desc:format(Config.PassMark) .. costStr,
                icon        = "fas fa-book",
                onSelect    = function()
                    startTheoryTest(licenseType)
                end,
            })
        end
    end

    table.insert(options, {
        title       = Lang.menu_info_title,
        description = Lang.menu_info_desc:format(label),
        icon        = "fas fa-info-circle",
        onSelect    = function()
            showLicenseInfo(licenseType)
        end,
    })

    lib.registerContext({
        id      = "dmv_menu_" .. licenseType,
        title   = Lang.menu_title:format(label),
        options = options,
    })
    lib.showContext("dmv_menu_" .. licenseType)
end

-- ─────────────────────────────────────────────
--  DELIVER PENDING RESULT AT EXAMINER
-- ─────────────────────────────────────────────
function deliverPendingResult(licenseType)
    local result = lib.callback.await("eb_dmv:claimResult", false)
    if not result then return end

    if testVehicleNetId then
        TriggerServerEvent("eb_dmv:deleteTestVehicle", testVehicleNetId)
        testVehicleNetId = nil
    end

    loadLicenses()

    local label = Lang.licenceLabels[result.licenseType] or result.licenseType

    if result.passed then
        lib.alertDialog({
            header   = Lang.result_pass_header,
            content  = Lang.result_pass_body:format(label),
            centered = true,
            cancel   = false,
        })
    else
        lib.alertDialog({
            header   = Lang.result_fail_header,
            content  = Lang.result_fail_body:format(
                label,
                result.reason ~= "" and result.reason or Lang.result_fail_reason_default
            ),
            centered = true,
            cancel   = false,
        })
    end
end

-- ─────────────────────────────────────────────
--  INFORMATION DIALOGS
-- ─────────────────────────────────────────────
function showLicenseInfo(licenseType)
    lib.alertDialog({
        header   = Lang.licence_info_header,
        content  = Lang.licenceInfo[licenseType] or Lang.licence_info_none,
        centered = true,
        cancel   = false,
    })
end

-- ─────────────────────────────────────────────
--  THEORY TEST
-- ─────────────────────────────────────────────
function startTheoryTest(licenseType)
    local questions = Config.Questions[licenseType]
    if not questions then
        notify(Lang.player_data_not_found, "error")
        return
    end

    -- Eligibility check
    local eligibility = lib.callback.await("eb_dmv:checkTestEligibility", false, licenseType)
    if not eligibility or not eligibility.allowed then
        lib.alertDialog({
            header   = Lang.eligibility_header,
            content  = eligibility and eligibility.reason or Lang.eligibility_fallback,
            centered = true,
            cancel   = false,
        })
        return
    end

    -- Charge for theory
    local charged = lib.callback.await("eb_dmv:charge", false, licenseType, "theory")
    if not charged then return end

    local pool = {}
    for i, v in ipairs(questions) do pool[i] = v end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local score        = 0
    local total        = #pool
    local wrongAnswers = {}

    notify(Lang.theory_starting:format(total), "inform")
    Wait(1500)

    for idx, qData in ipairs(pool) do
        local opts = {}
        for i, ans in ipairs(qData.a) do
            opts[#opts + 1] = { value = tostring(i), label = ans }
        end

        local result = lib.inputDialog(Lang.theory_question_title:format(idx, total), {
            {
                type        = "select",
                label       = qData.q,
                options     = opts,
                required    = true,
                placeholder = Lang.theory_question_placeholder,
            },
        })

        if not result then
            notify(Lang.theory_cancelled, "error")
            return
        end

        local chosen = tonumber(result[1])
        if chosen == qData.correct then
            score = score + 1
        else
            wrongAnswers[#wrongAnswers + 1] = qData.q
        end
    end

    local passed    = score >= Config.PassMark
    local resultStr = passed and Lang.theory_result_passed or Lang.theory_result_failed
    local msg       = Lang.theory_result_body:format(score, total, resultStr)

    if not passed then
        msg = msg .. Lang.theory_result_need_more:format(Config.PassMark)
    end

    lib.alertDialog({
        header   = Lang.theory_result_header,
        content  = msg,
        centered = true,
        cancel   = false,
    })

    if passed then
        TriggerServerEvent("eb_dmv:saveTheoryPass", licenseType)
        currentLicenses[theoryColMap[licenseType]] = 1
        notify(Lang.theory_pass_notify, "success")
        Wait(2000)
        startPracticalTest(licenseType)
    else
        notify(Lang.theory_fail_notify:format(score, total), "error")
    end
end

-- ─────────────────────────────────────────────
--  WAYPOINT CONDITION CHECKER
-- ─────────────────────────────────────────────

local function checkWaypointConditions(vehicle, waypoint, routeDefaults)
    local cond = {}

    -- Apply route defaults first
    if routeDefaults then
        for k, v in pairs(routeDefaults) do cond[k] = v end
    end

    -- Waypoint conditions override — false explicitly cancels a route default
    if waypoint.conditions then
        for k, v in pairs(waypoint.conditions) do
            if v == false then
                cond[k] = nil  -- cancel the route default
            else
                cond[k] = v
            end
        end
    end

    if not next(cond) then return true, nil end

    local vehCoords = GetEntityCoords(vehicle)
    local speedMph  = msToMph(GetEntitySpeed(vehicle))
    local altitude  = vehCoords.z

    if cond.minHeight and altitude < cond.minHeight then
        return false, Lang.cond_min_height:format(cond.minHeight)
    end
    if cond.maxHeight and altitude > cond.maxHeight then
        return false, Lang.cond_max_height:format(cond.maxHeight)
    end
    if cond.minSpeed and speedMph < cond.minSpeed then
        return false, Lang.cond_min_speed:format(cond.minSpeed)
    end
    if cond.maxSpeed and speedMph > cond.maxSpeed then
        return false, Lang.cond_max_speed:format(cond.maxSpeed, speedMph)
    end
    if cond.mustBeLanded then
        local onGround = IsVehicleOnAllWheels(vehicle)
        if not onGround or speedMph > 5.0 then
            return false, Lang.cond_must_land
        end
    end
    if cond.mustBeAirborne then
        local onGround = IsVehicleOnAllWheels(vehicle)
        if onGround then
            return false, Lang.cond_must_airborne
        end
    end
    if cond.heading then
        local tolerance  = cond.headingTolerance or 30.0
        local vehHeading = GetEntityHeading(vehicle)
        local diff       = math.abs(vehHeading - cond.heading) % 360
        if diff > 180 then diff = 360 - diff end
        if diff > tolerance then
            return false, Lang.cond_heading:format(cond.heading, tolerance)
        end
    end

    return true, nil
end

-- ─────────────────────────────────────────────
--  PRACTICAL TEST
-- ─────────────────────────────────────────────
function startPracticalTest(licenseType)
    if testActive then return end

    local warnings    = 0
    local maxWarnings = Config.MaxWarnings or 3

    if not Config.PracticalEnabled then
        TriggerServerEvent("eb_dmv:grantLicense", licenseType)
        return
    end

    -- ─── WEATHER CHECK ────────────────────────
    if licenseType == "plane" or licenseType == "helicopter" then
        local badWeather = {
            THUNDER   = true,
            RAIN      = true,
            BLIZZARD  = true,
            SNOWLIGHT = true,
            FOGGY     = true,
        }

        local weather = GetNextWeatherTypeHashName()
        if not weather or weather == "" then
            weather = GetPrevWeatherTypeHashName()
        end
        weather = tostring(weather):upper()

        debugPrint("Weather check: " .. weather)

        if badWeather[weather] then
            lib.alertDialog({
                header   = Lang.weather_bad_header,
                content  = Lang.weather_bad_body:format(
                    weather, Lang.licenceLabels[licenseType] or licenseType),
                centered = true,
                cancel   = false,
            })
            return
        end
    end

    -- Eligibility check
    local eligibility = lib.callback.await("eb_dmv:checkTestEligibility", false, licenseType)
    if not eligibility or not eligibility.allowed then
        lib.alertDialog({
            header   = Lang.eligibility_header,
            content  = eligibility and eligibility.reason or Lang.eligibility_fallback,
            centered = true,
            cancel   = false,
        })
        testActive      = false
        currentTestType = nil
        return
    end

    -- Charge for practical
    local charged = lib.callback.await("eb_dmv:charge", false, licenseType, "practical")
    if not charged then return end

    testActive      = true
    currentTestType = licenseType

    local route      = Config.PracticalRoutes[licenseType]
    local timeout    = Config.WaypointTimeouts[licenseType]
    local isAir      = (licenseType == "plane" or licenseType == "helicopter")
    local speedLimit = route.speedLimit

    notify(Lang.practical_starting, "inform")
    Wait(2000)

    local netId, plate = lib.callback.await("eb_dmv:spawnTestVehicle", false, licenseType)
    if not netId then
        notify(Lang.practical_spawn_fail, "error")
        testActive      = false
        currentTestType = nil
        return
    end

    testVehicleNetId = netId
    local vehicle    = nil
    local attempts   = 0

    repeat
        vehicle  = NetworkGetEntityFromNetworkId(netId)
        Wait(200)
        attempts = attempts + 1
    until DoesEntityExist(vehicle) or attempts > 25

    if not DoesEntityExist(vehicle) then
        notify(Lang.practical_vehicle_fail, "error")
        testActive       = false
        currentTestType  = nil
        testVehicleNetId = nil
        return
    end

    SetVehicleNumberPlateText(vehicle, plate or "DMVTEST")
    SetEntityAsMissionEntity(vehicle, true, true)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    Wait(500)

    SetVehicleEngineOn(vehicle, false, true, true)
    Wait(200)

    seatbeltOn = false

    local seatbeltEnforced = false
    if Config.SeatbeltRequired then
        notify(Lang.practical_seatbelt_grace, "inform")
        CreateThread(function()
            Wait(30000)
            seatbeltEnforced = true
            debugPrint("Seatbelt enforcement active.")
        end)
    end

    local failed     = false
    local failReason = ""

    -- ── WAYPOINT LOOP ─────────────────────────
    local totalWaypoints = #route.waypoints
    local routeDefaults  = Config.RouteConditionDefaults and Config.RouteConditionDefaults[licenseType]

    for wpIdx, waypoint in ipairs(route.waypoints) do
        local isFinalWaypoint = (wpIdx == totalWaypoints)

        SetNewWaypoint(waypoint.coords.x, waypoint.coords.y)

        local timer = (waypoint.timeout or timeout) * 1000
        local reached      = false
        local lastSecsLeft = timeout
        local inZone       = false

        lib.showTextUI(
            (Lang.hud_waypoint .. "\n" .. Lang.hud_timer):format(waypoint.label, lastSecsLeft),
            { position = "top-center", icon = "fas fa-map-marker-alt" }
        )

        while timer > 0 and not reached do
            Wait(500)
            timer = timer - 500

            local secsLeft = math.ceil(timer / 1000)
            local ped      = PlayerPedId()

            if not IsPedInVehicle(ped, vehicle, false) then
                failed     = true
                failReason = Lang.fail_left_vehicle
                break
            end

if Config.SeatbeltRequired and seatbeltEnforced then
                checkSeatbelt()
                if not seatbeltOn then
                    warnings = warnings + 1
                    if warnings >= maxWarnings then
                        failed     = true
                        failReason = Lang.fail_seatbelt
                        break
                    else
                        notify(Lang.warn_seatbelt:format(maxWarnings - warnings), "error")
                        Wait(5000)
                    end
                end
            end

if speedLimit then
                local speedMph = msToMph(GetEntitySpeed(vehicle))
                if speedMph > speedLimit + 2 then
                    warnings = warnings + 1
                    if warnings >= maxWarnings then
                        failed     = true
                        failReason = Lang.fail_speed:format(speedLimit, speedMph)
                        break
                    else
                        notify(Lang.warn_speed:format(speedLimit, speedMph, maxWarnings - warnings), "error")
                        Wait(5000)  -- 5 second cooldown before next warning can trigger
                    end
                end
            end

            local pedCoords = GetEntityCoords(ped)
            local dist      = #(pedCoords - waypoint.coords)
            local checkDist = isAir and 80.0 or 20.0

            local hudLine1 = Lang.hud_waypoint:format(waypoint.label)
            local hudLine2 = Lang.hud_timer:format(secsLeft)
            local hudLine3 = nil

            if dist < checkDist then
                inZone = true

                if isFinalWaypoint then
                    break
                end

                local condOk, condReason = checkWaypointConditions(vehicle, waypoint, routeDefaults)

                if condOk then
                    reached = true
                else
                    hudLine3 = Lang.hud_condition_warning:format(condReason or Lang.fail_conditions)
                end
            end

            if secsLeft ~= lastSecsLeft or hudLine3 ~= nil then
                lastSecsLeft = secsLeft
                local hudText = hudLine1 .. "\n" .. hudLine2
                if hudLine3 then hudText = hudText .. "\n" .. hudLine3 end
                lib.showTextUI(hudText, { position = "top-center", icon = "fas fa-map-marker-alt" })
            end
        end

        -- ── FINAL WAYPOINT STOP SEQUENCE ──────
        if not failed and inZone and isFinalWaypoint then
            local stopped = false

            while timer > 0 and not stopped do
                Wait(300)
                timer = timer - 300

                local secsLeft2 = math.ceil(timer / 1000)
                local speed     = GetEntitySpeed(vehicle)
                local engineOn  = GetIsVehicleEngineRunning(vehicle)
                local ped2      = PlayerPedId()
                local inVeh     = IsPedInVehicle(ped2, vehicle, false)

                local statusLines = {}

                if inVeh then
                    table.insert(statusLines, speed >= 0.5 and Lang.hud_stop_needed or Lang.hud_stop_done)
                    table.insert(statusLines, engineOn and Lang.hud_engine_needed or Lang.hud_engine_done)
                    table.insert(statusLines, Lang.hud_exit_needed)
                else
                    if speed < 0.5 and not engineOn then
                        stopped = true
                    else
                        failed     = true
                        failReason = Lang.fail_exit_early
                        break
                    end
                end

                if not stopped and not failed then
                    local condOk, condReason = checkWaypointConditions(vehicle, waypoint, routeDefaults)
                    if not condOk then
                        table.insert(statusLines, Lang.hud_condition_warning:format(condReason or Lang.fail_conditions))
                    end
                end

                local hudText = (Lang.hud_final_title .. "\n" .. Lang.hud_final_timer .. "\n"):format(
                    waypoint.label, secsLeft2
                ) .. table.concat(statusLines, "\n")
                lib.showTextUI(hudText, { position = "top-center", icon = "fas fa-parking" })
            end

            lib.hideTextUI()

            if not failed then
                if stopped then
                    reached = true
                else
                    failed     = true
                    failReason = Lang.fail_no_stop
                end
            end
        else
            lib.hideTextUI()
        end

        if failed then break end

        if not reached then
            failed     = true
            failReason = Lang.fail_timeout:format(waypoint.label)
            break
        end

        if not isFinalWaypoint then
            notify(Lang.checkpoint_reached:format(wpIdx), "success")
            Wait(800)
        end
    end

    -- ── EXIT VEHICLE ──────────────────────────
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, vehicle, false) then
        if isAir then
            TaskLeaveVehicle(ped, vehicle, 0)
            Wait(2000)
            if IsPedInVehicle(ped, vehicle, false) then
                local vehCoords  = GetEntityCoords(vehicle)
                local vehHeading = GetEntityHeading(vehicle)
                local exitX      = vehCoords.x + math.sin(math.rad(-vehHeading)) * 4.0
                local exitY      = vehCoords.y + math.cos(math.rad(-vehHeading)) * 4.0
                SetEntityCoords(ped, exitX, exitY, vehCoords.z, false, false, false, false)
            end
        else
            TaskLeaveVehicle(ped, vehicle, 0)
            Wait(1500)
        end
    end

    ClearGpsPlayerWaypoint()
    currentTestType = nil
    testActive      = false

    if failed and (failReason == nil or failReason == "") then
        failed     = false
        failReason = ""
    end

TriggerServerEvent("eb_dmv:savePracticalResult", licenseType, not failed, failReason)
    currentLicenses["pending_result_type"] = licenseType

    if failed then
        notify(Lang.practical_complete_fail, "inform")
        -- Don't delete vehicle — player drives back to examiner to collect result
        CreateThread(function()
            Wait(300000)  -- 5 minute cleanup in case they abandon
            if testVehicleNetId then
                TriggerServerEvent("eb_dmv:deleteTestVehicle", testVehicleNetId)
                testVehicleNetId = nil
            end
        end)
    else
        notify(Lang.practical_complete_pass, "success")
    end
end

-- ─────────────────────────────────────────────
--  SPEED HUD during ground vehicle tests
-- ─────────────────────────────────────────────
CreateThread(function()
    while true do
        if testActive and testVehicleNetId and currentTestType then
            local route = Config.PracticalRoutes[currentTestType]
            if route and route.speedLimit then
                local vehicle = NetworkGetEntityFromNetworkId(testVehicleNetId)
                if DoesEntityExist(vehicle) and IsPedInVehicle(PlayerPedId(), vehicle, false) then
                    local speedMph = msToMph(GetEntitySpeed(vehicle))
                    if speedMph > route.speedLimit then
                        SetTextFont(4)
                        SetTextScale(0.45, 0.45)
                        SetTextColour(255, 80, 80, 255)
                        SetTextEntry("STRING")
                        AddTextComponentString(Lang.hud_speed_over:format(speedMph, route.speedLimit))
                        DrawText(0.5, 0.02)
                        Wait(0)
                    else
                        Wait(200)
                    end
                else
                    Wait(500)
                end
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

-- ─────────────────────────────────────────────
--  CLEANUP on resource stop
-- ─────────────────────────────────────────────
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    if testVehicleNetId then
        TriggerServerEvent("eb_dmv:deleteTestVehicle", testVehicleNetId)
    end
    lib.hideTextUI()
end)