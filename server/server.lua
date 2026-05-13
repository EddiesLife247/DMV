--[[
    eb_dmv – server.lua
]]

local QBX = exports.qbx_core

-- ─────────────────────────────────────────────
--  DATABASE
-- ─────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `eb_dmv_licenses` (
            `citizenid`              VARCHAR(50)  NOT NULL,
            `licensecar`             TINYINT(1)   DEFAULT 0,
            `licensebushgv`          TINYINT(1)   DEFAULT 0,
            `licenseplane`           TINYINT(1)   DEFAULT 0,
            `licensehelicopter`      TINYINT(1)   DEFAULT 0,
            `theory_car`             TINYINT(1)   DEFAULT 0,
            `theory_bus_hgv`         TINYINT(1)   DEFAULT 0,
            `theory_plane`           TINYINT(1)   DEFAULT 0,
            `theory_helicopter`      TINYINT(1)   DEFAULT 0,
            `pending_result_type`    VARCHAR(20)  DEFAULT NULL,
            `pending_result_pass`    TINYINT(1)   DEFAULT NULL,
            `pending_result_reason`  VARCHAR(255) DEFAULT NULL,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local cols = {
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `theory_car`            TINYINT(1)   DEFAULT 0",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `theory_bus_hgv`        TINYINT(1)   DEFAULT 0",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `theory_plane`          TINYINT(1)   DEFAULT 0",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `theory_helicopter`     TINYINT(1)   DEFAULT 0",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `pending_result_type`   VARCHAR(20)  DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `pending_result_pass`   TINYINT(1)   DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `pending_result_reason` VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_car`             BIGINT DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_bus_hgv`         BIGINT DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_plane`           BIGINT DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_helicopter`      BIGINT DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_reason_car`      VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_reason_bus_hgv`  VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_reason_plane`    VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE eb_dmv_licenses ADD COLUMN IF NOT EXISTS `suspend_reason_helicopter` VARCHAR(255) DEFAULT NULL",
    }
    
    for _, sql in ipairs(cols) do MySQL.query(sql) end

    if Config.Debug then print("[eb_dmv] Table ensured.") end
end)

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────
local theoryColMap = {
    car        = "theory_car",
    bus_hgv    = "theory_bus_hgv",
    plane      = "theory_plane",
    helicopter = "theory_helicopter",
}

local function getCitizenId(source)
    local player = QBX:GetPlayer(source)
    if player then return player.PlayerData.citizenid end
    return nil
end

local function ensureRow(citizenid)
    MySQL.query("INSERT IGNORE INTO eb_dmv_licenses (citizenid) VALUES (?)", { citizenid })
end

local suspendColMap = {
    car        = "suspend_car",
    bus_hgv    = "suspend_bus_hgv",
    plane      = "suspend_plane",
    helicopter = "suspend_helicopter",
}

local suspendReasonColMap = {
    car        = "suspend_reason_car",
    bus_hgv    = "suspend_reason_bus_hgv",
    plane      = "suspend_reason_plane",
    helicopter = "suspend_reason_helicopter",
}

-- ─────────────────────────────────────────────
--  CHECK suspension + warrant before test
-- ─────────────────────────────────────────────
lib.callback.register("eb_dmv:checkTestEligibility", function(source, licenseType)
    local cid = getCitizenId(source)
    if not cid then return { allowed = false, reason = "Player data not found." } end

    ensureRow(cid)

    -- Suspension check
    if Config.SuspensionEnabled then
        local suspCol       = suspendColMap[licenseType]
        local suspReasonCol = suspendReasonColMap[licenseType]
        if suspCol then
            local result = MySQL.query.await(
                "SELECT `" .. suspCol .. "`, `" .. suspReasonCol .. "` FROM eb_dmv_licenses WHERE citizenid = ?",
                { cid }
            )
            if result and result[1] then
                local suspUntil = result[1][suspCol]
                if suspUntil and suspUntil > os.time() then
                    local remaining = suspUntil - os.time()
                    local mins      = math.ceil(remaining / 60)
                    local reason    = result[1][suspReasonCol] or "No reason given"
                    return {
                        allowed = false,
                        reason  = ("Your %s licence is suspended for %d more minute(s).\nReason: %s"):format(
                            licenseType, mins, reason)
                    }
                elseif suspUntil and suspUntil <= os.time() then
                    -- Expired — clear it
                    MySQL.query(
                        "UPDATE eb_dmv_licenses SET `" .. suspCol .. "` = NULL, `" .. suspReasonCol .. "` = NULL WHERE citizenid = ?",
                        { cid }
                    )
                end
            end
        end
    end

    -- Warrant check
    if Config.DenyOnWarrant then
        local player = QBX:GetPlayer(source)
        if player then
            local identifier = player.PlayerData.license or player.PlayerData.citizenid
            local ok, hasWarrant = pcall(function()
                return exports.tk_mdt:doesPlayerHaveWarrant(identifier)
            end)
            if ok and hasWarrant then
                return {
                    allowed = false,
                    reason  = Lang.eligibility_warrant
                }
            end
        end
    end


    return { allowed = true, reason = "" }
end)

-- ─────────────────────────────────────────────
--  SUSPEND COMMAND  /dmvsuspend <id> <type> <minutes> [reason]
--  Requires ace: eb_dmv.police
-- ─────────────────────────────────────────────
-- ─────────────────────────────────────────────
--  PERMISSION HELPERS
-- ─────────────────────────────────────────────
local function hasAdminPermission(source)
    if source == 0 then return true end  -- console always allowed
    if IsPlayerAceAllowed(source, Config.AdminAce) then return true end
    if Config.UseJobPermissions and Config.AdminJobs then
        local player = QBX:GetPlayer(source)
        if player then
            local job = player.PlayerData.job.name:lower()
            for _, j in ipairs(Config.AdminJobs) do
                if job == j:lower() then return true end
            end
        end
    end
    return false
end

local function hasPolicePermission(source)
    if source == 0 then return true end  -- console always allowed
    if IsPlayerAceAllowed(source, Config.PoliceAce) then return true end
    if Config.UseJobPermissions and Config.PoliceJobs then
        local player = QBX:GetPlayer(source)
        if player then
            local job = player.PlayerData.job.name:lower()
            for _, j in ipairs(Config.PoliceJobs) do
                if job == j:lower() then return true end
            end
        end
    end
    return false
end

RegisterCommand(Config.SuspendCommand, function(source, args)
    if not hasPolicePermission(source) then
        TriggerClientEvent("eb_dmv:notify", source, Lang.admin_no_permission, "error")
        return
    end


    local targetId  = tonumber(args[1])
    local licType   = args[2]
    local minutes   = tonumber(args[3])
    local reason    = args[4] and table.concat(args, " ", 4) or "Suspended by officer"

    local usage = "Usage: /" .. Config.SuspendCommand .. " <playerid> <car|bus_hgv|plane|helicopter> <minutes> [reason]"

    if not targetId or not licType or not minutes then
        if source == 0 then print(usage) else TriggerClientEvent("eb_dmv:notify", source, usage, "error") end
        return
    end

    local validTypes = { car = true, bus_hgv = true, plane = true, helicopter = true }
    if not validTypes[licType] then
        local msg = "Invalid licence type."
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    local cid = getCitizenId(targetId)
    if not cid then
        local msg = "Player " .. targetId .. " not found."
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    ensureRow(cid)

    local suspUntil = os.time() + (minutes * 60)
    local suspCol   = suspendColMap[licType]
    local reasonCol = suspendReasonColMap[licType]

    MySQL.query(
        "UPDATE eb_dmv_licenses SET `" .. suspCol .. "` = ?, `" .. reasonCol .. "` = ? WHERE citizenid = ?",
        { suspUntil, reason, cid }
    )

    TriggerClientEvent("eb_dmv:notify", targetId,
        ("Your %s licence has been suspended for %d minute(s).\nReason: %s"):format(licType, minutes, reason),
        "error")

    local adminName = source == 0 and "Console" or GetPlayerName(source)
    local msg = ("[%s] Suspended %s licence for player %d (%s) for %d mins. Reason: %s"):format(
        adminName, licType, targetId, cid, minutes, reason)
    print("[eb_dmv] " .. msg)
    if source > 0 then
        TriggerClientEvent("eb_dmv:notify", source,
            ("Suspended %s licence for player %d for %d minute(s)."):format(licType, targetId, minutes), "success")
    end
end, false)

-- ─────────────────────────────────────────────
--  UNSUSPEND COMMAND  /dmvunsuspend <id> <type>
--  Requires ace: eb_dmv.police
-- ─────────────────────────────────────────────
RegisterCommand(Config.UnsuspendCommand, function(source, args)
    if not hasPolicePermission(source) then
        TriggerClientEvent("eb_dmv:notify", source, Lang.admin_no_permission, "error")
        return
    end

    local targetId = tonumber(args[1])
    local licType  = args[2]

    local usage = "Usage: /" .. Config.UnsuspendCommand .. " <playerid> <car|bus_hgv|plane|helicopter>"
    if not targetId or not licType then
        if source == 0 then print(usage) else TriggerClientEvent("eb_dmv:notify", source, usage, "error") end
        return
    end

    local validTypes = { car = true, bus_hgv = true, plane = true, helicopter = true }
    if not validTypes[licType] then
        local msg = "Invalid licence type."
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    local cid = getCitizenId(targetId)
    if not cid then
        local msg = "Player " .. targetId .. " not found."
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    local suspCol   = suspendColMap[licType]
    local reasonCol = suspendReasonColMap[licType]

    MySQL.query(
        "UPDATE eb_dmv_licenses SET `" .. suspCol .. "` = NULL, `" .. reasonCol .. "` = NULL WHERE citizenid = ?",
        { cid }
    )

    TriggerClientEvent("eb_dmv:notify", targetId,
        ("Your %s licence suspension has been lifted."):format(licType), "success")

    if source > 0 then
        TriggerClientEvent("eb_dmv:notify", source,
            ("Suspension lifted for player %d (%s licence)."):format(targetId, licType), "success")
    end
    print(("[eb_dmv] Suspension lifted: %s licence for %s"):format(licType, cid))
end, false)

-- ─────────────────────────────────────────────
--  SYNC licence to QBX metadata.licences
-- ─────────────────────────────────────────────
local function syncMetadataLicense(source, licenseType)
    local metaKey = Config.LicenseMetaKeys[licenseType]
    if not metaKey then return end

    local player = QBX:GetPlayer(source)
    if not player then return end

    local licences = player.PlayerData.metadata.licences or {}
    licences[metaKey] = true
    player.Functions.SetMetaData("licences", licences)

    if Config.Debug then
        print(("[eb_dmv] Synced metadata licence '%s' for source %d"):format(metaKey, source))
    end
end

-- ─────────────────────────────────────────────
--  VEHICLE KEYS HELPER
-- ─────────────────────────────────────────────
local function giveKeys(source, plate)
    if Config.VehicleKeysResource == "Renewed-Vehiclekeys" then
        exports['Renewed-Vehiclekeys']:addKey(source, plate)
    elseif Config.VehicleKeysResource == "qbx_vehiclekeys" then
        exports['qbx_vehiclekeys']:GiveKeys(source, plate)
    end
end

local function removeKeys(source, plate)
    if Config.VehicleKeysResource == "Renewed-Vehiclekeys" then
        exports['Renewed-Vehiclekeys']:removeKey(source, plate)
    elseif Config.VehicleKeysResource == "qbx_vehiclekeys" then
        exports['qbx_vehiclekeys']:RemoveKeys(source, plate)
    end
end

-- ─────────────────────────────────────────────
--  FETCH licenses
-- ─────────────────────────────────────────────
lib.callback.register("eb_dmv:getLicenses", function(source)
    local cid = getCitizenId(source)
    if not cid then return {} end
    ensureRow(cid)
    local result = MySQL.query.await("SELECT * FROM eb_dmv_licenses WHERE citizenid = ?", { cid })
    if result and result[1] then return result[1] end
    return {}
end)

-- ─────────────────────────────────────────────
--  CHARGE PLAYER
-- ─────────────────────────────────────────────
lib.callback.register("eb_dmv:charge", function(source, licenseType, stage)
    local costs = Config.Costs and Config.Costs[licenseType]
    if not costs then return true end

    local amount = stage == "theory" and costs.theory or costs.practical
    if not amount or amount <= 0 then return true end

    local player = QBX:GetPlayer(source)
    if not player then return false end

    local cash = player.PlayerData.money["cash"] or 0
    if cash < amount then
        TriggerClientEvent("eb_dmv:chargeFailed", source, amount, stage)
        return false
    end

    player.Functions.RemoveMoney("cash", amount, "dmv-" .. stage .. "-" .. licenseType)
    if Config.Debug then
        print(("[eb_dmv] Charged $%d (%s %s) from %s"):format(amount, stage, licenseType, source))
    end
    return true
end)

-- ─────────────────────────────────────────────
--  SAVE theory pass
-- ─────────────────────────────────────────────
RegisterNetEvent("eb_dmv:saveTheoryPass", function(licenseType)
    local source = source
    local cid    = getCitizenId(source)
    if not cid then return end

    local col = theoryColMap[licenseType]
    if not col then return end

    ensureRow(cid)
    MySQL.query("UPDATE eb_dmv_licenses SET `" .. col .. "` = 1 WHERE citizenid = ?", { cid })
    if Config.Debug then print("[eb_dmv] Theory pass saved: " .. col .. " → " .. cid) end
end)

-- ─────────────────────────────────────────────
--  SAVE practical result
-- ─────────────────────────────────────────────
RegisterNetEvent("eb_dmv:savePracticalResult", function(licenseType, passed, reason)
    local source = source
    local cid    = getCitizenId(source)
    if not cid then return end

    ensureRow(cid)
    MySQL.query(
        "UPDATE eb_dmv_licenses SET pending_result_type = ?, pending_result_pass = ?, pending_result_reason = ? WHERE citizenid = ?",
        { licenseType, passed and 1 or 0, reason or "", cid }
    )
    if Config.Debug then
        print(("[eb_dmv] Pending result saved: %s %s → %s"):format(licenseType, passed and "PASS" or "FAIL", cid))
    end
end)

-- ─────────────────────────────────────────────
--  CLAIM result + grant if passed
-- ─────────────────────────────────────────────
lib.callback.register("eb_dmv:claimResult", function(source)
    local cid = getCitizenId(source)
    if not cid then return nil end

    local result = MySQL.query.await("SELECT * FROM eb_dmv_licenses WHERE citizenid = ?", { cid })
    if not result or not result[1] then return nil end

    local row = result[1]
    if row.pending_result_type == nil then return nil end

    local licenseType = row.pending_result_type
    local passed      = row.pending_result_pass == 1 or row.pending_result_pass == true
    local reason      = row.pending_result_reason

    MySQL.query(
        "UPDATE eb_dmv_licenses SET pending_result_type = NULL, pending_result_pass = NULL, pending_result_reason = NULL WHERE citizenid = ?",
        { cid }
    )

    if passed then
        local licCol    = Config.LicenseMetaKeys[licenseType]
        local theoryCol = theoryColMap[licenseType]
        if licCol then
            MySQL.query(
                "UPDATE eb_dmv_licenses SET `" .. licCol .. "` = 1, `" .. theoryCol .. "` = 0 WHERE citizenid = ?",
                { cid }
            )
        end
        TriggerClientEvent("eb_dmv:licenseGranted", source, licenseType)
        syncMetadataLicense(source, licenseType)
    else
        local theoryCol = theoryColMap[licenseType]
        if theoryCol then
            MySQL.query(
                "UPDATE eb_dmv_licenses SET `" .. theoryCol .. "` = 0 WHERE citizenid = ?",
                { cid }
            )
        end
    end

    return { licenseType = licenseType, passed = passed, reason = reason }
end)

-- ─────────────────────────────────────────────
--  GRANT license (direct)
-- ─────────────────────────────────────────────
RegisterNetEvent("eb_dmv:grantLicense", function(licenseType)
    local source = source
    local cid    = getCitizenId(source)
    if not cid then return end

    local col = Config.LicenseMetaKeys[licenseType]
    if not col then
        print("[eb_dmv] Unknown licenseType: " .. tostring(licenseType))
        return
    end

    ensureRow(cid)
    MySQL.query("UPDATE eb_dmv_licenses SET `" .. col .. "` = 1 WHERE citizenid = ?", { cid })
    syncMetadataLicense(source, licenseType)
    TriggerClientEvent("eb_dmv:licenseGranted", source, licenseType)
    if Config.Debug then print("[eb_dmv] License granted: " .. col .. " → " .. cid) end
end)

-- ─────────────────────────────────────────────
--  SPAWN test vehicle
-- ─────────────────────────────────────────────
lib.callback.register("eb_dmv:spawnTestVehicle", function(source, licenseType)
    local route = Config.PracticalRoutes[licenseType]
    if not route then return nil end

    local ped     = GetPlayerPed(source)
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehHash = GetHashKey(route.spawnVehicle)
    local spawnX  = coords.x + math.sin(math.rad(-heading)) * 5.0
    local spawnY  = coords.y + math.cos(math.rad(-heading)) * 5.0

    local vehicle = CreateVehicle(vehHash, spawnX, spawnY, coords.z, heading, true, false)

    local timeout = 2000
    while not DoesEntityExist(vehicle) and timeout > 0 do
        Wait(50)
        timeout = timeout - 50
    end

    if not DoesEntityExist(vehicle) then return nil end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = "DMVTEST"

    giveKeys(source, plate)

    if Config.Debug then print("[eb_dmv] Spawned vehicle netId: " .. netId) end

    return netId, plate
end)

-- ─────────────────────────────────────────────
--  DELETE test vehicle
-- ─────────────────────────────────────────────
RegisterNetEvent("eb_dmv:deleteTestVehicle", function(netId)
    local source  = source
    removeKeys(source, "DMVTEST")
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end)

-- ─────────────────────────────────────────────
--  ADMIN COMMAND  /dmvgrant <id> <type> <stage>
--  Requires ace: eb_dmv.admin
--  stage: theory | practical | both
-- ─────────────────────────────────────────────
RegisterCommand(Config.AdminCommand, function(source, args)
    if not hasAdminPermission(source) then
        TriggerClientEvent("eb_dmv:notify", source, Lang.admin_no_permission, "error")
        return
    end


    local targetId = tonumber(args[1])
    local licType  = args[2]
    local stage    = args[3]

    local usage = "Usage: /" .. Config.AdminCommand .. " <playerid> <car|bus_hgv|plane|helicopter> <theory|practical|both>"

    if not targetId or not licType or not stage then
        if source == 0 then print(usage) else TriggerClientEvent("eb_dmv:notify", source, usage, "error") end
        return
    end

    local validTypes  = { car = true, bus_hgv = true, plane = true, helicopter = true }
    local validStages = { theory = true, practical = true, both = true }

    if not validTypes[licType] then
        local msg = "Invalid licence type. Use: car, bus_hgv, plane, helicopter"
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    if not validStages[stage] then
        local msg = "Invalid stage. Use: theory, practical, both"
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    local cid = getCitizenId(targetId)
    if not cid then
        local msg = "Player " .. targetId .. " not found or not loaded."
        if source == 0 then print(msg) else TriggerClientEvent("eb_dmv:notify", source, msg, "error") end
        return
    end

    ensureRow(cid)

    if stage == "theory" or stage == "both" then
        local theoryCol = theoryColMap[licType]
        MySQL.query("UPDATE eb_dmv_licenses SET `" .. theoryCol .. "` = 1 WHERE citizenid = ?", { cid })
        TriggerClientEvent("eb_dmv:notify", targetId,
            "An admin has granted you a theory pass for: " .. licType, "success")
        print("[eb_dmv] Admin granted theory: " .. licType .. " → " .. cid)
    end

    if stage == "practical" or stage == "both" then
        local licCol = Config.LicenseMetaKeys[licType]
        MySQL.query("UPDATE eb_dmv_licenses SET `" .. licCol .. "` = 1 WHERE citizenid = ?", { cid })
        syncMetadataLicense(targetId, licType)
        TriggerClientEvent("eb_dmv:licenseGranted", targetId, licType)
        print("[eb_dmv] Admin granted licence: " .. licType .. " → " .. cid)
    end

    local adminName = source == 0 and "Console" or GetPlayerName(source)
    local msg = ("[%s] Granted %s/%s to player %d (%s)"):format(adminName, stage, licType, targetId, cid)
    print("[eb_dmv] " .. msg)
    if source > 0 then
        TriggerClientEvent("eb_dmv:notify", source,
            ("Granted %s %s to player %d"):format(stage, licType, targetId), "success")
    end

end, false)