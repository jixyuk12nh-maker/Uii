return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts
    local Signal = Core.Signal
    local newCorner = Core.newCorner
    local newStroke = Core.newStroke
    local TweenService = game:GetService("TweenService")

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Value = spec.Default or "",
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            Placeholder = spec.Placeholder or "",
            FocusLostOnly = spec.FocusLostOnly == true,
            _input = nil,
        }

        row:AttachRight(function(parent)
            local frame = Instance.new("Frame")
            frame.AnchorPoint = Vector2.new(1, 0.5)
            frame.Position = UDim2.fromScale(1, 0.5)
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Tokens.ElementBackground
            frame.BorderSizePixel = 0
            frame.Parent = parent
            newCorner(frame, 5)
            newStroke(frame)

            local input = Instance.new("TextBox")
            input.BackgroundTransparency = 1
            input.Size = UDim2.new(1, -10, 1, 0)
            input.Position = UDim2.fromOffset(5, 0)
            input.Text = obj.Value
            input.PlaceholderText = obj.Placeholder
            input.PlaceholderColor3 = Tokens.Unselected
            input.TextColor3 = Tokens.TextColor
            input.TextSize = 13
            input.TextXAlignment = Enum.TextXAlignment.Left
            input.ClearTextOnFocus = false
            input.FontFace = Fonts.Main
            input.BorderSizePixel = 0
            input.Parent = frame
            obj._input = input

            trove:Connect(input:GetPropertyChangedSignal("Text"), function()
                if not obj.FocusLostOnly then
                    obj:Set(input.Text)
                end
            end)
            trove:Connect(input.FocusLost, function()
                if obj.FocusLostOnly then
                    obj:Set(input.Text)
                end
                TweenService:Create(input, TweenInfo.new(0.1), { TextColor3 = Tokens.TextColor }):Play()
            end)
            trove:Connect(input.Focused, function()
                TweenService:Create(input, TweenInfo.new(0.1), { TextColor3 = Tokens.Accent }):Play()
            end)
            trove:Connect(obj.Changed, function(v)
                if input.Text ~= v and not input:IsFocused() then
                    input.Text = v
                end
            end)

            return frame
        end)

        function obj:Set(v, instant)
            if type(v) == "boolean" or v == nil then return end
            v = tostring(v)
            if v == self.Value then return end
            self.Value = v
            if not instant then
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
