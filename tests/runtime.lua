local events = {}
local combat = false
local methods = {}
function methods:GetID() return self.id or 0 end
function methods:SetID(id) self.id = id end
function methods:IsShown() return self.shown ~= false end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:SetScale(scale) self.scale = scale end
function methods:GetWidth() return self.width or 200 end
function methods:GetHeight() return self.height or 200 end
function methods:GetCenter() return self.x or 500, self.y or 400 end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(...)
    self.point = {...}
    self.points = self.points or {}
    self.points[select(1, ...)] = {...}
end
function methods:SetPassThroughButtons(...) self.passThrough = {...} end
function methods:SetMovable(value) self.movable = value end
function methods:SetClampedToScreen(value) self.clamped = value end
function methods:SetHeight(value) self.height = value end
function methods:GetFrameLevel() return 1 end
function methods:SetFrameLevel() end
function methods:EnableMouse(value) self.mouse = value end
function methods:RegisterForDrag() end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:HookScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(event) events[event] = self end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function CreateFrame() return setmetatable({scripts = {}}, {__index = methods}) end
function hooksecurefunc(target, name, fn)
    if type(target) == 'string' then fn, name, target = name, target, _G end
    local old = target[name]
    target[name] = function(...) old(...); fn(...) end
end
function InCombatLockdown() return combat end
UIParent = CreateFrame()
UIParent.width, UIParent.height = 1000, 800
ContainerFrame1 = CreateFrame()
ContainerFrame1.id = 0
ContainerFrame1.PortraitButton = CreateFrame()
ContainerFrame2 = CreateFrame()
ContainerFrame2.id = 1
SlashCmdList = {}
function UpdateContainerFrameAnchors()
    ContainerFrame1:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -10, 10)
    ContainerFrame2:SetPoint('BOTTOMRIGHT', ContainerFrame1, 'TOPRIGHT', 0, 5)
end
local function event(name, arg) events[name].scripts.OnEvent(events[name], name, arg) end
MoveBagsDB = { positions = {}, locked = false }
assert(loadfile('Core.lua'))('SimpleBagMover')
event('ADDON_LOADED', 'SimpleBagMover')
event('PLAYER_LOGIN')
local frame = ContainerFrame1
local handle = frame.moveBagsHandle
assert(handle.points.TOPLEFT[2] == frame.PortraitButton)
assert(handle.points.TOPLEFT[3] == 'TOPRIGHT' and handle.points.TOPLEFT[4] > 0)
assert(handle.passThrough[1] == 'RightButton')
assert(ContainerFrame2.moveBagsHandle.points.TOPLEFT[4] == 64)
handle.scripts.OnDragStart()
assert(frame.moving)
frame.x, frame.y = 300, 250
handle.scripts.OnDragStop()
assert(MoveBagsDB == nil)
assert(SimpleBagMoverDB.positions.bag0.x == .3)
UpdateContainerFrameAnchors()
assert(frame.point[1] == 'CENTER' and frame.point[4] == 300)
-- Pooled windows must use the current bag ID.
frame:SetID(1)
UpdateContainerFrameAnchors()
assert(frame.point[1] == 'BOTTOMRIGHT')
frame:SetID(0)
assert(frame.point[4] == 300)
frame:SetScale(.8)
assert(frame.point[4] == 375)
-- Protected combat periods defer restoration until combat ends.
combat = true
UpdateContainerFrameAnchors()
assert(frame.point[1] == 'BOTTOMRIGHT')
combat = false
event('PLAYER_REGEN_ENABLED')
assert(frame.point[1] == 'CENTER')
SlashCmdList.SIMPLEBAGMOVER('lock')
handle.scripts.OnDragStart()
assert(not frame.moving and not handle.mouse)
SlashCmdList.SIMPLEBAGMOVER('unlock')
assert(handle.mouse)
-- A fresh runtime must restore the same SavedVariables table.
local saved = SimpleBagMoverDB
ContainerFrame1, ContainerFrame2 = CreateFrame(), CreateFrame()
ContainerFrame2.id = 1
assert(loadfile('Core.lua'))('SimpleBagMover')
event('ADDON_LOADED', 'SimpleBagMover')
assert(SimpleBagMoverDB == saved and ContainerFrame1.point[4] == 300)
UIParent.width = 2000
event('DISPLAY_SIZE_CHANGED')
assert(ContainerFrame1.point[4] == 600)
SlashCmdList.SIMPLEBAGMOVER('reset')
assert(next(SimpleBagMoverDB.positions) == nil)
assert(ContainerFrame1.point[1] == 'BOTTOMRIGHT')
print('PASS: persistence, pooled bag identity, layout restoration, scale, combat, lock, reset')
