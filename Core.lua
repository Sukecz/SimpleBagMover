local addonName = ...
local eventFrame = CreateFrame("Frame")
local frames, hooked = {}, {}
local db, applying, moving
local Print

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function BagKey(frame)
    if frame == ContainerFrameCombinedBags then return "combined" end
    local id = frame:GetID()
    if type(id) == "number" and id >= 0 and id <= (NUM_BAG_SLOTS or 4) then
        return "bag" .. id
    end
end

local function ValidPosition(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
        and p.x >= 0 and p.x <= 1 and p.y >= 0 and p.y <= 1
end

local function Apply(frame)
    if not db or applying or moving == frame or not frame:IsShown() then return end
    local p = db.positions[BagKey(frame)]
    if not ValidPosition(p) then return end
    local scale = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    applying = true
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
        p.x * UIParent:GetWidth() * scale, p.y * UIParent:GetHeight() * scale)
    applying = false
end

local function Save(frame, key)
    local x, y = frame:GetCenter()
    if not key or not x or not y then return end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.positions[key] = {
        x = math.max(0, math.min(1, x * scale / UIParent:GetWidth())),
        y = math.max(0, math.min(1, y * scale / UIParent:GetHeight())),
    }
end

local function StopMoving()
    if not moving then return end
    local frame = moving
    frame:StopMovingOrSizing()
    Save(frame, frame.moveBagsDragKey)
    frame.moveBagsDragKey = nil
    moving = nil
    Apply(frame)
end

local function SetLocked(locked)
    if InCombat() then Print("Try again after combat."); return end
    StopMoving()
    db.locked = locked
    for frame in pairs(frames) do
        frame.moveBagsHandle:EnableMouse(not db.locked and BagKey(frame) ~= nil)
    end
    Print(db.locked and "Positions locked." or "Drag bag titles to move them.")
end

local function ResetPositions()
    if InCombat() then Print("Try again after combat."); return end
    StopMoving()
    db.positions = {}
    if UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
    Print("Positions reset.")
end

local function Attach(frame)
    if not frame or frames[frame] or InCombat() then return end
    frames[frame] = true
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    -- Only the title region is interactive; item slots and close buttons stay free.
    local handle = CreateFrame("Frame", nil, frame)
    frame.moveBagsHandle = handle
    -- Anchor outside the actual portrait hit area, not a guessed pixel offset.
    if frame.PortraitButton then
        handle:SetPoint("TOPLEFT", frame.PortraitButton, "TOPRIGHT", 4, 0)
    else
        handle:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -5)
    end
    -- A drag overlay must never consume Blizzard's context-menu clicks.
    if handle.SetPassThroughButtons then
        handle:SetPassThroughButtons("RightButton")
    end
    handle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -32, -5)
    handle:SetHeight(22)
    handle:SetFrameLevel(frame:GetFrameLevel() + 10)
    handle:EnableMouse(not db.locked)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        local key = BagKey(frame)
        if db.locked or InCombat() or not key then return end
        moving = frame
        frame.moveBagsDragKey = key
        frame:StartMoving()
    end)
    handle:SetScript("OnDragStop", StopMoving)
    handle:SetScript("OnEnter", function()
        GameTooltip:SetOwner(handle, "ANCHOR_TOP")
        GameTooltip:SetText("Simple Bag Mover")
        GameTooltip:AddLine("Drag to move. Use /sbm lock to lock positions.", 1, 1, 1)
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:HookScript("OnHide", function()
        if moving == frame then StopMoving() end
    end)
    frame:HookScript("OnShow", function() Apply(frame) end)
    -- Secure post-hooks leave Blizzard's layout functions intact.
    hooksecurefunc(frame, "SetPoint", function() Apply(frame) end)
    hooksecurefunc(frame, "SetScale", function() Apply(frame) end)
    hooksecurefunc(frame, "SetID", function() Apply(frame) end)
end

local function Refresh()
    if not db or InCombat() then return end
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do Attach(_G["ContainerFrame" .. i]) end
    Attach(ContainerFrameCombinedBags)
    for frame in pairs(frames) do
        frame.moveBagsHandle:EnableMouse(not db.locked and BagKey(frame) ~= nil)
        Apply(frame)
    end
    for _, name in ipairs({"UpdateContainerFrameAnchors", "ContainerFrame_GenerateFrame"}) do
        if type(_G[name]) == "function" and not hooked[name] then
            hooked[name] = true
            hooksecurefunc(name, Refresh)
        end
    end
end

Print = function(message)
    print("|cff66ccffSimple Bag Mover:|r " .. message)
end

local function Command(input)
    local command = (input or ""):lower():match("^%s*(.-)%s*$")
    if command == "debug" then
        local version, build, _, interface = GetBuildInfo()
        local count = 0
        for _ in pairs(frames) do count = count + 1 end
        Print(string.format("0.1.3; client %s (%s); interface %s; project %s; frames %d; layout hook %s",
            tostring(version), tostring(build), tostring(interface), tostring(WOW_PROJECT_ID), count,
            tostring(hooked.UpdateContainerFrameAnchors or false)))
    elseif command == "lock" or command == "unlock" or command == "reset" then
        if InCombat() then Print("Try again after combat."); return end
        if command == "reset" then
            ResetPositions()
        else
            SetLocked(command == "lock")
        end
    else
        Print("/sbm lock, /sbm unlock, /sbm reset, /sbm debug")
    end
end

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(SimpleBagMoverDB) ~= "table" then
            SimpleBagMoverDB = type(MoveBagsDB) == "table" and MoveBagsDB or {}
        end
        MoveBagsDB = nil
        db = SimpleBagMoverDB
        if type(db.positions) ~= "table" then db.positions = {} end
        db.locked = db.locked == true
        SLASH_SIMPLEBAGMOVER1, SLASH_SIMPLEBAGMOVER2 = "/simplebagmover", "/sbm"
        SlashCmdList.SIMPLEBAGMOVER = Command
    end
    if event == "PLAYER_REGEN_DISABLED" then
        StopMoving()
        return
    end
    Refresh()
end)
