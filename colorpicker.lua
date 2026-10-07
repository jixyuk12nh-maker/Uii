return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts
    local Signal = Core.Signal
    local newCorner = Core.newCorner
    local newStroke = Core.newStroke

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Value = spec.Default or Color3.fromRGB(255, 255, 255),
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            _rt = nil,
            _popup = nil,
            _boxes = nil,
        }

        local function syncBoxes(v)
            if obj._boxes then
                obj._boxes.R.Text = tostring(math.round(v.R * 255))
                obj._boxes.G.Text = tostring(math.round(v.G * 255))
                obj._boxes.B.Text = tostring(math.round(v.B * 255))
            end
        end

        local function buildPopup(parent)
            local popup = Instance.new("Frame")
            popup.AnchorPoint = Vector2.new(1, 0)
            popup.Position = UDim2.new(1, 0, 1, 4)
            popup.Size = UDim2.fromOffset(180, 110)
            popup.BackgroundColor3 = Tokens.GradientTop
            popup.BorderSizePixel = 0
            popup.ZIndex = 60
            popup.Visible = false
            popup.Parent = parent
            newCorner(popup, 6)
            newStroke(popup)

            local boxes = {}
            for i, ch in ipairs({ "R", "G", "B" }) do
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.fromOffset(10, (i - 1) * 28 + 8)
                lbl.Size = UDim2.fromOffset(20, 22)
                lbl.Text = ch
                lbl.TextSize = 14
                lbl.TextColor3 = Tokens.TextColor
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.FontFace = Fonts.SemiBold
                lbl.BorderSizePixel = 0
                lbl.Parent = popup

                local box = Instance.new("TextBox")
                box.Position = UDim2.fromOffset(34, (i - 1) * 28 + 8)
                box.Size = UDim2.fromOffset(130, 22)
                box.BackgroundColor3 = Tokens.ElementBackground
                box.Text = tostring(math.round(obj.Value[ch] * 255))
                box.TextSize = 13
                box.TextColor3 = Tokens.TextColor
                box.FontFace = Fonts.Main
                box.BorderSizePixel = 0
                box.ClearTextOnFocus = false
                box.Parent = popup
                newCorner(box, 4)

                boxes[ch] = box

                trove:Connect(box.FocusLost, function()
                    local n = tonumber(box.Text)
                    if n == nil then
                        syncBoxes(obj.Value)
                        return
                    end
                    n = math.clamp(math.floor(n + 0.5), 0, 255)
                    local r = ch == "R" and n or math.round(obj.Value.R * 255)
                    local g = ch == "G" and n or math.round(obj.Value.G * 255)
                    local b = ch == "B" and n or math.round(obj.Value.B * 255)
                    obj:Set(Color3.fromRGB(r, g, b))
                end)
            end

            obj._popup = popup
            obj._boxes = boxes
        end

        row:AttachRight(function(parent)
            local swatch = Instance.new("TextButton")
            swatch.AnchorPoint = Vector2.new(1, 0.5)
            swatch.Position = UDim2.fromScale(1, 0.5)
            swatch.Size = UDim2.fromOffset(26, 26)
            swatch.BorderSizePixel = 0
            swatch.BackgroundColor3 = obj.Value
            swatch.Text = ""
            swatch.AutoButtonColor = false
            swatch.Parent = parent
            newCorner(swatch, 5)
            newStroke(swatch)
            obj._rt = swatch

            trove:Connect(swatch.MouseButton1Click, function()
                if obj._popup == nil then
                    buildPopup(swatch)
                end
                obj._popup.Visible = not obj._popup.Visible
            end)

            return swatch
        end)

        function obj:Set(v, instant)
            if typeof(v) ~= "Color3" then return end
            if v == self.Value then return end
            self.Value = v
            if self._rt then self._rt.BackgroundColor3 = v end
            syncBoxes(v)
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
