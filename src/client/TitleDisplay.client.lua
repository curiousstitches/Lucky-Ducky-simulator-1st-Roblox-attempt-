-- src/client/TitleDisplay.client.lua  | draws each player's equipped Title above their head
local Players = game:GetService("Players")

local function attach(player)
	local function setup(char)
		local head = char:WaitForChild("Head", 5); if not head then return end
		local old = head:FindFirstChild("TitleTag"); if old then old:Destroy() end
		local bb = Instance.new("BillboardGui")
		bb.Name = "TitleTag"; bb.Size = UDim2.new(0, 200, 0, 26); bb.StudsOffset = Vector3.new(0, 2.4, 0)
		bb.AlwaysOnTop = true; bb.Parent = head
		local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextStrokeTransparency = 0.4
		t.TextColor3 = Color3.fromRGB(255, 215, 60); t.Parent = bb
		local function refresh() local title = player:GetAttribute("Title"); t.Text = (title and title ~= "") and ("[ " .. title .. " ]") or "" end
		refresh()
		player:GetAttributeChangedSignal("Title"):Connect(refresh)
	end
	if player.Character then setup(player.Character) end
	player.CharacterAdded:Connect(setup)
end

for _, p in ipairs(Players:GetPlayers()) do attach(p) end
Players.PlayerAdded:Connect(attach)
