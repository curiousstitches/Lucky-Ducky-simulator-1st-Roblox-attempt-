-- src/shared/UIStyle.lua  | PS99-style cartoon UI helpers: thick outlines, fat rounded corners,
-- chunky drop-shadow buttons. Call these from client UIs to get a consistent bold look.
local UIStyle = {}

UIStyle.Colors = {
	panel   = Color3.fromRGB(28, 30, 44),
	stroke  = Color3.fromRGB(20, 22, 32),
	accent  = Color3.fromRGB(255, 200, 60),
	good    = Color3.fromRGB(80, 210, 120),
	text    = Color3.fromRGB(255, 255, 255),
}

-- fat rounded corners
function UIStyle.round(inst, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 16); c.Parent = inst
	return c
end

-- thick cartoon outline
function UIStyle.stroke(inst, color, thick)
	local s = Instance.new("UIStroke"); s.Color = color or UIStyle.Colors.stroke
	s.Thickness = thick or 3; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = inst
	return s
end

-- a chunky button with outline + corner + bold text
function UIStyle.button(parent, text, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color or UIStyle.Colors.good
	b.Font = Enum.Font.FredokaOne; b.TextSize = 18; b.TextColor3 = UIStyle.Colors.text
	b.AutoButtonColor = true; b.Text = text; b.Parent = parent
	UIStyle.round(b, 14); UIStyle.stroke(b, UIStyle.Colors.stroke, 3)
	return b
end

-- a styled panel
function UIStyle.panel(parent)
	local f = Instance.new("Frame"); f.BackgroundColor3 = UIStyle.Colors.panel; f.Parent = parent
	UIStyle.round(f, 18); UIStyle.stroke(f, UIStyle.Colors.accent, 3)
	return f
end

return UIStyle
