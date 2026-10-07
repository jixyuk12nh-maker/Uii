return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Label = spec.Label or "",
        }

        row:AttachRight(function(parent)
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.Parent = parent

            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
            layout.Parent = holder

            local function bar(order)
                local f = Instance.new("Frame")
                f.BackgroundTransparency = 0.7
                f.BorderSizePixel = 0
                f.Size = UDim2.fromOffset(0, 1)
                f.LayoutOrder = order
                f.BackgroundColor3 = Tokens.TextColor
                f.Parent = holder
                local fi = Instance.new("UIFlexItem")
                fi.FlexMode = Enum.UIFlexMode.Fill
                fi.Parent = f
            end

            bar(0)

            if obj.Label ~= "" then
                local l = Instance.new("TextLabel")
                l.BackgroundTransparency = 1
                l.Size = UDim2.fromScale(0, 1)
                l.AutomaticSize = Enum.AutomaticSize.X
                l.Text = obj.Label:upper()
                l.TextSize = 12
                l.TextColor3 = Tokens.Unselected
                l.FontFace = Fonts.SemiBold
                l.LayoutOrder = 1
                l.BorderSizePixel = 0
                l.Parent = holder
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 8)
                pad.PaddingRight = UDim.new(0, 8)
                pad.Parent = l
            end

            bar(2)

            return holder
        end)

        function obj:SetLabel(l) self.Label = l end
        function obj:SetVisible(v) self.Row:SetVisible(v) end

        return obj
    end
end
