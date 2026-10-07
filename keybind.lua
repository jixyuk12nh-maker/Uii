return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts
    local Signal = Core.Signal
    local newCorner = Core.newCorner
    local newStroke = Core.newStroke
    local UserInputService = game:GetService("UserInputService")

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Value = spec.Default,
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            _capturing = false,
            _rt = nil,
            _conn = nil,
        }

        local function formatKey(key)
            if key == nil then return "None" end
            if typeof(key) == "EnumItem" then
                if key.EnumType == Enum.KeyCode then
                    return key.Name
                elseif key.EnumType == Enum.UserInputType then
                    if key == Enum.UserInputType.MouseButton1 then return "MB1" end
                    if key == Enum.UserInputType.MouseButton2 then return "MB2" end
                    if key == Enum.UserInputType.MouseButton3 then return "MB3" end
                end
                return key.Name
            end
            return tostring(key)
        end

        local function stopCapture()
            obj._capturing = false
            if obj._conn then
                obj._conn:Disconnect()
                obj._conn = nil
            end
            if obj._rt then
                obj._rt.Label.Text = formatKey(obj.Value)
                obj._rt.Label.TextColor3 = Tokens.TextColor
            end
        end

        row:AttachRight(function(parent)
            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.fromScale(1, 0.5)
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = Tokens.ElementBackground
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.Parent = parent
            newCorner(btn, 5)
            newStroke(btn)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.fromScale(1, 1)
            label.Text = formatKey(obj.Value)
            label.TextSize = 13
            label.TextColor3 = Tokens.TextColor
            label.FontFace = Fonts.SemiBold
            label.BorderSizePixel = 0
            label.Parent = btn
            obj._rt = { Button = btn, Label = label }

            trove:Connect(btn.MouseButton1Click, function()
                if obj._capturing then
                    stopCapture()
                    return
                end
                obj._capturing = true
                label.Text = "..."
                label.TextColor3 = Tokens.Accent
                obj._conn = trove:Connect(UserInputService.InputBegan, function(input, gp)
                    if gp then return end
                    local key = nil
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            stopCapture()
                            return
                        end
                        key = input.KeyCode
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        key = Enum.UserInputType.MouseButton1
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        key = Enum.UserInputType.MouseButton2
                    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                        key = Enum.UserInputType.MouseButton3
                    end
                    if key == nil then return end
                    obj:Set(key)
                    stopCapture()
                end)
            end)

            return btn
        end)

        function obj:Set(v, instant)
            if v == self.Value then return end
            self.Value = v
            if self._rt and not self._capturing then
                self._rt.Label.Text = formatKey(v)
                self._rt.Label.TextColor3 = Tokens.TextColor
            end
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
