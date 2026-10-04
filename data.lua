-- ============================================================
-- Data Script — ꧁AɴнDᴇᴘZᴀı꧂
-- Tải từ GitHub API
-- ============================================================

gg.setVisible(false)

-- Kiểm tra game
local T = gg.getTargetPackage()
if T ~= "com.fingersoft.hcr2" then
    gg.alert("❗ Vui lòng chọn Hill Climb Racing 2!")
    os.exit()
end

-- Tìm thư viện game
local libs = gg.getRangesList("libcocos2dcpp.so")
if #libs == 0 then
    gg.alert("❗ Không tìm thấy libcocos2dcpp.so!\nVào game trước rồi chạy lại.")
    os.exit()
end
LIB_BASE = libs[1].start

-- Chọn vùng nhớ
gg.setRanges(gg.REGION_C_ALLOC)

-- ============ HÀM ẨN MENU ============
function HideAndWait()
    gg.setVisible(false)
end

-- ============ 1. FLY HACK ============
local FlyHackState = false

function FlyHack()
    local choice = gg.choice({
        "✅ Bật Fly Hack",
        "❌ Tắt Fly Hack",
        "🔙 Quay lại"
    }, nil, "✈️ FLY HACK")

    if not choice or choice == 3 then return HideAndWait() end

    if choice == 1 then
        gg.clearResults()
        gg.setRanges(gg.REGION_C_BSS)
        gg.searchNumber("-0.75", gg.TYPE_FLOAT)
        gg.getResults(2)
        gg.editAll("0.08", gg.TYPE_FLOAT)
        gg.clearResults()
        gg.searchNumber("-0.55", gg.TYPE_FLOAT)
        gg.getResults(2)
        gg.editAll("0.08", gg.TYPE_FLOAT)
        gg.clearResults()
        gg.searchNumber("-0.25", gg.TYPE_FLOAT)
        gg.getResults(2)
        gg.editAll("0.08", gg.TYPE_FLOAT)
        gg.clearResults()
        gg.searchNumber("-0.15", gg.TYPE_FLOAT)
        gg.getResults(2)
        gg.editAll("0.08", gg.TYPE_FLOAT)
        gg.clearResults()
        gg.searchNumber("0.08", gg.TYPE_FLOAT)
        local res = gg.getResults(2)
        if #res > 0 then
            gg.editAll("-1.2", gg.TYPE_FLOAT)
            FlyHackState = true
            gg.alert("✅ Đã bật Fly Hack!")
        end
        gg.setRanges(gg.REGION_C_ALLOC)
    elseif choice == 2 then
        if not FlyHackState then
            gg.alert("❌ Chưa bật!")
            return HideAndWait()
        end
        gg.clearResults()
        gg.setRanges(gg.REGION_C_BSS)
        gg.searchNumber("-1.2", gg.TYPE_FLOAT)
        local res = gg.getResults(2)
        if #res > 0 then
            gg.editAll("0.08", gg.TYPE_FLOAT)
            FlyHackState = false
            gg.alert("❌ Đã tắt Fly Hack!")
        end
        gg.setRanges(gg.REGION_C_ALLOC)
    end
    HideAndWait()
end

-- ============ 2. MAX ALL MASTERY ============
local masteryResults = {}

function getMasteryStats()
    if #masteryResults == 0 then return "\n─────────────────\n❌ Chưa quét" end
    local readPack = {}
    local stats = {active = 0, inactive = 0, locked = 0}
    for i = 1, #masteryResults do
        readPack[i] = {address = masteryResults[i].address + 0x8, flags = gg.TYPE_DWORD}
    end
    local values = gg.getValues(readPack)
    for _, v in ipairs(values) do
        if v.value == 1 then stats.active = stats.active + 1
        elseif v.value == 279 then stats.inactive = stats.inactive + 1
        elseif v.value == 0 then stats.locked = stats.locked + 1 end
    end
    return "\n─────────────────\n✅ Max: " .. stats.active ..
           "\n⏳ Inactive: " .. stats.inactive ..
           "\n🔒 Locked: " .. stats.locked
