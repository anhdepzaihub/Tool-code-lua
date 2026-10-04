--[[
╔══════════════════════════════════════════════════════════════╗
║            ▓▓▓  AɴнDᴇᴘZᴀı SCRIPT V3  ▓▓▓                     ║
║              HCR2 Cheat Menu (All Versions)                  ║
║                                                              ║
║    📢 Discord  :: Andepzai                                   ║
║    📢 Telegram :: @Andepzai                                  ║
║    📢 Youtube  :: @Andepzai                                  ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
--  BIẾN TOÀN CỤC
-- ═══════════════════════════════════════════════════════════
local ShowPrint = [[
╔══════════════════════════════════════════════════════════════╗
║            ▓▓▓  AɴнDᴇᴘZᴀı SCRIPT V3  ▓▓▓                     ║
║                  Thanks for using!                           ║
║                                                              ║
║    📢 Discord  :: Andepzai                                   ║
║    📢 Telegram :: @Andepzai                                  ║
║    📢 Youtube  :: @Andepzai                                  ║
╚══════════════════════════════════════════════════════════════╝
]]

local LIB_BASE = nil
local archType = 0
local currentRange = nil
local RANGE_VALUE = nil
local gameVersion = nil
local BaseGameStatus = nil
local BaseGameStatusRaw = nil
local BaseRegion = nil

-- ═══════════════════════════════════════════════════════════
--  KIỂM TRA BAN ĐẦU
-- ═══════════════════════════════════════════════════════════
local blockedApps = {
    "com.gushi.gtpcanary", "com.packagesniffer.frtparlak",
    "com.rhmsoft.edit", "app.greyshirts.sslcapture",
    "frtparlak.rootsniffer", "com.minhui.wifianalyzer",
    "io.neoterm", "com.foxcyber.gg", "sstool.only.com.sstool"
}

local function checkBlocked()
    gg.setVisible(false)
    for _, pkg in ipairs(blockedApps) do
        if gg.isPackageInstalled(pkg) then
            gg.alert("⛔ Detected forbidden app!\n\n📦 " .. pkg)
            os.exit()
        end
    end
end

local function checkGG()
    gg.setVisible(false)
    local ok = pcall(function() gg.require("101.1", 16142) end)
    if not ok then
        gg.alert("❌ Please use original Game Guardian 101.1!")
        os.exit()
    end
end

local function checkHCR2()
    gg.setVisible(false)
    if gg.getTargetPackage() ~= "com.fingersoft.hcr2" then
        gg.alert("❗ Please select HCR2 on top of Game Guardian!")
        os.exit()
    end
end

local function getHCR2Version()
    local info = gg.getTargetInfo()
    if info and info.versionName then return tostring(info.versionName) end
    return "Unknown"
end

local function detectArch()
    local info = gg.getTargetInfo()
    local libDir = info.nativeLibraryDir:lower()
    if libDir:find("arm64") or libDir:find("aarch64") then return 1
    elseif libDir:find("armeabi") or libDir:find("v7a") then return 2
    elseif libDir:find("x86_64") then return 3
    elseif libDir:find("x86") then return 4 end
    return 0
end

local function getLib()
    local libs = gg.getRangesList("libcocos2dcpp.so")
    if #libs == 0 then
        local c = gg.choice({"⏩ Continue", "❌ Exit"}, nil, "❗ Couldn't find libcocos2dcpp.so!")
        if c ~= 1 then os.exit() end
        return false
    end
    LIB_BASE = libs[1].start
    return true
end

local function selectRange()
    gg.setVisible(false)
    local ranges = {
        { name = "C alloc", value = gg.REGION_C_ALLOC },
        { name = "C data",  value = gg.REGION_C_DATA },
        { name = "Other",   value = gg.REGION_OTHER }
    }
    local labels = {}
    for _, r in ipairs(ranges) do table.insert(labels, r.name) end

    local pick = gg.choice(labels, 0, "🧭 Chọn vùng nhớ (khuyến nghị C alloc)")
    if not pick then os.exit() end

    if pick ~= 1 then
        gg.alert("⚠️ Range này có thể không hoạt động tốt!\nVui lòng dùng C alloc.")
    end

    RANGE_VALUE = ranges[pick].value
    currentRange = ranges[pick].name
    gg.setRanges(RANGE_VALUE)
    gg.toast("✅ Range: " .. currentRange)
    gg.sleep(500)
end

-- ═══════════════════════════════════════════════════════════
--  TÌM GAMESTATUS
-- ═══════════════════════════════════════════════════════════
local function findGameStatus()
    local SEARCH_REGIONS = { gg.REGION_C_ALLOC, gg.REGION_OTHER }
    for _, region in ipairs(SEARCH_REGIONS) do
        gg.clearResults()
        gg.setRanges(region)
        gg.searchNumber("h 73 74 61 72 74 75 70 5F 63 6F 75 6E 74", gg.TYPE_BYTE)
        gg.refineNumber("h 73", gg.TYPE_BYTE)
        local scan_results = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        for _, d in ipairs(scan_results) do
            local ptr = gg.getValues({{ address = d.address + 0x1F, flags = gg.TYPE_QWORD }})[1]
            if ptr and ptr.value and ptr.value >= 0x10000 and ptr.value < 0x7FFFFFFFFFFF then
                local ver = gg.getValues({{ address = ptr.value + 0x10, flags = gg.TYPE_DWORD }})[1]
                local v = ver and tonumber(ver.value)
                if v == 65792 or v == 65793 or v == 16843008 or v == 16843009 then
                    local tp = gg.getValues({{ address = ptr.value + 0x80, flags = gg.TYPE_QWORD }})[1]
                    if tp and tp.value and tp.value ~= 0 then
                        local td = gg.getValues({{ address = tp.value, flags = gg.TYPE_DWORD }})[1]
                        if td and td.value and td.value ~= 0 then
                            BaseRegion = region
                            BaseGameStatusRaw = ver.address
                            BaseGameStatus = td.address
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
--  HELPER
-- ═══════════════════════════════════════════════════════════
local function readStringAt(addr, maxLen)
    maxLen = maxLen or 64
    local reads = {}
    for i = 0, maxLen - 1 do
        reads[#reads + 1] = { address = addr + i, flags = gg.TYPE_BYTE }
    end
    local result = gg.getValues(reads)
    local bytes = {}
    for _, v in ipairs(result) do
        if v.value == 0 then break end
        local b = v.value < 0 and v.value + 256 or v.value
        bytes[#bytes + 1] = string.char(b)
    end
    return table.concat(bytes)
end

local PART_CAPS = {
    ["_magnet"] = 15, ["_heavyweight"] = 15, ["_glide"] = 15,
    ["_rollcage"] = 15, ["_air_control"] = 15, ["_winter_tyres"] = 15,
    ["_start_boost"] = 10, ["_jump"] = 10, ["_wheelie_boost"] = 10,
    ["_fume_boost"] = 10, ["_flip_speed_boost"] = 10,
    ["_afterburner"] = 7, ["_turbo_boost"] = 7, ["_spoiler"] = 7,
    ["_perfect_landing_boost"] = 7,
    ["_thrusters"] = 4, ["_nitro"] = 4, ["_fuel_boost"] = 4, ["_coin_boost"] = 4,
}

local function partMaxLevel(name)
    name = tostring(name or "")
    for suffix, cap in pairs(PART_CAPS) do
        if name:find(suffix .. "$") then return cap end
    end
    return 3
end

local function checkGameStatus()
    if not BaseGameStatus or BaseGameStatus == 0 then
        gg.alert("❌ Chưa scan được GameStatus!\n\n💡 Vào Garage (bấm 1 xe) rồi chạy lại script.")
        return false
    end
    return true
end

local VERSION_OFFSETS = {
    ["1.74"] = { freezeDiamond = 0x21CC3F4, vnpStats = 0x1FBE5A0 },
    ["1.75"] = { freezeDiamond = 0x22049C4, vnpStats = 0x2060CA0 },
}
local function getOffsets()
    local v = gameVersion and gameVersion:match("^(%d+%.%d+)")
    return VERSION_OFFSETS[v] or VERSION_OFFSETS["1.75"]
end

-- ═══════════════════════════════════════════════════════════
--  HACK CƠ BẢN
-- ═══════════════════════════════════════════════════════════
local noScrapState = false
local function upgradeWithoutScrap()
    local choice = gg.choice({
        "🟢 Bật Upgrade Without Scrap",
        "🔴 Tắt Upgrade Without Scrap",
        "⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (noScrapState and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return MainMenu() end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(RANGE_VALUE)
        gg.searchNumber("2139095039D;-0.6F::17", gg.TYPE_FLOAT)
        gg.refineNumber("-0.6", gg.TYPE_FLOAT)
        local res = gg.getResults(gg.getResultsCount())
        if #res == 0 then
            gg.alert("❌ Không tìm thấy! Vào garage trước.")
            return
        end
        gg.editAll("-999", gg.TYPE_FLOAT)
        gg.clearResults()
        noScrapState = true
        gg.alert("✅ Đã bật!")
    elseif choice == 2 then
        if not noScrapState then
            gg.alert("❌ Chưa bật!")
            return
        end
        gg.clearResults()
        gg.setRanges(RANGE_VALUE)
        gg.searchNumber("2139095039D;-999F::17", gg.TYPE_FLOAT)
        gg.refineNumber("-999", gg.TYPE_FLOAT)
        local res = gg.getResults(gg.getResultsCount())
        if #res > 0 then
            gg.editAll("-0.60000002384", gg.TYPE_FLOAT)
            noScrapState = false
            gg.alert("❌ Đã tắt!")
        end
    end
end

-- FLY HACK
local flyState = false
local function flyHack()
    local choice = gg.choice({
        "🟢 Bật Fly Hack",
        "🔴 Tắt Fly Hack",
        "⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (flyState and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return MainMenu() end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(gg.REGION_C_BSS)
        for _, v in ipairs({"-0.75", "-0.55", "-0.25", "-0.15"}) do
            gg.searchNumber(v, gg.TYPE_FLOAT)
            gg.getResults(2)
            gg.editAll("0.08", gg.TYPE_FLOAT)
            gg.clearResults()
        end
        gg.searchNumber("0.08", gg.TYPE_FLOAT)
        local res = gg.getResults(2)
        if #res > 0 then
            gg.editAll("-1.2", gg.TYPE_FLOAT)
            flyState = true
            gg.alert("✅ Đã bật!")
        else
            gg.alert("❌ Không tìm thấy!")
        end
        gg.setRanges(RANGE_VALUE)
    elseif choice == 2 then
        if not flyState then
            gg.alert("❌ Chưa bật!")
            return
        end
        gg.clearResults()
        gg.setRanges(gg.REGION_C_BSS)
        gg.searchNumber("-1.2", gg.TYPE_FLOAT)
        local res = gg.getResults(2)
        if #res > 0 then
            gg.editAll("0.08", gg.TYPE_FLOAT)
            flyState = false
            gg.alert("❌ Đã tắt!")
        end
        gg.setRanges(RANGE_VALUE)
    end
end

-- UNLOCK VEHICLE
local VEHICLES = {
    "HILL CLIMBER", "HILL CLIMBER Mk2", "MOTOCROSS BIKE", "MONSTER TRUCK",
    "TRACTOR", "DUNE BUGGY", "SPORTS CAR", "MOTOCROSS BIKE 2",
    "RALLY CAR", "TANK", "SNOWMOBILE", "SUPER DIESEL", "SUPER SPORTS CAR",
    "RACING TRUCK", "MOTORCYCLE", "SUPER OFFROAD", "SUPERBIKE",
    "TRICYCLE", "BEACH BUGGY", "LOWRIDER", "BUS", "HOT ROD",
    "SPORTS CAR Mk2", "FORMULA", "MUSCLE CAR", "TOURING CAR",
    "CC-EV", "BOB SLAYER", "RAIDER", "ROTATOR", "GLIDER",
    "SPORTSBIKE", "SKELETON", "MOTORCYCLE 2", "ROCKET BIKE",
    "SUPER RALLY", "SPORTS CAR 3", "HOVERBIKE", "BEAST", "SCORPION"
}

local function unlockVehicleByName(name)
    if not name or name == "" then return false end
    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. name, gg.TYPE_BYTE)
    local getRes = gg.getResults(gg.getResultsCount())
    if #getRes == 0 then return false end
    local tbl = {}
    for _, v in ipairs(getRes) do
        table.insert(tbl, { address = v.address + 0xEF, flags = gg.TYPE_DWORD })
    end
    gg.clearResults()
    gg.loadResults(tbl)
    gg.refineNumber("1~5", gg.TYPE_DWORD)
    local unlocked = gg.getResults(gg.getResultsCount())
    if #unlocked == 0 then return false end
    gg.editAll("1", gg.TYPE_DWORD)
    local edits = {}
    for _, v in ipairs(unlocked) do
        table.insert(edits, { address = v.address + 0x38, flags = gg.TYPE_DWORD, value = 0 })
        for i = 1, 13 do
            table.insert(edits, { address = v.address + (i * 4), flags = gg.TYPE_DWORD, value = 0 })
        end
    end
    gg.setValues(edits)
    gg.clearResults()
    return true
end

local function unlockAnyVehicle()
    local menu = {}
    for _, v in ipairs(VEHICLES) do
        table.insert(menu, "🚗 " .. v)
    end
    table.insert(menu, "⬅️ Quay lại")

    local pick = gg.multiChoice(menu, nil, "☑️ Chọn nhiều xe để mở khóa")
    if not pick then return MainMenu() end

    local count = 0
    for i, selected in pairs(pick) do
        if selected and i <= #VEHICLES then
            if unlockVehicleByName(VEHICLES[i]) then
                count = count + 1
            end
        end
    end

    if count > 0 then
        gg.alert("✅ Đã mở khóa " .. count .. " xe!")
    else
        gg.alert("❌ Không mở khóa được xe nào!")
    end
end

-- TRACKS EDITOR
local function tracksEditor()
    local input = gg.prompt({
        "🗺️ Tên Map (VD: Countryside):",
        "📏 Độ dài hiện tại (m):",
        "📐 Độ dài mới (m):",
        "✅ Enable Verify"
    }, {"", "", "", true}, {"text", "number", "number", "checkbox"})

    if not input then return MainMenu() end

    local mapName   = input[1]
    local curLength = tonumber(input[2])
    local newLength = tonumber(input[3])
    local doVerify  = input[4]

    if not mapName or mapName == "" or not curLength or not newLength then
        gg.alert("❌ Nhập thiếu thông tin!")
        return
    end

    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. mapName, gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        gg.alert("❌ Không tìm thấy map: " .. mapName)
        return
    end

    gg.refineNumber(string.byte(mapName:sub(1, 1)), gg.TYPE_BYTE)
    local results = gg.getResults(30)
    if #results == 0 then
        gg.alert("⚠️ Refine thất bại!")
        return
    end

    local patched = 0
    for _, r in ipairs(results) do
        gg.clearResults()
        gg.searchNumber(r.address - 1, 32)
        local ptrs = gg.getResults(100)
        for _, p in ipairs(ptrs) do
            local lengthAddr = p.address + 0x20
            local verifyAddr = p.address + 0x34
            local curVal = gg.getValues({{ address = lengthAddr, flags = gg.TYPE_DWORD }})[1].value
            if curVal == curLength then
                gg.setValues({{ address = lengthAddr, flags = gg.TYPE_DWORD, value = newLength }})
                if doVerify then
                    gg.setValues({{ address = verifyAddr, flags = gg.TYPE_DWORD, value = 1 }})
                end
                patched = patched + 1
            end
        end
    end

    if patched > 0 then
        gg.alert("✅ Đã patch " .. patched .. " entries!")
    else
        gg.alert("❌ Không match!")
    end
end

-- ═══════════════════════════════════════════════════════════
--  VEHICLE HACKS
-- ═══════════════════════════════════════════════════════════
local VehicleHacks = {
    f1  = { name = "Lowrider - Super Jumpshocks", search = 'Q 00 00 A0 "A" 00 80 40 66 66 06 41', replace = 'Q 00 00 A0 "A" 00 80 "@" 00 C8 41', state = false, results = nil },
    f2  = { name = "Hot Rod - Boost Hack", search = "4620693218774745088", replace = "4620693218877722624", state = false, results = nil },
    f3  = { name = "CC-EV - Super Boost", search = 'Q 00 00 A0 "A" 00 08 "A" 00 48 41', replace = 'Q 00 00 A0 "A" 00 08 "A" 00 C8 42', state = false, results = nil },
    f4  = { name = "Glider - Infinite Propeller", search = 'Q 00 00 A0 "A" 00 C0 "?" 00 40 40', replace = 'Q 00 00 A0 "A" 00 C0 3F 28 6B EE 4E', state = false, results = nil },
    f5  = { name = "Muscle Car - Engine Hack", search = '20f;34f;44f:9', refine = '44', replace = '220', state = false, results = nil },
    f6  = { name = "Glider - Infinite Wing", search = 'Q 00 00 A0 "A" 00 A0 "@" 00 20 41', replace = 'Q 00 00 A0 "A" 00 A0 40 66 7F E2 4E', state = false, results = nil },
    f7  = { name = "Muscle Car - Super Burn-Out", search = 'Q 00 00 A0 "A" 00 60 "@" 00 D0 40', replace = 'Q 00 00 A0 "A" 00 60 "@" 00 FA 43', state = false, results = nil },
    f8  = { name = "Rally Car - Grip Hack", search = '0.8;1.2:5', refine = '1.2', replace = '999', state = false, results = nil },
    f9  = { name = "Formula - Super Grip", search = 'Q 00 00 A0 41 CD CC CC ">" 00 C0 3F', replace = 'Q 00 00 A0 41 CD CC CC ">" 00 70 41', state = false, results = nil },
    f10 = { name = "Supercar - Super Air Brake", search = 'Q 00 00 A0 "A" 00 A0 C0 00 00 A0 C1', replace = 'Q 00 00 A0 "A" 00 A0 C0 00 00 C8 C2', state = false, results = nil },
    f11 = { name = "Supercar - Reverse Air Brake", search = 'Q 00 00 A0 "A" 00 A0 C0 00 00 A0 C1', replace = 'Q 00 00 A0 "A" 00 A0 C0 00 00 8C 42', state = false, results = nil },
    f12 = { name = "Rally Car - Engine Hack", search = '10;25:5', refine = '25', replace = '999', state = false, results = nil },
    f13 = { name = "Muscle Car - Downforce + Fuel", search = '43.0;1.27999997139;2.0;0.69999998808;25.0:49', refine = '43', replace = '1000', state = false, results = nil }
}

local function toggleVehicleHack(key)
    local data = VehicleHacks[key]
    if not data then return end

    local choice = gg.choice({
        "🟢 BẬT",
        "🔴 TẮT",
        "⬅️ Quay lại"
    }, nil, "🔧 " .. data.name .. "\nTrạng thái: " .. (data.state and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return end

    local vType = gg.TYPE_FLOAT
    local s = tostring(data.search)
    if s:sub(1,2) == "Q " then vType = gg.TYPE_BYTE
    elseif s:find(";") then vType = gg.TYPE_FLOAT
    elseif not s:find("%.") then
        if #s > 10 then vType = gg.TYPE_QWORD else vType = gg.TYPE_DWORD end
    end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(RANGE_VALUE)
        gg.searchNumber(data.search, vType)
        if data.refine and gg.getResultsCount() > 0 then
            gg.refineNumber(data.refine, vType)
        end
        local count = gg.getResultsCount()
        if count == 0 then
            gg.alert("❌ Không tìm thấy! Vào xe này trước.")
        else
            local results = gg.getResults(count)
            data.results = gg.getValues(results)
            gg.editAll(data.replace, vType)
            data.state = true
            gg.clearResults()
            gg.toast("✅ Đã bật: " .. data.name)
        end
    elseif choice == 2 then
        if data.results then
            gg.setValues(data.results)
            data.state = false
            gg.toast("❌ Đã tắt: " .. data.name)
        else
            gg.alert("❌ Chưa bật!")
        end
    end
end

local function vehicleHacksMenu()
    local keys = {}
    local labels = {}
    local n = 1
    for k in pairs(VehicleHacks) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tonumber(a:match("%d+")) < tonumber(b:match("%d+")) end)

    for _, k in ipairs(keys) do
        local v = VehicleHacks[k]
        local st = v.state and "🟢" or "⚫"
        table.insert(labels, st .. " " .. n .. ". " .. v.name)
        n = n + 1
    end
    table.insert(labels, "⬅️ Quay lại")

    local pick = gg.choice(labels, nil, nil)
    if not pick or pick == #labels then return MainMenu() end

    toggleVehicleHack(keys[pick])
    return vehicleHacksMenu()
end

-- ═══════════════════════════════════════════════════════════
--  SHOP / CHEST
-- ═══════════════════════════════════════════════════════════
local freeChestsFound = false
local freeChestsOriginal = {}
local function freeChests()
    local choice = gg.choice({
        "🟢 Bật Free Chests",
        "🔴 Tắt Free Chests",
        "⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (freeChestsFound and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return MainMenu() end

    if choice == 1 then
        if not freeChestsFound then
            gg.clearResults()
            gg.setRanges(gg.REGION_C_DATA)
            gg.searchNumber("0.1", gg.TYPE_FLOAT)
            local count = gg.getResultCount()
            if count == 0 then
                gg.alert("❌ Không tìm thấy!")
                gg.setRanges(RANGE_VALUE)
                return
            end
            local res = gg.getResults(count)
            freeChestsOriginal = gg.getValues(res)
            local newVals = {}
            for i, v in ipairs(res) do
                newVals[i] = { address = v.address, flags = v.flags, value = "0" }
            end
            gg.setValues(newVals)
            freeChestsFound = true
            gg.setRanges(RANGE_VALUE)
            gg.alert("✅ Đã bật!")
        else
            gg.toast("✅ Đã bật rồi!")
        end
    elseif choice == 2 then
        if freeChestsFound and #freeChestsOriginal > 0 then
            gg.setValues(freeChestsOriginal)
            freeChestsFound = false
            gg.setRanges(RANGE_VALUE)
            gg.alert("❌ Đã tắt!")
        else
            gg.alert("❌ Chưa bật!")
        end
    end
end

local function freePurchases()
    local c = gg.choice({
        "▶️ TIẾP TỤC",
        "⬅️ Quay lại"
    }, nil, "⚠️ Cần kết nối Google Play!\nĐang ở Shop của game?")

    if c ~= 1 then return MainMenu() end

    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber("7,234,820", gg.TYPE_DWORD)
    local results = gg.getResults(100)
    if #results == 0 then
        gg.alert("❌ Không tìm thấy! Vào Shop trước.")
        return
    end

    for _, v in ipairs(results) do
        gg.clearResults()
        gg.searchNumber(v.address, gg.TYPE_QWORD)
        local ptrs = gg.getResults(100)
        for _, vv in ipairs(ptrs) do
            local val = gg.getValues({{ address = vv.address + 0x18, flags = 4 }})[1].value
            if val > 0 and val < 100 then
                local edits = {}
                for off = 0x18, 0x2C, 4 do
                    table.insert(edits, { address = vv.address + off, flags = 4, value = 0 })
                end
                gg.setValues(edits)
            end
        end
    end
    gg.alert("✅ Đã bật Free Purchases!")
end

local function partsDropLegendary()
    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber("1000;9::5", gg.TYPE_DWORD)
    gg.refineNumber("9", gg.TYPE_DWORD)
    gg.getResults(gg.getResultsCount())
    gg.editAll(7, gg.TYPE_DWORD)

    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber("1;1;1;1;60;0;1036831949::25", gg.TYPE_DWORD)
    gg.refineNumber("60", gg.TYPE_DWORD)

    if gg.getResultCount() == 0 then
        gg.alert("❌ Không tìm thấy!")
        return
    end

    local results = gg.getResults(1)
    local baseAddr = results[1].address
    local scanTbl = {}
    for i = -32, 32 do
        table.insert(scanTbl, { address = baseAddr + (i * 4), flags = gg.TYPE_DWORD })
    end
    local values = gg.getValues(scanTbl)
    local final = {}
    for _, v in ipairs(values) do
        if v.value >= 1 and v.value <= 50 then
            v.value = 9999
            table.insert(final, v)
        end
    end

    if #final > 0 then
        gg.setValues(final)
        gg.clearResults()
        gg.alert("✅ Đã bật!\nMở Legendary Chest!")
    else
        gg.alert("❌ Không có giá trị hợp lệ!")
    end
end

-- ═══════════════════════════════════════════════════════════
--  ADVENTURE
-- ═══════════════════════════════════════════════════════════
local advChestV1Found = false
local advChestV1Results = nil
local advChestV1Original = nil
local function advChestHackV1()
    local choice = gg.choice({
        "🟢 Bật Rising Chest Levels",
        "🔴 Tắt Rising Chest Levels",
        "⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (advChestV1Found and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return MainMenu() end

    if choice == 1 then
        if not advChestV1Found then
            gg.clearResults()
            gg.setRanges(RANGE_VALUE)
            gg.searchNumber("500;500::5", gg.TYPE_DWORD)
            local count = gg.getResultsCount()
            if count == 0 then
                gg.alert("❌ Không tìm thấy!")
                return
            end
            advChestV1Results = gg.getResults(count)
            advChestV1Original = gg.getValues(advChestV1Results)
            local edits = {}
            for i, v in ipairs(advChestV1Results) do
                edits[i] = { address = v.address, flags = v.flags, value = -1 }
            end
            gg.setValues(edits)
            advChestV1Found = true
            gg.alert("✅ Đã bật!")
        else
            gg.alert("✅ Đã bật rồi!")
        end
    elseif choice == 2 then
        if advChestV1Found then
            gg.setRanges(RANGE_VALUE)
            gg.setValues(advChestV1Original)
            advChestV1Found = false
            gg.alert("❌ Đã tắt!")
        else
            gg.alert("❌ Chưa bật!")
        end
    end
end

local function flatGroundAdventure()
    local choice = gg.choice({
        "1. Adventure Maps (General)",
        "2. City",
        "3. Forest",
        "4. Winter",
        "5. Savanna",
        "6. Beach",
        "7. Gloomvale",
        "⬅️ Quay lại"
    }, nil, "➖ Flat Ground for Adventure")

    if not choice or choice == 8 then return MainMenu() end

    local function toggle(search, enableVal, disableVal, ranges)
        gg.clearResults()
        if ranges then gg.setRanges(ranges) else gg.setRanges(RANGE_VALUE) end
        gg.searchNumber(search, gg.TYPE_DWORD)
        local res = gg.getResults(gg.getResultsCount())
        if #res == 0 then
            gg.alert("❌ Không tìm thấy!")
            return
        end
        local val = gg.choice({"✅ Enable", "❌ Disable"}, nil, "Toggle Flat Ground")
        if val == 1 then
            gg.editAll(enableVal, gg.TYPE_DWORD)
            gg.alert("✅ Đã bật!")
        elseif val == 2 then
            gg.editAll(disableVal, gg.TYPE_DWORD)
            gg.alert("❌ Đã tắt!")
        end
        gg.setRanges(RANGE_VALUE)
    end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(gg.REGION_C_DATA)
        gg.searchNumber("0.7", gg.TYPE_FLOAT)
        local res = gg.getResults(gg.getResultsCount())
        if #res == 0 then
            gg.alert("❌ Không tìm thấy!")
            gg.setRanges(RANGE_VALUE)
            return
        end
        local opt = gg.choice({"✅ Enable", "❌ Disable"}, nil, "Flat Ground General")
        if opt == 1 then
            gg.editAll(9999, gg.TYPE_FLOAT)
            gg.alert("✅ Đã bật!")
        elseif opt == 2 then
            gg.editAll(0.7, gg.TYPE_FLOAT)
            gg.alert("❌ Đã tắt!")
        end
        gg.setRanges(RANGE_VALUE)
    elseif choice == 2 then toggle("1123132079", 1206423683, 1123132079, gg.REGION_C_ALLOC | gg.REGION_C_DATA | gg.REGION_C_BSS)
    elseif choice == 3 then toggle("1109006215", 1223132079, 1109006215, gg.REGION_C_ALLOC | gg.REGION_C_BSS)
    elseif choice == 4 then toggle("1120232603", 1197191296, 1120232603, gg.REGION_C_ALLOC | gg.REGION_C_DATA | gg.REGION_C_BSS)
    elseif choice == 5 then toggle("1116330252", 1148436480, 1116330252, gg.REGION_C_ALLOC | gg.REGION_C_DATA | gg.REGION_C_BSS)
    elseif choice == 6 then toggle("1125450835", 1142292480, 1125450835, gg.REGION_C_ALLOC | gg.REGION_C_DATA | gg.REGION_C_BSS)
    elseif choice == 7 then toggle("1113060784", 1144750080, 1113060784, RANGE_VALUE)
    end
end

-- ═══════════════════════════════════════════════════════════
--  AUTO WIN + DEBUG MODE
-- ═══════════════════════════════════════════════════════════
local autoWinApplied = {}
local autoWinState = false
local AUTOWIN_OFFSET = 0x000000

local function autoWin()
    if archType == 3 or archType == 4 then
        gg.alert("❗ Auto Win chỉ hoạt động trên ARMV8!")
        return
    end
    local choice = gg.choice({
        "🟢 Bật Auto Win",
        "🔴 Tắt Auto Win",
        "⬅️ Quay lại"
    }, nil, "Auto Win (ARMV8) — Trạng thái: " .. (autoWinState and "🟢 ON" or "🔴 OFF"))

    if not choice or choice == 3 then return MainMenu() end
    if AUTOWIN_OFFSET == 0x000000 then
        gg.alert("⚠️ Auto Win offset chưa cấu hình!")
        return
    end
    local addr = LIB_BASE + AUTOWIN_OFFSET
    if autoWinApplied[addr] == nil then
        local cur = gg.getValues({{ address = addr, flags = gg.TYPE_DWORD }})
        if cur and cur[1] then autoWinApplied[addr] = cur[1].value end
    end
    if choice == 1 then
        gg.setValues({{ address = addr, flags = gg.TYPE_DWORD, value = "1r" }})
        autoWinState = true
        gg.alert("✅ Đã bật!")
    elseif choice == 2 then
        if autoWinApplied[addr] then
            gg.setValues({{ address = addr, flags = gg.TYPE_DWORD, value = autoWinApplied[addr] }})
            autoWinApplied[addr] = nil
            autoWinState = false
            gg.alert("❌ Đã tắt!")
        end
    end
end

local function debugMode()
    local choice = gg.choice({
        "🟢 Bật Debug Mode",
        "🔴 Tắt Debug Mode",
        "⬅️ Quay lại"
    }, nil, "💎 Play Hidden Maps")

    if not choice or choice == 3 then return MainMenu() end

    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_DATA)
    gg.searchNumber("h 24 64 65 62 75 67 5F 6D 6F 64 65 5F 65 6E 61 62 6C 65 64", gg.TYPE_BYTE)

    if gg.getResultCount() == 0 then
        gg.alert("❌ Không tìm thấy!")
        gg.setRanges(RANGE_VALUE)
        return
    end

    local res = gg.getResults(1)
    local ptrData = gg.getValues({{ address = res[1].address + 0x20, flags = gg.TYPE_QWORD }})
    if not ptrData[1] or ptrData[1].value == 0 then
        gg.alert("❌ Không tìm thấy pointer!")
        gg.setRanges(RANGE_VALUE)
        return
    end

    local flagAddr = ptrData[1].value
    if choice == 1 then
        gg.setValues({{ address = flagAddr, flags = gg.TYPE_BYTE, value = 1 }})
        gg.setRanges(RANGE_VALUE)
        gg.alert("✅ Đã bật Debug Mode!")
    elseif choice == 2 then
        gg.setValues({{ address = flagAddr, flags = gg.TYPE_BYTE, value = 0 }})
        gg.setRanges(RANGE_VALUE)
        gg.alert("❌ Đã tắt Debug Mode!")
    end
end

-- ═══════════════════════════════════════════════════════════
--  VIP PASS + DIAMONDS
-- ═══════════════════════════════════════════════════════════
local VIPM = {}
function VIPM.readPtr(a)
    local v = gg.getValues({{address = a, flags = gg.TYPE_QWORD}})
    return (v and v[1]) and v[1].value or 0
end
VIPM._main = nil
function VIPM.mainStatus()
    if VIPM._main then return VIPM._main end
    gg.setVisible(false)
    gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("Q 1A 73 74 61 72 74 75 70 5F 63 6F 75", gg.TYPE_BYTE)
    gg.refineNumber("26", gg.TYPE_BYTE)
    local results = gg.getResults(gg.getResultCount())
    gg.clearResults()
    if not results or #results == 0 then return nil end
    for _, v in ipairs(results) do
        local p20 = VIPM.readPtr(v.address + 0x20)
        if p20 ~= 0 then
            local p80 = VIPM.readPtr(p20 + 0x80)
            if p80 ~= 0 then VIPM._main = p80; return p80 end
        end
    end
    return nil
end

local function vipPassFunc()
    local res = gg.prompt({"⭐ Nhập số ngày VIP [1-30]:"}, {30}, {"number"})
    if not res then return end
    local days = math.max(1, math.min(30, tonumber(res[1]) or 30))

    local base = VIPM.mainStatus()
    if not base then gg.toast("❌ Không tìm thấy Base Status!"); return end
    local vipPtr = VIPM.readPtr(base + 0x3A8)
    if vipPtr == 0 then gg.toast("❌ Lỗi Pointer VIP!"); return end

    local vip = vipPtr + 0x10
    local now = os.time(os.date("!*t"))
    gg.setValues({
        {address = vip,        flags = gg.TYPE_DWORD, value = 130559},
        {address = vip + 0x4,  flags = gg.TYPE_DWORD, value = 81},
        {address = vip + 0x8,  flags = gg.TYPE_DWORD, value = now + 86400 * days},
        {address = vip + 0xC,  flags = gg.TYPE_DWORD, value = 6},
        {address = vip + 0x10, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x14, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x18, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x1C, flags = gg.TYPE_DWORD, value = 65793},
    })
    local p = VIPM.readPtr(base + 0x2E0)
    if p ~= 0 then
        local it = {address = p + 0x2C, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues({it}); gg.addListItems({it})
    end
    gg.clearResults()
    gg.toast("⭐ VIP " .. days .. " ngày!")
end

local SR = {}
SR.lib = "libcocos2dcpp.so"
function SR.readPtr(a) return gg.getValues({{address = a, flags = gg.TYPE_QWORD}})[1].value end
function SR.getBase()
    local r = gg.getRangesList(SR.lib)
    return #r > 0 and r[1].start or nil
end

local function diamondsSR()
    gg.setVisible(false)
    local p = gg.prompt(
        {"💎 Số Diamonds (Max 1000000):", "🛡️ Bật Bypass?"},
        {"15000", true}, {"number", "checkbox"}
    )
    if not p then return end
    local val = tonumber(p[1]) or 15000
    local bypass = p[2]

    local base = SR.getBase()
    if not base then gg.toast("lib not found"); return end

    local freezeOff = getOffsets().freezeDiamond
    if not freezeOff then
        gg.alert("⚠️ Version chưa có freezeDiamond!")
        return
    end

    gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_C_BSS)
    gg.searchNumber("1126191955", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultCount())
    gg.clearResults()
    if #results == 0 then gg.toast("base not found"); return end

    local edits = {}
    for _, v in ipairs(results) do
        local pF8 = SR.readPtr(v.address + 0xF8)
        if pF8 ~= 0 then
            local p48 = SR.readPtr(pF8 + 0x48)
            if p48 ~= 0 then
                local v138 = SR.readPtr(p48 + 0x138)
                local v140 = SR.readPtr(p48 + 0x140)
                local v148 = SR.readPtr(p48 + 0x148)
                if v138 ~= 0 then
                    edits[#edits+1] = {address = v138, flags = gg.TYPE_DWORD, value = val}
                end
                for o = 0x0, 0xA0, 0x8 do
                    local ptr = SR.readPtr(pF8 + o)
                    if ptr ~= 0 then
                        edits[#edits+1] = {address = ptr + 0x138, flags = gg.TYPE_QWORD, value = v138}
                        edits[#edits+1] = {address = ptr + 0x140, flags = gg.TYPE_QWORD, value = v140}
                        edits[#edits+1] = {address = ptr + 0x148, flags = gg.TYPE_QWORD, value = v148}
                        edits[#edits+1] = {address = ptr + 0x10C, flags = gg.TYPE_FLOAT, value = 1}
                    end
                end
            end
        end
    end
    if #edits == 0 then gg.toast("NOT WORK"); return end
    if bypass then
        gg.addListItems({{address = base + freezeOff, flags = gg.TYPE_DWORD, value = 0, freeze = true}})
    end
    gg.setValues(edits)
    gg.toast(bypass and "💎 [OK] + BYPASS" or "💎 [OK]")
end

-- ═══════════════════════════════════════════════════════════
--  MAX VEHICLES / MASTERY / PARTS
-- ═══════════════════════════════════════════════════════════
local function MaxVehicles()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Vào garage trước rồi bấm OK")
    local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD }})[1].value
    local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD }})[1].value

    if not vehicleListPtr or vehicleListPtr == 0 or not totalVehicles or totalVehicles == 0 then
        gg.alert("❌ Không đọc được vehicle list!")
        return
    end

    local reads = {}
    for i = 0, totalVehicles - 1 do
        reads[#reads + 1] = { address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD }
    end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do
        if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end
    end

    local meta = {}
    for _, vp in ipairs(vehicles) do
        meta[#meta + 1] = { address = vp + 0x18, flags = gg.TYPE_QWORD }
        meta[#meta + 1] = { address = vp + 0x20, flags = gg.TYPE_QWORD }
    end
    local metaVals = gg.getValues(meta)

    local upReads = {}
    for k, vp in ipairs(vehicles) do
        local namePtr        = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
        local upgradeListPtr = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value
        local vehicleName = (namePtr and namePtr ~= 0) and readStringAt(namePtr + 1) or "unknown"
        local slots = vehicleName:find("lowrider") and 5 or 4
        if upgradeListPtr and upgradeListPtr ~= 0 then
            for j = 0, slots - 1 do
                upReads[#upReads + 1] = { address = upgradeListPtr + j * 8, flags = gg.TYPE_QWORD }
            end
        end
    end

    local upPtrs = gg.getValues(upReads)
    local edits = {}
    for _, p in ipairs(upPtrs) do
        if p.value and p.value ~= 0 then
            edits[#edits + 1] = { address = p.value + 0x20, flags = gg.TYPE_DWORD, value = 19 }
            edits[#edits + 1] = { address = p.value + 0x24, flags = gg.TYPE_DWORD, value = 19 }
        end
    end

    if #edits > 0 then
        gg.setValues(edits)
        gg.alert("✅ Đã max " .. #vehicles .. " vehicles!")
    else
        gg.alert("❌ Không có gì để max!")
    end
end

local function MaxMastery()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Dùng Max Vehicles TRƯỚC!")
    local ts = os.time()
    local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD }})[1].value
    local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD }})[1].value
    if not vehicleListPtr or vehicleListPtr == 0 then
        gg.alert("❌ Không đọc được vehicle list!")
        return
    end

    local reads = {}
    for i = 0, totalVehicles - 1 do
        reads[#reads + 1] = { address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD }
    end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do
        if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end
    end

    local mReads = {}
    for _, vp in ipairs(vehicles) do
        mReads[#mReads + 1] = { address = vp + 0x120, flags = gg.TYPE_QWORD }
    end
    local mVals = gg.getValues(mReads)

    local active, caReads = {}, {}
    for k, vp in ipairs(vehicles) do
        local mPtr = mVals[k] and mVals[k].value
        if mPtr and mPtr ~= 0 then
            active[#active + 1] = { vehiclePtr = vp, masteryPtr = mPtr }
            for j = 0, 3 do
                caReads[#caReads + 1] = { address = mPtr + j * 8, flags = gg.TYPE_QWORD }
            end
        end
    end
    local caVals = gg.getValues(caReads)

    local writes = {}
    local successCount = 0
    for a = 1, #active do
        local entry = active[a]
        local base  = (a - 1) * 4
        for j = 1, 4 do
            local p = caVals[base + j]
            if p and p.value and p.value ~= 0 then
                writes[#writes + 1] = { address = p.value + 0x18, flags = gg.TYPE_DWORD, value = 65793 }
                writes[#writes + 1] = { address = p.value + 0x1C, flags = gg.TYPE_DWORD, value = ts }
            end
        end
        writes[#writes + 1] = { address = entry.vehiclePtr + 0x120, flags = gg.TYPE_QWORD, value = entry.masteryPtr }
        writes[#writes + 1] = { address = entry.vehiclePtr + 0x128, flags = gg.TYPE_DWORD, value = 4 }
        writes[#writes + 1] = { address = entry.vehiclePtr + 0x12C, flags = gg.TYPE_DWORD, value = 4 }
        writes[#writes + 1] = { address = entry.vehiclePtr + 0x130, flags = gg.TYPE_DWORD, value = 4 }
        successCount = successCount + 1
    end

    if #writes > 0 then
        gg.setValues(writes)
        gg.alert("✅ Đã max " .. successCount .. " masteries!")
    else
        gg.alert("❌ Không có gì để max!")
    end
end

local function MaxParts()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Dùng Max Vehicles TRƯỚC!")
    local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD }})[1].value
    local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD }})[1].value
    if not vehicleListPtr or vehicleListPtr == 0 then
        gg.alert("❌ Không đọc được vehicle list!")
        return
    end

    local reads = {}
    for i = 0, totalVehicles - 1 do
        reads[#reads + 1] = { address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD }
    end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do
        if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end
    end

    local meta = {}
    for _, vp in ipairs(vehicles) do
        meta[#meta + 1] = { address = vp + 0x58, flags = gg.TYPE_QWORD }
        meta[#meta + 1] = { address = vp + 0x60, flags = gg.TYPE_DWORD }
    end
    local metaVals = gg.getValues(meta)

    local upgradeList = {}
    for k, vp in ipairs(vehicles) do
        local partsListPtr = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
        local totalParts   = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value

        if partsListPtr and partsListPtr ~= 0 and totalParts and totalParts > 0 then
            local pReads = {}
            for j = 0, totalParts - 1 do
                pReads[#pReads + 1] = { address = partsListPtr + j * 8, flags = gg.TYPE_QWORD }
            end
            local partPtrs = gg.getValues(pReads)

            for _, pp in ipairs(partPtrs) do
                local partPtr = pp.value
                if partPtr and partPtr ~= 0 then
                    local namePtr = gg.getValues({{ address = partPtr + 0x18, flags = gg.TYPE_QWORD }})[1].value
                    local partName = "unknown"
                    if namePtr and namePtr ~= 0 then
                        local header = gg.getValues({{ address = namePtr, flags = gg.TYPE_DWORD }})[1].value
                        if header == 49 then
                            local namePtr2 = gg.getValues({{ address = namePtr + 0x10, flags = gg.TYPE_QWORD }})[1].value
                            partName = namePtr2 ~= 0 and readStringAt(namePtr2) or "unknown"
                        else
                            partName = readStringAt(namePtr + 1)
                        end
                    end
                    local lvl = partMaxLevel(partName)
                    upgradeList[#upgradeList + 1] = { address = partPtr + 0x20, flags = gg.TYPE_DWORD, value = lvl }
                    upgradeList[#upgradeList + 1] = { address = partPtr + 0x34, flags = gg.TYPE_DWORD, value = lvl }
                end
            end
        end
    end

    if #upgradeList > 0 then
        gg.setValues(upgradeList)
        gg.alert("✅ Đã max " .. math.floor(#upgradeList / 2) .. " parts!")
    else
        gg.alert("❌ Không có parts để max!")
    end
end

-- ═══════════════════════════════════════════════════════════
--  SET FUEL & COINS
-- ═══════════════════════════════════════════════════════════
local FandResults, FandFound = {}, false
local function ApplyFand(val)
    if not FandFound then
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber("-1082130432~-1054867456;1~1500F;1~5;1~1500F::21", gg.TYPE_DWORD)
        gg.refineNumber("1~1500", gg.TYPE_FLOAT)
        local c = gg.getResultCount()
        if c == 0 then gg.alert("❌ Không tìm thấy!"); return end
        FandResults = gg.getResults(c); FandFound = true
    end
    local nv = {}
    for i, r in ipairs(FandResults) do
        nv[i] = {address = r.address, flags = gg.TYPE_FLOAT, value = val}
    end
    gg.setValues(nv); gg.alert("✅ Đã áp dụng: " .. tostring(val))
end

local function SetFuelCoins()
    local presets = {
        [1]         = "⚡ Default Radius",
        [10]        = "⚡ Short Radius (10m)",
        [500]       = "⚡ Big Radius (500m)",
        [100000000] = "⚡ Remove Fuel & Coins"
    }
    local keys = {}
    for k in pairs(presets) do keys[#keys+1] = k end
    table.sort(keys)
    local labels = {}
    for _, k in ipairs(keys) do labels[#labels+1] = presets[k] end
    labels[#labels+1] = "✏️ Custom Radius"
    labels[#labels+1] = "⬅️ Quay lại"

    local choice = gg.choice(labels, nil, nil)
    if choice == nil or choice == #labels then return end

    if choice == #labels - 1 then
        local inp = gg.prompt({"Radius (m):"}, {67}, {"number"})
        if not inp then return SetFuelCoins() end
        ApplyFand(tonumber(inp[1]))
        return SetFuelCoins()
    end
    ApplyFand(keys[choice])
    return SetFuelCoins()
end

-- ═══════════════════════════════════════════════════════════
--  EVENT MENU
-- ═══════════════════════════════════════════════════════════
local function EventMenu()
    if not checkGameStatus() then return end
    local choice = gg.choice({
        "🛒 Free Purchases (Event)",
        "💎 Add Currency (Coins/Gems)",
        "⬅️ Quay lại"
    }, nil, "🎉 Làm việc trong Event tab của game")

    if not choice or choice == 3 then return end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.searchNumber("60;600;150", gg.TYPE_FLOAT)
        local res = gg.getResults(gg.getResultsCount())
        if #res == 0 then
            gg.alert("❌ Vào Event tab trong game trước!")
            return
        end
        gg.editAll(0, gg.TYPE_FLOAT)
        gg.clearResults()
        gg.alert("✅ Đã bật!\nThoát Event tab rồi vào lại.")
    elseif choice == 2 then
        local cur = gg.prompt({
            "Chọn (1=Coins, 2=Gems):",
            "Số lượng:"
        }, {1, 50000}, {"number", "number"})
        if not cur then return end
        local ctype  = tonumber(cur[1]) or 1
        local amount = tonumber(cur[2]) or 50000
        local addr = BaseGameStatus + 0x4F4
        if ctype == 2 then addr = BaseGameStatus + 0x4F8 end
        gg.setValues({{ address = addr, flags = gg.TYPE_DWORD, value = amount }})
        gg.alert("✅ Đã set currency " .. ctype .. " = " .. amount)
    end
end

-- ═══════════════════════════════════════════════════════════
--  TEAM EVENT MODULE
-- ═══════════════════════════════════════════════════════════
local TE = {
    VerifyRetryCount=0x11F, VerifyMatchmakingReq=0x123, VerifyUnknown3=0x127,
    StartServerTimestamp=0x12B, StartClientTimestamp=0x12F, EndEventTimestamp=0x133,
    VerifyTeamTicketJoin=0x13F, VerifyTicketRefillBase=0x147, VerifyUnknown6=0x14B,
    VerifyRetryLimit=0x14F, VerifyRetryDisableFlag=0x153,
    VerifyTeamDurationStart=0x1FB, VerifyTeamDurationEnd=0x1FF,
    EditMatchmakingReq=0x123, EditTeamTicketJoin=0x13F, EditTicketRefill=0x147,
    EditRetryDisable=0x157, EditTeamDurationStart=0x1FB, EditTeamDurationEnd=0x1FF,
    SetVehicleLimit1=0x437, SetVehicleLimit2=0x43F, SetVehicleLimit3=0x447,
    AllowVehicleList1=0x44F, AllowVehicleList2=0x457, AllowVehicleList3=0x45F,
    AnalyzeGameMode=0x4DF,
    EventScoreCheck1=0x1B0, EventScoreCheck2=0x1C8, EventScoreCheck3=0x1E0,
}
local TE_VerifyPatterns = {
    {offset=TE.VerifyRetryCount, expected=10},
    {offset=TE.VerifyMatchmakingReq, expected=5},
    {offset=TE.VerifyUnknown3, expected=3},
    {offset=TE.VerifyTeamTicketJoin, expected=1},
    {offset=TE.VerifyTicketRefillBase, expected=14400},
    {offset=TE.VerifyUnknown6, expected=2},
    {offset=TE.VerifyRetryLimit, expected=50},
    {offset=TE.VerifyRetryDisableFlag, expected=1},
    {offset=TE.VerifyTeamDurationStart, expected=172800},
    {offset=TE.VerifyTeamDurationEnd, expected=172800},
}
local TE_History = {}
local TE_DurationInput = nil

local function TE_readOne(addr, flags)
    if not addr or type(addr) ~= "number" then return nil end
    local v = gg.getValues({{address = addr, flags = flags}})
    return (v and v[1]) and v[1].value or nil
end

local function TE_verifyBase(base)
    for _, pat in ipairs(TE_VerifyPatterns) do
        local cur = TE_readOne(base + pat.offset, gg.TYPE_DWORD)
        if cur == nil or cur ~= pat.expected then return false end
    end
    return true
end

local function TE_searchEvent()
    local input = gg.prompt({"Tên Event (VD: :Hooked on a Wheelin'):"}, {""}, {"text"})
    if not input or input[1] == "" then gg.toast("⚠️ Trống!"); return end
    local label = input[1]
    local len = #label
    local word = label:match("^(%S+)") or label
    local firstChar = label:sub(1, 1)

    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. label, gg.TYPE_BYTE)
    gg.refineNumber(":" .. word, gg.TYPE_BYTE)
    gg.refineNumber(":" .. firstChar, gg.TYPE_BYTE)

    local cnt = gg.getResultsCount()
    local refineResults = gg.getResults(cnt)
    TE_History[label] = TE_History[label] or {results={}, verified={}, is_enabled=false}
    local added = 0
    if cnt == 0 then gg.toast("❌ Không tìm thấy!"); return end

    if len <= 23 then
        for _, r in ipairs(refineResults) do
            if not TE_History[label].verified[r.address] then
                if TE_verifyBase(r.address) then
                    TE_History[label].verified[r.address] = true
                    TE_History[label].results[#TE_History[label].results+1] = r
                    added = added + 1
                end
            end
        end
        gg.clearResults()
        gg.toast("✅ Added " .. added .. " cho: " .. label)
        return
    end

    for _, rr in ipairs(refineResults) do
        local stringAddress = rr.address
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber(stringAddress, gg.TYPE_QWORD)
        local pCount = gg.getResultsCount()
        if pCount > 0 then
            for _, p in ipairs(gg.getResults(pCount)) do
                local base = p.address - 0xF
                local checkAddr = p.address - 0x10
                local v = gg.getValues({{address = checkAddr, flags = gg.TYPE_DWORD}})
                if v and v[1] and v[1].value >= 0 and v[1].value <= 100 then
                    if not TE_History[label].verified[base] then
                        if TE_verifyBase(base) then
                            TE_History[label].verified[base] = true
                            TE_History[label].results[#TE_History[label].results+1] = {address = base}
                            added = added + 1
                        end
                    end
                end
            end
        end
    end
    gg.toast("✅ Pointer-verified " .. added .. " cho: " .. label)
    gg.clearResults()
end

local function TE_applyEdits(base, selectedEdits)
    local batch = {}
    for _, idx in ipairs(selectedEdits) do
        if idx == 1 then
            batch[#batch+1] = {address=base+TE.EditMatchmakingReq, flags=gg.TYPE_DWORD, value=1}
        elseif idx == 2 then
            batch[#batch+1] = {address=base+TE.EditTeamTicketJoin, flags=gg.TYPE_DWORD, value=0}
        elseif idx == 3 then
            local orig = TE_readOne(base + TE.EditTicketRefill, gg.TYPE_DWORD)
            if orig then
                gg.setValues({{address=base+TE.EditTicketRefill, flags=gg.TYPE_DWORD, value=0}})
                gg.sleep(300)
                gg.setValues({{address=base+TE.EditTicketRefill, flags=gg.TYPE_DWORD, value=orig}})
            end
        elseif idx == 4 then
            batch[#batch+1] = {address=base+TE.EditRetryDisable, flags=gg.TYPE_DWORD, value=-1}
        elseif idx == 5 then
            if not TE_DurationInput then
                local ui = gg.prompt({"Duration (HOURS) [1;48]:"}, {"1"}, {"number"})
                if not ui then return false end
                TE_DurationInput = tonumber(ui[1]) or 1
            end
            local fv = 3600 * TE_DurationInput
            batch[#batch+1] = {address=base+TE.EditTeamDurationStart, flags=gg.TYPE_DWORD, value=fv}
            batch[#batch+1] = {address=base+TE.EditTeamDurationEnd, flags=gg.TYPE_DWORD, value=fv}
        end
    end
    if #batch > 0 then
        if not pcall(function() gg.setValues(batch) end) then return false end
    end
    return true
end

local function TE_enableEvent()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local eventPrompt = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not eventPrompt then return end
    local editNames = {"Matchmaking (1 player)", "Team ticket unlimited", "Refill Tickets [T-E]", "Retry Disable", "Duration [Leaders]"}
    local editPrompt = gg.prompt(editNames, {}, {"checkbox","checkbox","checkbox","checkbox","checkbox"})
    if not editPrompt then return end
    local sel = {}
    for k, v in pairs(editPrompt) do if v then sel[#sel+1] = k end end
    if #sel == 0 then gg.toast("⚠️ Không chọn edits!"); return end
    for i, isSelected in ipairs(eventPrompt) do
        if isSelected then
            local label = labels[i]
            local hist = TE_History[label]
            local cnt = 0
            for _, r in ipairs(hist.results) do
                if TE_applyEdits(r.address, sel) then cnt = cnt + 1 end
            end
            hist.is_enabled = cnt > 0
            gg.toast(string.format("✅ Enabled %d/%d cho \"%s\"", cnt, #hist.results, label))
        end
    end
    gg.clearResults(); gg.clearList()
end

local function TE_disableEvent()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, entry in pairs(TE_History) do
        if entry.is_enabled then labels[#labels+1] = label end
    end
    if #labels == 0 then gg.toast("❌ Không có event nào bật!"); return end
    local sel = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not sel then return end
    for i, isSelected in ipairs(sel) do
        if isSelected then
            local label = labels[i]
            local hist = TE_History[label]
            for _, r in ipairs(hist.results) do
                gg.setValues({
                    {address=r.address+TE.EditMatchmakingReq,    flags=gg.TYPE_DWORD, value=5},
                    {address=r.address+TE.EditTeamTicketJoin,    flags=gg.TYPE_DWORD, value=1},
                    {address=r.address+TE.EditRetryDisable,      flags=gg.TYPE_DWORD, value=1},
                    {address=r.address+TE.EditTeamDurationStart, flags=gg.TYPE_DWORD, value=172800},
                    {address=r.address+TE.EditTeamDurationEnd,   flags=gg.TYPE_DWORD, value=172800},
                })
            end
            hist.is_enabled = false
            gg.toast("⚠️ Disabled " .. label)
        end
    end
end

local function TE_showLogs()
    if not next(TE_History) then gg.alert("⚠️ Chưa có history!"); return end
    local lines = {}
    for label, h in pairs(TE_History) do
        lines[#lines+1] = string.format("%s: %d entry [%s]", label, #h.results, h.is_enabled and "✅" or "❌")
    end
    gg.alert(table.concat(lines, "\n"))
end

local function TE_setVehicleLimit()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local sel = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not sel then return end
    local inp = gg.prompt({"Limit:"}, {"1"}, {"number"})
    if not inp then return end
    local limitVal = tonumber(inp[1]) or 1
    for i, isSelected in ipairs(sel) do
        if isSelected then
            local hist = TE_History[labels[i]]
            for addr, _ in pairs(hist.verified) do
                local lStart = TE_readOne(addr + TE.SetVehicleLimit1, gg.TYPE_QWORD)
                local lEnd   = TE_readOne(addr + TE.SetVehicleLimit2, gg.TYPE_QWORD)
                if lStart and lEnd and lStart ~= 0 then
                    local count = math.floor((lEnd - lStart) / 4)
                    local batch = {}
                    for j = 0, count-1 do
                        batch[#batch+1] = {address=lStart + j*4, flags=gg.TYPE_DWORD, value=limitVal}
                    end
                    gg.setValues(batch)
                end
            end
            gg.toast("✅ Updated: " .. labels[i])
        end
    end
end

local function TE_analyzeGameMode()
    if not next(TE_History) then gg.toast("⚠️ Chưa search!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local ch = gg.choice(labels, nil, "Event để phân tích:")
    if not ch then return end
    local label = labels[ch]
    local hist = TE_History[label]
    local inp = gg.prompt({"Total Modes [1-5]:"}, {"1"}, {"number"})
    if not inp then return end
    local jumps = math.min(math.max(math.floor(tonumber(inp[1]) or 1), 1), 5)
    local jumpOffsets = {0, 0x8, 0x10, 0x18, 0x20}
    local modeInfo = {}
    for _, entry in ipairs(hist.results) do
        if entry and entry.address then
            local basePtr = TE_readOne(entry.address + TE.AnalyzeGameMode, gg.TYPE_QWORD)
            if basePtr and basePtr ~= 0 then
                for i = 1, jumps do
                    local jumpPtr = TE_readOne(basePtr + jumpOffsets[i], gg.TYPE_QWORD)
                    if jumpPtr and jumpPtr ~= 0 then
                        local function readF(o)
                            local p = TE_readOne(jumpPtr + o, gg.TYPE_QWORD)
                            if not p or p == 0 then return 0 end
                            return TE_readOne(p, gg.TYPE_FLOAT) or 0
                        end
                        local v198, v1B0, v1C8 = readF(TE.EventScoreCheck1), readF(TE.EventScoreCheck2), readF(TE.EventScoreCheck3)
                        if not (v198 == 0 and v1B0 == 0 and v1C8 == 0) then
                            modeInfo[#modeInfo+1] = {
                                jump=i, mode=(v1B0 == 0) and "Distance Mode" or "Time Attack Mode",
                                t198=v198, t1B0=v1B0, t1C8=v1C8,
                            }
                        end
                    end
                end
            end
        end
    end
    if #modeInfo == 0 then gg.toast("❌ Không có mode hợp lệ!"); return end
    local msg = "📌 Game Mode Analysis\nEvent: " .. label .. "\n\n"
    for _, m in ipairs(modeInfo) do
        msg = msg .. string.format("Mode %d (%s)\n", m.jump, m.mode)
        if m.mode == "Distance Mode" then
            msg = msg .. string.format("Distance → %.2f\nMax Points → %.2f\n\n", m.t198, m.t1C8)
        else
            msg = msg .. string.format("Min → %.2f\nMax → %.2f\nMax Points → %.2f\n\n", m.t198, m.t1B0, m.t1C8)
        end
    end
    gg.alert(msg)
end

local function TeamEventMenu()
    local menu = {
        "🔍 SEARCH EVENT (BƯỚC 1)",
        "✅ ENABLE TEAM EVENT",
        "❌ DISABLE TEAM EVENT",
        "📝 SHOW LOGS",
        "🥀 Set Vehicle Limit",
        "🔬 GAME MODES INFO",
        "⬅️ Quay lại"
    }
    local choice = gg.choice(menu, nil, nil)
    if choice == nil or choice == 7 then return end
    if choice == 1 then TE_searchEvent()
    elseif choice == 2 then TE_enableEvent()
    elseif choice == 3 then TE_disableEvent()
    elseif choice == 4 then TE_showLogs()
    elseif choice == 5 then TE_setVehicleLimit()
    elseif choice == 6 then TE_analyzeGameMode()
    end
    return TeamEventMenu()
end

-- ═══════════════════════════════════════════════════════════
--  ABOUT
-- ═══════════════════════════════════════════════════════════
local function About()
    local info = [[
╔══════════════════════════════════╗
║      ꧁AɴнDᴇᴘZᴀı꧂ SCRIPT V3       ║
╚══════════════════════════════════╝

📌 Version: V3
🎮 Game: Hill Climb Racing 2
⚙️ GG: 101.1

📢 Contact:
   💬 Discord  :: Andepzai
   ✈️ Telegram :: @Andepzai
   📺 Youtube  :: @Andepzai

⚡ FEATURES (22):
   ✅ Upgrade Parts Without Scrap
   ✅ Fly Hack
   ✅ Unlock Any Vehicle
   ✅ Tracks Editor
   ✅ Vehicle Hacks (13 xe)
   ✅ Free Chests
   ✅ Free Purchases
   ✅ Parts Drop (Legendary)
   ✅ Adventure Chest Hack V1
   ✅ Flat Ground for Adventure
   ✅ Auto Win (ARMV8)
   ✅ Debug Mode
   ✅ VIP Pass
   ✅ Diamonds (SR) + Bypass
   ✅ Max Vehicles
   ✅ Max Mastery
   ✅ Max Parts
   ✅ Set Fuel & Coins
   ✅ Team Event Menu (6 chức năng)
   ✅ Event Menu
   ✅ About
   ✅ Exit

⚠️ Sử dụng script này có thể bị BAN tài khoản.
   Tác giả không chịu trách nhiệm.
]]
    gg.alert(info, "OK")
    return MainMenu()
end

-- ═══════════════════════════════════════════════════════════
--  MENU CHÍNH (KHÔNG TIÊU ĐỀ)
-- ═══════════════════════════════════════════════════════════
function MainMenu()
    gg.setVisible(false)

    local menu = {
        "⚡ Upgrade Parts Without Scrap",
        "🚀 Fly Hack",
        "🚗 Unlock Any Vehicle",
        "🛣️ Tracks Editor",
        "🏎️ Vehicle Hacks",
        "⚡ Free Chests",
        "💳 Free Purchases",
        "🔧 Parts Drop (Legendary)",
        "🧰 Adventure Chest Hack V1",
        "➖ Flat Ground for Adventure",
        "🔥 Auto Win (ARMV8)",
        "💎 Debug Mode",
        "⭐ VIP Pass",
        "💎 Diamonds (SR) + Bypass",
        "🚀 Max Vehicles",
        "⭐ Max Mastery",
        "🔩 Max Parts",
        "💰 Set Fuel & Coins",
        "🎯 Team Event Menu",
        "🎉 Event Menu",
        "ℹ️ About",
        "❌ Exit"
    }

    -- KHÔNG có tiêu đề
    local choice = gg.choice(menu, nil, nil)
    if not choice then return end

    if choice == 1 then upgradeWithoutScrap()
    elseif choice == 2 then flyHack()
    elseif choice == 3 then unlockAnyVehicle()
    elseif choice == 4 then tracksEditor()
    elseif choice == 5 then vehicleHacksMenu()
    elseif choice == 6 then freeChests()
    elseif choice == 7 then freePurchases()
    elseif choice == 8 then partsDropLegendary()
    elseif choice == 9 then advChestHackV1()
    elseif choice == 10 then flatGroundAdventure()
    elseif choice == 11 then autoWin()
    elseif choice == 12 then debugMode()
    elseif choice == 13 then vipPassFunc()
    elseif choice == 14 then diamondsSR()
    elseif choice == 15 then MaxVehicles()
    elseif choice == 16 then MaxMastery()
    elseif choice == 17 then MaxParts()
    elseif choice == 18 then SetFuelCoins()
    elseif choice == 19 then TeamEventMenu()
    elseif choice == 20 then EventMenu()
    elseif choice == 21 then About()
    elseif choice == 22 then
        gg.setVisible(true)
        print(ShowPrint)
        os.exit()
    end
end

-- ═══════════════════════════════════════════════════════════
--  KHỞI ĐỘNG
-- ═══════════════════════════════════════════════════════════
checkBlocked()
checkGG()
checkHCR2()
getLib()
archType = detectArch()
gameVersion = getHCR2Version()

if archType == 3 or archType == 4 then
    gg.alert("⚠️ Phát hiện Emulator!\nAuto Win sẽ không hoạt động.")
end

selectRange()

gg.clearResults()
gg.clearList()
gg.setRanges(RANGE_VALUE)
gg.toast("🚀 Starting AɴнDᴇᴘZᴀı V3...")
gg.sleep(800)

-- Tìm GameStatus (chạy ẩn)
if not findGameStatus() then
    -- Không báo lỗi, chỉ toast nhẹ
    gg.toast("⚠️ Chưa tìm thấy GameStatus (vào Garage để fix)")
end

MainMenu()

-- Vòng lặp giữ menu
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        MainMenu()
    end
    gg.sleep(100)
end
