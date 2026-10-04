-- ============================================================
--  AɴнDᴇᴘZᴀı SCRIPT V3 - HCR2 CHEAT MENU
--  Fixed version - No syntax errors
-- ============================================================

local ShowPrint = [[
╔══════════════════════════════════════════════════════════════╗
║            ▓▓▓  AɴнDᴇᴘZᴀı SCRIPT V3  ▓▓▓                     ║
║                  Thanks for using!                           ║
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
            gg.alert("⛔ Detected forbidden app!\n📦 " .. pkg)
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
        gg.alert("❗ Please select HCR2!")
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
        local c = gg.choice({"⏩ Continue", "❌ Exit"}, nil, "❗ Couldn't find lib!")
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
        gg.alert("⚠️ Range này có thể không tốt!\nVui lòng dùng C alloc.")
    end

    RANGE_VALUE = ranges[pick].value
    currentRange = ranges[pick].name
    gg.setRanges(RANGE_VALUE)
    gg.toast("✅ Range: " .. currentRange)
    gg.sleep(500)
end

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
        gg.alert("❌ Chưa scan được GameStatus!\n💡 Vào Garage (bấm 1 xe) rồi chạy lại.")
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
            gg.alert("❌ Không tìm thấy!")
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

    local pick = gg.multiChoice(menu, nil, "☑️ Chọn nhiều xe")
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
        gg.alert("❌ Không mở được xe nào!")
    end
end

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
        gg.alert("❌ Nhập thiếu!")
        return
    end

    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. mapName, gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        gg.alert("❌ Không tìm thấy map!")
        return
    end

    gg.refineNumber(string.byte(mapName:sub(1, 1)), gg.TYPE_BYTE)
    local results = gg.getResults(30)
    if #results == 0 then
        gg.alert("⚠️ Refine fail!")
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
            local val = gg.getValues({{ address = 
