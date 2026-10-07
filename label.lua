return function(Core)
    local Tokens = Core.Tokens
    local Fonts = Core.Fonts

    return function(menu, row, trove, spec)
        local obj = {
            _trove = trove,
            _menu = menu,
            Row = row,
            Label = spec.Label or "",
            _label = nil,
            _textColor = spec.TextColor,
        }

        row:AttachRight(function(parent)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.fromScale(1, 1)
            l.Text = obj.Label
            l.TextSize = spec.TextSize or 15
            l.TextXAlignment = Enum.TextXAlignment.Right
            l.TextColor3 = obj._textColor or Tokens.TextColor
            l.FontFace = Fonts.Main
            l.BorderSizePixel = 0
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.Parent = parent
            obj._label = l
            return l
        end)

        function obj:SetLabel(l)
            self.Label = l
            if self._label then self._label.Text = l end
        end
        function obj:SetColor(c)
            self._textColor = c
            if self._label then self._label.TextColor3 = c end
        end
        function obj:SetVisible(v) self.Row:SetVisible(v) end

        return obj
    end
end
