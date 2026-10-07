return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts
    local Signal = Core.Signal
    local newCorner = Core.newCorner
    local TweenService = game:GetService("TweenService")

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Value = spec.Default == true,
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            _rt = nil,
        }

        row:AttachRight(function(parent)
            local track = Instance.new("Frame")
            track.AnchorPoint = Vector2.new(1, 0.5)
            track.Position = UDim2.fromScale(1, 0.5)
            track.Size = UDim2.fromOffset(32, 20)
            track.BackgroundColor3 = Tokens.ToggleBackgroundUnselected
            track.BorderSizePixel = 0
            track.Parent = parent
            newCorner(track, 10)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(1, 1)
            fill.BackgroundColor3 = Tokens.Accent
            fill.BackgroundTransparency = 1
            fill.BorderSizePixel = 0
            fill.Parent = track
            newCorner(fill, 10)

            local circle = Instance.new("Frame")
            circle.Position = UDim2.fromOffset(3, 2)
            circle.Size = UDim2.fromOffset(16, 16)
            circle.BackgroundColor3 = Tokens.ToggleCircleUnselected
            circle.BorderSizePixel = 0
            circle.Parent = track
            newCorner(circle, 8)

            obj._rt = { Fill = fill, Circle = circle }

            local function apply(v, instant)
                local targetFill = v and 0 or 1
                local targetColor = v and Tokens.Accent or Tokens.ToggleCircleUnselected
                local targetPos = v and UDim2.fromOffset(13, 2) or UDim2.fromOffset(3, 2)
                if instant then
                    fill.BackgroundTransparency = targetFill
                    circle.BackgroundColor3 = targetColor
                    circle.Position = targetPos
                    return
                end
                local info = TweenInfo.new(0.1)
                TweenService:Create(fill, info, { BackgroundTransparency = targetFill }):Play()
                TweenService:Create(circle, info, { BackgroundColor3 = targetColor, Position = targetPos }):Play()
            end
            apply(obj.Value, true)

            trove:Connect(obj.Changed, function(v) apply(v) end)
            trove:Connect(row.Frame.InputBegan, function(input)
                local t = input.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    obj:Set(not obj.Value)
                end
            end)

            return track
        end)

        function obj:Set(v, instant)
            if type(v) ~= "boolean" or v == self.Value then return end
            self.Value = v
            if instant then
                local rt = self._rt
                if rt then
                    rt.Fill.BackgroundTransparency = v and 0 or 1
                    rt.Circle.BackgroundColor3 = v and Tokens.Accent or Tokens.ToggleCircleUnselected
                    rt.Circle.Position = v and UDim2.fromOffset(13, 2) or UDim2.fromOffset(3, 2)
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
