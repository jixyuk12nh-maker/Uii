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
            Options = table.clone(spec.Options or {}),
            Value = spec.Default or (spec.Options and spec.Options[1]),
            Changed = Signal.new(),
            _onChanged = spec.OnChanged or function() end,
            _panel = nil,
            _panelScroll = nil,
            _rows = {},
            CloseOnSelect = spec.CloseOnSelect == true,
        }

        local function buildRows()
            if obj._panelScroll == nil then return end
            for _, r in ipairs(obj._rows) do r:Destroy() end
            obj._rows = {}
            for i, opt in ipairs(obj.Options) do
                local r = Instance.new("TextButton")
                r.Size = UDim2.new(1, -8, 0, 24)
                r.Position = UDim2.fromOffset(4, (i - 1) * 24 + 4)
                r.BackgroundTransparency = (opt == obj.Value) and 0.7 or 1
                r.BackgroundColor3 = Tokens.ElementBackground
                r.Text = ""
                r.AutoButtonColor = false
                r.BorderSizePixel = 0
                r.LayoutOrder = i
                r.Parent = obj._panelScroll
                newCorner(r, 4)

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, -8, 1, 0)
                lbl.Position = UDim2.fromOffset(8, 0)
                lbl.Text = tostring(opt)
                lbl.TextSize = 13
                lbl.TextColor3 = opt == obj.Value and Tokens.Accent or Tokens.TextColor
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.FontFace = Fonts.Main
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Parent = r

                trove:Connect(r.MouseButton1Click, function()
                    obj:Set(opt)
                    if obj.CloseOnSelect and obj._panel then
                        obj._panel.Visible = false
                    end
                end)

                table.insert(obj._rows, r)
            end
        end

        local function buildPanel(parent)
            local panel = Instance.new("Frame")
            panel.AnchorPoint = Vector2.new(1, 0)
            panel.Position = UDim2.new(1, 0, 1, 4)
            panel.Size = UDim2.new(1, 0, 0, math.min(#obj.Options * 24 + 8, 200))
            panel.BackgroundColor3 = Tokens.GradientTop
            panel.BorderSizePixel = 0
            panel.ZIndex = 60
            panel.Visible = false
            panel.Parent = parent
            newCorner(panel, 6)
            newStroke(panel)

            local scroll = Instance.new("ScrollingFrame")
            scroll.BackgroundTransparency = 1
            scroll.Size = UDim2.fromScale(1, 1)
            scroll.BorderSizePixel = 0
            scroll.CanvasSize = UDim2.fromOffset(0, #obj.Options * 24 + 8)
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = Tokens.Accent
            scroll.Parent = panel
            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = scroll
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 4)
            pad.PaddingBottom = UDim.new(0, 4)
            pad.Parent = scroll

            obj._panel = panel
            obj._panelScroll = scroll
            buildRows()
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
            label.Size = UDim2.new(1, -16, 1, 0)
            label.Position = UDim2.fromOffset(8, 0)
            label.Text = obj.Value ~= nil and tostring(obj.Value) or "Select"
            label.TextSize = 13
            label.TextColor3 = Tokens.TextColor
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.FontFace = Fonts.Main
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = btn
            obj._label = label

            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.AnchorPoint = Vector2.new(1, 0.5)
            arrow.Position = UDim2.new(1, -6, 0.5, 0)
            arrow.Size = UDim2.fromOffset(10, 10)
            arrow.Text = "v"
            arrow.TextSize = 11
            arrow.TextColor3 = Tokens.Unselected
            arrow.FontFace = Fonts.Main
            arrow.Parent = btn

            trove:Connect(btn.MouseButton1Click, function()
                if obj._panel == nil then
                    buildPanel(btn)
                end
                obj._panel.Visible = not obj._panel.Visible
            end)

            return btn
        end)

        function obj:Set(v, instant)
            if v == self.Value then return end
            self.Value = v
            if self._label then
                self._label.Text = v ~= nil and tostring(v) or "Select"
            end
            if self._panelScroll then
                buildRows()
            end
            if not instant then
                self.Changed:Fire(v)
                self._onChanged(v)
            end
        end
        function obj:Get() return self.Value end
        function obj:SetOptions(opts)
            self.Options = table.clone(opts or {})
            if self._panel then
                self._panel:Destroy()
                self._panel = nil
                self._panelScroll = nil
                self._rows = {}
            end
        end
        function obj:SetVisible(v) self.Row:SetVisible(v) end
        function obj:OnChanged(fn) self._trove:Connect(self.Changed, fn) return self end

        return obj
    end
end
