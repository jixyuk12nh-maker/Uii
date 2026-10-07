return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts
    local Signal = Core.Signal
    local newCorner = Core.newCorner
    local UserInputService = game:GetService("UserInputService")

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Min = spec.Min or 0,
            Max = spec.Max or 100,
            Step = spec.Step or 1,
            Value = spec.Default or spec.Min or 0,
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            Suffix = spec.Suffix or "",
            _rt = nil,
        }

        row:AttachRight(function(parent)
            local holder = Instance.new("Frame")
            holder.AnchorPoint = Vector2.new(1, 0.5)
            holder.Position = UDim2.fromScale(1, 0.5)
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.BackgroundTransparency = 1
            holder.Parent = parent

            local track = Instance.new("Frame")
            track.AnchorPoint = Vector2.new(0, 0.5)
            track.Position = UDim2.new(0, 0, 0.5, 0)
            track.Size = UDim2.new(1, -50, 0, 3)
            track.BackgroundColor3 = Tokens.GradientMid
            track.BorderSizePixel = 0
            track.Parent = holder
            newCorner(track, 2)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(0, 1)
            fill.BackgroundColor3 = Tokens.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            newCorner(fill, 2)

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.fromScale(0, 0.5)
            knob.Size = UDim2.fromOffset(12, 12)
            knob.BackgroundColor3 = Tokens.Accent
            knob.BorderSizePixel = 0
            knob.Parent = track
            newCorner(knob, 6)

            local box = Instance.new("TextBox")
            box.AnchorPoint = Vector2.new(1, 0.5)
            box.Position = UDim2.new(1, 0, 0.5, 0)
            box.Size = UDim2.fromOffset(44, 22)
            box.BackgroundColor3 = Tokens.ElementBackground
            box.Text = tostring(obj.Value) .. obj.Suffix
            box.TextSize = 13
            box.TextColor3 = Tokens.TextColor
            box.FontFace = Fonts.SemiBold
            box.BorderSizePixel = 0
            box.Parent = holder
            newCorner(box, 4)

            obj._rt = { Track = track, Fill = fill, Knob = knob, Box = box }

            local function render(v)
                local t = (obj.Max == obj.Min) and 0 or (v - obj.Min) / (obj.Max - obj.Min)
                fill.Size = UDim2.fromScale(t, 1)
                knob.Position = UDim2.fromScale(t, 0.5)
                if not box:IsFocused() then
                    box.Text = tostring(v) .. obj.Suffix
                end
            end

            local dragging = false
            local function updateFromX(x)
                local tp = track.AbsolutePosition.X
                local ts = track.AbsoluteSize.X
                if ts <= 0 then return end
                local t = math.clamp((x - tp) / ts, 0, 1)
                local raw = obj.Min + (obj.Max - obj.Min) * t
                obj:Set(math.round(raw / obj.Step) * obj.Step)
            end

            trove:Connect(track.InputBegan, function(i)
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromX(i.Position.X)
                end
            end)
            trove:Connect(knob.InputBegan, function(i)
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            trove:Connect(UserInputService.InputChanged, function(i)
                if not dragging then return end
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                    updateFromX(i.Position.X)
                end
            end)
            trove:Connect(UserInputService.InputEnded, function(i)
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            trove:Connect(box.FocusLost, function()
                local n = tonumber(box.Text:match("[%d%.%-]+"))
                if n then
                    obj:Set(n)
                else
                    render(obj.Value)
                end
            end)
            trove:Connect(obj.Changed, render)
            render(obj.Value)

            return holder
        end)

        function obj:Set(v, instant)
            v = math.clamp(math.round(v / self.Step) * self.Step, self.Min, self.Max)
            if v == self.Value then return end
            self.Value = v
            if instant then
                local rt = self._rt
                if rt then
                    local t = (self.Max == self.Min) and 0 or (v - self.Min) / (self.Max - self.Min)
                    rt.Fill.Size = UDim2.fromScale(t, 1)
                    rt.Knob.Position = UDim2.fromScale(t, 0.5)
                    rt.Box.Text = tostring(v) .. self.Suffix
                end
            else
                self.Changed:Fire(v)
                self._onChanged(v)
            end
        end
        function obj:Get() return self.Value end
        function obj:SetVisible(v) self.Row:SetVisible(v) end
        function obj:OnChanged(fn) self._trove:Connect(self.Changed, fn) return self end

        return obj
    end
end
