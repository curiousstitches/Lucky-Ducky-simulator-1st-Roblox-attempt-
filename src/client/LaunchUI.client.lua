-- src/client/LaunchUI.client.lua  | one-time starter wheel on first join + a Slots panel (4->60->120).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpinStarter = Remotes:WaitForChild("SpinStarter")
local GetSlots    = Remotes:WaitForChild("GetSlots")
local BuySlot     = Remotes:WaitForChild("BuySlot")
local InventoryChanged = Remotes:WaitForChild("InventoryChanged")

local gui = Instance.new("ScreenGui")
gui.Name="LaunchUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

-- ===== STARTER WHEEL (auto-opens once) =====
local function showStarter()
	local dim=Instance.new("Frame"); dim.Size=UDim2.fromScale(1,1); dim.BackgroundColor3=Color3.new(0,0,0)
	dim.BackgroundTransparency=0.4; dim.Parent=gui
	local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
	panel.Size=UDim2.new(0,320,0,300); panel.BackgroundColor3=Color3.fromRGB(28,30,42); panel.Parent=dim
	Instance.new("UICorner",panel).CornerRadius=UDim.new(0,20)
	Instance.new("UIStroke",panel).Color=Color3.fromRGB(255,215,90)
	local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,50); title.Position=UDim2.new(0,0,0,16)
	title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.TextSize=24; title.TextColor3=Color3.fromRGB(255,220,100)
	title.Text="🎡 STARTER WHEEL"; title.Parent=panel
	local duck=Instance.new("TextLabel"); duck.Size=UDim2.new(1,0,0,120); duck.Position=UDim2.new(0,0,0,60)
	duck.BackgroundTransparency=1; duck.Font=Enum.Font.GothamBlack; duck.TextSize=80; duck.Text="🦆"; duck.Parent=panel
	local info=Instance.new("TextLabel"); info.Size=UDim2.new(1,-20,0,40); info.Position=UDim2.new(0,10,0,176)
	info.BackgroundTransparency=1; info.Font=Enum.Font.GothamBold; info.TextSize=15; info.TextWrapped=true
	info.TextColor3=Color3.fromRGB(220,220,230); info.Text="Spin for your 2 starter ducks!"; info.Parent=panel
	local btn=Instance.new("TextButton"); btn.AnchorPoint=Vector2.new(0.5,1); btn.Position=UDim2.new(0.5,0,1,-18)
	btn.Size=UDim2.new(0,200,0,50); btn.BackgroundColor3=Color3.fromRGB(255,200,60); btn.Font=Enum.Font.GothamBlack
	btn.TextSize=20; btn.TextColor3=Color3.fromRGB(40,30,10); btn.Text="SPIN!"; btn.Parent=panel
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,14)
	btn.Activated:Connect(function()
		btn.Active=false; btn.Text="..."
		-- spin animation
		local faces={"🦆","🐤","🐥","🟡","✨"}
		for i=1,18 do duck.Text=faces[(i%#faces)+1]; task.wait(0.06) end
		local res=SpinStarter:InvokeServer()
		if res and res.ok then
			duck.Text= res.huge and "🦆✨" or "🦆🦆"
			info.Text= res.huge and "JACKPOT! A HUGE duck!!!" or ("Got: "..res.ducks[1].rarity.." + "..res.ducks[2].rarity.."!")
			btn.Text="CLAIM"; btn.Active=true
			btn.Activated:Connect(function() dim:Destroy() end)
		else
			info.Text=(res and res.reason) or "Already claimed"; task.wait(1); dim:Destroy()
		end
	end)
end

-- only show if not yet spun: ask server via slot info hook (starterSpun isn't sent, so spin returns reason if done)
task.delay(2, function()
	local info = GetSlots:InvokeServer()
	if info and not info.starterSpun then showStarter() end
end)

-- ===== SLOTS PANEL =====
local openBtn=Instance.new("TextButton"); openBtn.AnchorPoint=Vector2.new(1,1); openBtn.Position=UDim2.new(1,-16,1,-256)
openBtn.Size=UDim2.new(0,110,0,48); openBtn.BackgroundColor3=Color3.fromRGB(120,200,255); openBtn.Font=Enum.Font.GothamBlack
openBtn.TextSize=14; openBtn.TextColor3=Color3.new(1,1,1); openBtn.Text="➕ Slots"; openBtn.Parent=gui
Instance.new("UICorner",openBtn).CornerRadius=UDim.new(0,14)

local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0,420,0,360); panel.BackgroundColor3=Color3.fromRGB(20,22,30); panel.Visible=false; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(120,200,255)
local head=Instance.new("TextLabel"); head.Size=UDim2.new(1,-50,0,40); head.Position=UDim2.new(0,12,0,8)
head.BackgroundTransparency=1; head.Font=Enum.Font.GothamBlack; head.TextSize=18; head.TextXAlignment=Enum.TextXAlignment.Left
head.TextColor3=Color3.fromRGB(150,210,255); head.Text="➕ DUCK SLOTS"; head.Parent=panel
local close=Instance.new("TextButton"); close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-10,0,8)
close.Size=UDim2.new(0,36,0,36); close.BackgroundColor3=Color3.fromRGB(200,70,70); close.Font=Enum.Font.GothamBold
close.TextSize=20; close.TextColor3=Color3.new(1,1,1); close.Text="✕"; close.Parent=panel
Instance.new("UICorner",close).CornerRadius=UDim.new(1,0)
local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,-24,0,24); sub.Position=UDim2.new(0,12,0,46)
sub.BackgroundTransparency=1; sub.Font=Enum.Font.GothamBold; sub.TextSize=13; sub.TextXAlignment=Enum.TextXAlignment.Left
sub.TextColor3=Color3.fromRGB(200,205,215); sub.Text=""; sub.Parent=panel
local scroll=Instance.new("ScrollingFrame"); scroll.Position=UDim2.new(0,12,0,76); scroll.Size=UDim2.new(1,-24,1,-88)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=5; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.Parent=panel
local list=Instance.new("UIListLayout",scroll); list.Padding=UDim.new(0,8); list.HorizontalAlignment=Enum.HorizontalAlignment.Center

