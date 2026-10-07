--==========================================================================
--  Kicia UI — Core (Signal, Trove, Tokens, Batch, Util, Fonts)
--==========================================================================
local Core = {}

--  Signal ---------------------------------------------------------------
do
    local Signal = {}
    Signal.__index = Signal
    function Signal.new() return setmetatable({ _handlers = {} }, Signal) end
    function Signal:Connect(fn)
        local h = { fn = fn, connected = true }
        table.insert(self._handlers, h)
        local sig = self
        return { Connected = true, Disconnect = function(c)
            if not h.connected then return end
            h.connected = false; c.Connected = false
            local i = table.find(sig._handlers, h)
            if i then table.remove(sig._handlers, i) end
        end }
    end
    function Signal:Once(fn)
        local c; c = self:Connect(function(...) c:Disconnect() fn(...) end); return c
    end
    function Signal:Fire(...)
        for _, h in ipairs(table.clone(self._handlers)) do
            if h.connected then task.spawn(h.fn, ...) end
        end
    end
    function Signal:Destroy() table.clear(self._handlers) end
    Core.Signal = Signal
end

--  Trove ---------------------------------------------------------------
do
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
            local d = member("Destroy"); if d then pcall(d, o) return end
            local dc = member("Disconnect"); if dc then pcall(dc, o) end
        end
    end
    function Trove:Add(o) table.insert(self._items, o) return o end
    function Trove:Connect(sig, fn) return self:Add(sig:Connect(fn)) end
    function Trove:Extend() return self:Add(Trove.new(self._name)) end
    function Trove:Remove(o, keep)
        local i = table.find(self._items, o)
        if i then table.remove(self._items, i) if not keep then cleanItem(o) end end
    end
    function Trove:Clean()
        local items = self._items; self._items = {}
        for i = #items, 1, -1 do cleanItem(items[i]) end
    end
    Trove.Destroy = Trove.Clean
    Core.Trove = Trove
end

--  Tokens --------------------------------------------------------------
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
    TabHighlight = Color3.fromRGB(51, 65, 70),
    TabShadow = Color3.fromRGB(30, 51, 61),
}

--  Fonts ---------------------------------------------------------------
Core.Fonts = {
    Main     = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
    SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    Bold     = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

--  Util ----------------------------------------------------------------
do
    local U = {}
    function U.currentViewportSize()
        local c = workspace.CurrentCamera
        return c and c.ViewportSize or Vector2.new(1920, 1080)
    end
    function U.gethui()
        local f = getfenv(0).gethui
        if type(f) == "function" then
            local ok, h = pcall(f)
            if ok and h then return h end
        end
        return game:GetService("CoreGui")
    end
    function U.findScrollingAncestor(inst)
        local p = inst and inst.Parent
        while p do
            if p:IsA("ScrollingFrame") then return p end
            p = p.Parent
        end
    end
    Core.Util = U
end

--  Batch ---------------------------------------------------------------
do
    local Tokens = Core.Tokens
    local Batch = {}
    Batch.__index = Batch
    local registry = setmetatable({}, { __mode = "k" })

    local function buildGradient(tokens, times)
        if #tokens == 1 then return ColorSequence.new(Tokens[tokens[1]]) end
        local kps = {}
        for i, tok in ipairs(tokens) do
            local t = times ~= nil and times[i] or (i - 1) / (#tokens - 1)
            kps[i] = ColorSequenceKeypoint.new(t, Tokens[tok])
        end
        return ColorSequence.new(kps)
    end

    function Batch.new()
        return setmetatable({ _prop = {}, _grad = {}, _state = {}, _set = {} }, Batch)
    end
    function Batch:Bind(inst, prop, token)
        inst[prop] = Tokens[token]
        local b = self._prop[token] or {}; self._prop[token] = b
        table.insert(b, { Instance = inst, Property = prop })
        self:_mark(token)
    end
    function Batch:BindGradient(g, tokens, times)
        g.Color = buildGradient(tokens, times)
        table.insert(self._grad, { Gradient = g, Tokens = tokens, Times = times })
        for _, t in ipairs(tokens) do self:_mark(t) end
    end
    function Batch:_mark(token)
        if self._set[token] then return end
        self._set[token] = true
        local s = registry[token] or {}; registry[token] = s
        s[self] = true
    end
    function Batch:Destroy()
        for t in next, self._set do
            local s = registry[t]; if s then s[self] = nil end
        end
        table.clear(self._set); table.clear(self._prop)
        table.clear(self._grad); table.clear(self._state)
    end
    Batch.newBatch = function(parent)
        local b = Batch.new(); if parent then parent:Add(b) end; return b
    end
    Batch.get = function(t) return Tokens[t] end
    function Batch.refresh(token, color)
        if Tokens[token] == color then return end
        Tokens[token] = color
        local s = registry[token]; if s == nil then return end
        for b in next, s do
            local props = b._prop[token]
            if props then for _, p in ipairs(props) do p.Instance[p.Property] = color end end
            for _, g in ipairs(b._grad) do
                if table.find(g.Tokens, token) then
                    g.Gradient.Color = buildGradient(g.Tokens, g.Times)
                end
            end
            local st = b._state[token]
            if st then for _, f in ipairs(st) do f(color) end end
        end
    end
    Core.Batch = Batch
end

return Core