end

function searchMastery()
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber(":mastery_data", gg.TYPE_BYTE)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.clearResults()
        gg.searchNumber("1D~5D;0D~1D;279D::21", gg.TYPE_DWORD)
        gg.refineNumber("1~5", gg.TYPE_DWORD)
        count = gg.getResultsCount()
    end
    if count == 0 then
        masteryResults = {}
        gg.alert("❌ Không tìm thấy Mastery!")
        return false
    end
    masteryResults = gg.getResults(count)
    gg.toast("✅ Đã quét!")
    return true
end

function applyMastery()
    if #masteryResults == 0 then
        gg.alert("❌ Chưa có dữ liệu!")
        return
    end
    local applyPack = {}
    for i = 1, #masteryResults do
        applyPack[i] = {address = masteryResults[i].address + 0x8, value = 1, flags = gg.TYPE_DWORD}
    end
    gg.setValues(applyPack)
    gg.clearResults()
    masteryResults = {}
    gg.alert("✅ Đã Max TẤT CẢ Mastery!")
end

function MaxAllMasteries()
    if #masteryResults == 0 then searchMastery() end
    local statusInfo = getMasteryStats()
    local choice = gg.choice({
        "🔄 Quét lại",
        "🎯 Max Tất Cả",
        "🔙 Quay lại"
    }, nil, "😈 MAX ALL MASTERY" .. statusInfo)
    if not choice or choice == 3 then return HideAndWait() end
    if choice == 1 then
        searchMastery()
        return MaxAllMasteries()
    elseif choice == 2 then
        applyMastery()
    end
    HideAndWait()
end