local function refresh()
	for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local info=GetSlots:InvokeServer() or {}
	sub.Text=("Active slots: %d  (free cap 60, Robux cap 120)"):format(info.current or 4)
	for _,row in ipairs(info.rows or {}) do
		local card=Instance.new("Frame"); card.Size=UDim2.new(1,-6,0,40); card.BackgroundColor3=Color3.fromRGB(30,33,44); card.Parent=scroll
		Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
		local t=Instance.new("TextLabel"); t.Position=UDim2.new(0,12,0,0); t.Size=UDim2.new(0.62,0,1,0); t.BackgroundTransparency=1
		t.Font=Enum.Font.GothamBold; t.TextSize=13; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextColor3=Color3.new(1,1,1)
		local price = row.splats>0 and (row.splats.." 💩 Splats") or (row.cost.." Droppings")
		t.Text=("+%d slots  •  %s"):format(row.slots, row.owned and "OWNED ✓" or price); t.Parent=card
		local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,0.5); b.Position=UDim2.new(1,-10,0.5,0); b.Size=UDim2.new(0,90,0,38)
		b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextColor3=Color3.new(1,1,1); b.Parent=card
		Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
		if row.owned then b.BackgroundColor3=Color3.fromRGB(70,74,86); b.Text="✓"; b.AutoButtonColor=false
		else b.BackgroundColor3=Color3.fromRGB(70,200,110); b.Text="Unlock"
			b.Activated:Connect(function() BuySlot:InvokeServer(row.id); task.wait(0.15); refresh() end) end
	end
	local note=Instance.new("Frame"); note.Size=UDim2.new(1,-6,0,40); note.BackgroundTransparency=1; note.Parent=scroll
	local nl=Instance.new("TextLabel"); nl.Size=UDim2.fromScale(1,1); nl.BackgroundTransparency=1; nl.Font=Enum.Font.Gotham
	nl.TextSize=12; nl.TextWrapped=true; nl.TextColor3=Color3.fromRGB(180,185,195)
	nl.Text="Slots 60→120 unlock via Robux passes in the Shop."; nl.Parent=note
end
openBtn.Activated:Connect(function() panel.Visible=true; refresh() end)
close.Activated:Connect(function() panel.Visible=false end)
