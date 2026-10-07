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
            Label = spec.Label or "Button",
            Clicked = Signal.new(),
            _onClick = spec.OnClick or function() end,
            _variant = spec.Variant or "default",
            _title = nil,
        }

        row:AttachRight(function(parent)
            local isPrimary = obj._variant == "primary"
            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.fromScale(1, 0.5)
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.BackgroundColor3 = isPrimary and Tokens.Accent or Tokens.ElementBackground
            btn.Parent = parent
            newCorner(btn, 5)
            newStroke(btn)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.fromScale(1, 1)
            label.Text = obj.Label
            label.TextSize = 14
            label.FontFace = Fonts.SemiBold
            label.TextColor3 = isPrimary and Color3.new(1, 1, 1) or Tokens.TextColor
            label.BorderSizePixel = 0
            label.Parent = btn
            obj._title = label

            trove:Connect(btn.MouseButton1Click, function()
                obj.Clicked:Fire()
                obj._onClick()
            end)

            return btn
        end)

        function obj:SetLabel(l)
            self.Label = l
            if self._title then self._title.Text = l end
        end
        function obj:SetVisible(v) self.Row:SetVisible(v) end
        function obj:OnClick(fn) self._trove:Connect(self.Clicked, fn) return self end

        return obj
    end
end