-- ============ 3. TRACKS EDITOR ============
function TracksEditor()
    local req = {"Tên bản đồ", "Độ dài hiện tại", "Độ dài mới", "✅ Verify"}
    local defaults = {"", "300", "2000000000", true}
    local types = {"text", "number", "number", "checkbox"}
    local input = gg.prompt(req, defaults, types)
    if not input then return HideAndWait() end
    local mapName = input[1]
    local curLength = tonumber(input[2])
    local newLength = tonumber(input[3])
    local doVerify = input[4]
    if not mapName or mapName == "" then
        gg.alert("❌ Chưa nhập tên!")
        return TracksEditor()
    end
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber(":" .. mapName, gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then
        gg.alert("❌ Không tìm thấy: " .. mapName)
        return HideAndWait()
    end
    local firstChar = string.byte(mapName:sub(1, 1))
    gg.refineNumber(firstChar, gg.TYPE_BYTE)
    local results = gg.getResults(30)
    if #results == 0 then
        gg.alert("❌ Refine thất bại!")
        return HideAndWait()
    end
    local patched = 0
    for _, r in ipairs(results) do
        local candidate = r.address - 1
        gg.clearResults()
        gg.searchNumber(candidate, 32)
        local ptrs = gg.getResults(100)
        for _, p in ipairs(ptrs) do
            local lengthAddr = p.address + 0x20
            local verifyAddr = p.address + 0x34
            local curVal = gg.getValues({{address = lengthAddr, flags = gg.TYPE_DWORD}})[1].value
            if curVal == curLength then
                gg.setValues({{address = lengthAddr, flags = gg.TYPE_DWORD, value = newLength}})
                if doVerify then
                    gg.setValues({{address = verifyAddr, flags = gg.TYPE_DWORD, value = 1}})
                end
                patched = patched + 1
            end
        end
    end
    if patched > 0 then
        gg.alert("✅ Đã chỉnh " .. patched .. " bản đồ!")
    else
        gg.alert("❌ Không khớp!")
    end
    HideAndWait()
end

-- ============ 4. FREE CHESTS ============
local ChestsOriginal = {}
local ChestsFound = false

function FreeChests()
    local choice = gg.choice({
        "✅ Bật Free Chests",
        "❌ Tắt Free Chests",
        "🔙 Quay lại"
    }, nil, "⚡ FREE CHESTS")
    if not choice or choice == 3 then return HideAndWait() end
    if choice == 1 then
        if not ChestsFound then
            gg.clearResults()
            gg.setRanges(gg.REGION_C_DATA)
            gg.searchNumber("0.1", gg.TYPE_FLOAT)
            local count = gg.getResultCount()
            if count == 0 then
                gg.alert("❌ Không tìm thấy!\nMở Shop trước!")
                gg.setRanges(gg.REGION_C_ALLOC)
                return HideAndWait()
            end
            local res = gg.getResults(count)
            ChestsOriginal = gg.getValues(res)
            local newValues = {}
            for i, v in ipairs(res) do
                newValues[i] = {address = v.address, flags = v.flags, value = "0"}
            end
            gg.setValues(newValues)
            ChestsFound = true
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.toast("✅ Đã bật! (" .. count .. ")")
        else
            gg.toast("✅ Đã bật rồi!")
        end
    elseif choice == 2 then
        if ChestsFound and #ChestsOriginal > 0 then
            gg.setValues(ChestsOriginal)
            ChestsFound = false
            gg.alert("❌ Đã tắt!")
        else
            gg.alert("❌ Chưa bật!")
        end
        gg.setRanges(gg.REGION_C_ALLOC)
    end
    HideAndWait()
end

-- ============ 5. DEBUG MODE ============
function DebugMode()
    local choice = gg.choice({
        "✅ Bật Debug Mode",
        "❌ Tắt Debug Mode",
        "🔙 Quay lại"
    }, nil, "💎 DEBUG MODE")
    if not choice or choice == 3 then return HideAndWait() end
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_DATA)
    gg.searchNumber("h 24 64 65 62 75 67 5F 6D 6F 64 65 5F 65 6E 61 62 6C 65 64", gg.TYPE_BYTE)
    local count = gg.getResultCount()
    if count == 0 then
        gg.alert("❌ Không tìm thấy!")
        gg.setRanges(gg.REGION_C_ALLOC)
        return HideAndWait()
    end
    local results = gg.getResults(1)
    local debug_mode_addr = results[1].address
    local pointer_data = gg.getValues({{address = debug_mode_addr + 0x20, flags = gg.TYPE_QWORD}})
    if not pointer_data[1] or pointer_data[1].value == 0 then
        gg.alert("❌ Không tìm thấy con trỏ!")
        gg.setRanges(gg.REGION_C_ALLOC)
        return HideAndWait()
    end
    local debug_flag_address = pointer_data[1].value
    if choice == 1 then
        gg.setValues({{address = debug_flag_address, flags = gg.TYPE_BYTE, value = 1}})
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.alert("✅ Đã bật Debug Mode!")
    elseif choice == 2 then
        gg.setValues({{address = debug_flag_address, flags = gg.TYPE_BYTE, value = 0}})
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.alert("❌ Đã tắt Debug Mode!")
    end
    HideAndWait()
end

-- ============ MENU CHÍNH ============
function MainMenu()
    gg.setVisible(false)
    local choice = gg.choice({
        "✈️  Fly Hack",
        "😈  Max All Vehicle's Mastery",
        "🛣  Tracks Editor",
        "⚡  Free Chests",
        "💎  Debug Mode",
        "❌  Thoát"
    }, nil, "🎮 Script by ꧁AɴнDᴇᴘZᴀı꧂")
    if choice == nil then return HideAndWait() end
    if choice == 6 then os.exit() end
    if choice == 1 then FlyHack()
    elseif choice == 2 then MaxAllMasteries()
    elseif choice == 3 then TracksEditor()
    elseif choice == 4 then FreeChests()
    elseif choice == 5 then DebugMode() end
    HideAndWait()
end

MainMenu()

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        MainMenu()
    end
    gg.sleep(100)
end
