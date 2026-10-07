local Core = {}

local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ _handlers = {} }, Signal) end
function Signal:Connect(fn)
    local h = { fn = fn, connected = true }
    table.insert(self._handlers, h)
    local sig = self
    return { Connected = true, Disconnect = function(c)
        if not h.connected then return end
        h.connected = false
        c.Connected = false
        local i = table.find(sig._handlers, h)
        if i then table.remove(sig._handlers, i) end
    end }
end
function Signal:Once(fn)
    local c
    c = self:Connect(function(...) c:Disconnect() fn(...) end)
    return c
end
function Signal:Fire(...)
    for _, h in ipairs(table.clone(self._handlers)) do
        if h.connected then task.spawn(h.fn, ...) end
    end
end
function Signal:Destroy() table.clear(self._handlers) end
Core.Signal = Signal

local Trove = {}
Trove.__index = Trove
function Trove.new(name) return setmetatable({ _name = name, _items = {} }, Trove) end
local function cleanItem(o)
    local t = typeof(o)
    if t == "RBXScriptConnection" then o:Disconnect()
    elseif t == "Instance" then pcall(function() o:Destroy() end)
    elseif t == "thread" then pcall(task.cancel, o)
    elseif type(o) == "function" then pcall(o)
    elseif type(o) == "table" then
        local function member(k)
            local ok, v = pcall(function() return o[k] end)
            return ok and type(v) == "function" and v or nil
        end
        local d = member("Destroy")
        if d then pcall(d, o) return end
        local dc = member("Disconnect")
        if dc then pcall(dc, o) end
    end
end
function Trove:Add(o) table.insert(self._items, o) return o end
function Trove:Connect(sig, fn) return self:Add(sig:Connect(fn)) end
function Trove:Extend() return self:Add(Trove.new(self._name)) end
function Trove:Remove(o, keep)
    local i = table.find(self._items, o)
    if i then
        table.remove(self._items, i)
        if not keep then cleanItem(o) end
    end
end
function Trove:Clean()
    local items = self._items
    self._items = {}
    for i = #items, 1, -1 do cleanItem(items[i]) end
end
Trove.Destroy = Trove.Clean
Core.Trove = Trove

Core.Tokens = {
    Accent = Color3.fromRGB(154, 213, 222),
    Outline = Color3.fromRGB(24, 25, 24),
    Background = Color3.fromRGB(0, 0, 0),
    ElementBackground = Color3.fromRGB(6, 6, 6),
    TabButtonSelected = Color3.fromRGB(51, 65, 70),
    Unselected = Color3.fromRGB(75, 72, 72),
    TextColor = Color3.fromRGB(197, 197, 197),
    ToggleCircleUnselected = Color3.fromRGB(70, 85, 87),
    ToggleBackgroundUnselected = Color3.fromRGB(12, 13, 13),
    GradientTop = Color3.fromRGB(14, 16, 16),
    GradientMid = Color3.fromRGB(6, 6, 6),
    GradientDark = Color3.fromRGB(3, 3, 3),
    GradientDeep = Color3.fromRGB(0, 0, 0),
}

Core.Fonts = {
    Main     = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
    SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    Bold     = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

function Core.getHudParent()
    local f = getfenv(0).gethui
    if type(f) == "function" then
        local ok, h = pcall(f)
        if ok and h then return h end
    end
    local ok, pg = pcall(function()
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end)
    if ok and pg then return pg end
    return game:GetService("CoreGui")
end

function Core.newCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

function Core.newStroke(parent, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Core.Tokens.Outline
    s.Thickness = 1
    s.Parent = parent
    return s
end

function Core.fetch(base, rel)
    local url = base .. rel
    local src = game:HttpGet(url)
    assert(#src > 0, "KiciaUI: empty response for " .. url)
    local fn, err = loadstring(src, "KiciaUI/" .. rel)
    assert(fn, "KiciaUI: compile error in " .. rel .. ": " .. tostring(err))
    return fn()
end

return Core
