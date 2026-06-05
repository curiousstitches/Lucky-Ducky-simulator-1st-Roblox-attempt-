-- src/client/MenuUI.client.lua  | one tabbed menu: Play(rebirth+jeep), Tasks, Codes, Leaders
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SummonJeep   = Remotes:WaitForChild("SummonJeep")
local RebirthDo    = Remotes:WaitForChild("RebirthDo")
local GetProgress  = Remotes:WaitForChild("GetProgress")
local GetTasks     = Remotes:WaitForChild("GetTasks")
local ClaimQuest   = Remotes:WaitForChild("ClaimQuest")
local RedeemCode   = Remotes:WaitForChild("RedeemCode")
local GetLeaderboard = Remotes:WaitForChild("GetLeaderboard")
local SetMode      = Remotes:WaitForChild("SetMode")
local ModeSync     = Remotes:WaitForChild("ModeSync")
local GetIndex     = Remotes:WaitForChild("GetIndex")
local ClaimIndex   = Remotes:WaitForChild("ClaimIndex")
local DoSpin       = Remotes:WaitForChild("DoSpin")
local GetSpin      = Remotes:WaitForChild("GetSpin")
local ClanCreate   = Remotes:WaitForChild("ClanCreate")
local ClanJoin     = Remotes:WaitForChild("ClanJoin")
local ClanLeave    = Remotes:WaitForChild("ClanLeave")
local ClanInfo     = Remotes:WaitForChild("ClanInfo")
local ClanTop      = Remotes:WaitForChild("ClanTop")

local gui = Instance.new("ScreenGui")
gui.Name = "MenuUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(0, 1); openBtn.Position = UDim2.new(0, 16, 1, -16)
openBtn.Size = UDim2.new(0, 96, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 16; openBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
openBtn.Text = "☰ Menu"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(255, 200, 80)

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- tab bar
local tabbar = Instance.new("Frame")
tabbar.Position = UDim2.new(0, 12, 0, 8); tabbar.Size = UDim2.new(1, -56, 0, 40)
tabbar.BackgroundTransparency = 1; tabbar.Parent = panel
local tabLayout = Instance.new("UIListLayout", tabbar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 6)

local body = Instance.new("Frame")
body.Position = UDim2.new(0, 12, 0, 54); body.Size = UDim2.new(1, -24, 1, -64)
body.BackgroundTransparency = 1; body.Parent = panel

local pages = {}
local function makePage(name)
	local pg = Instance.new("ScrollingFrame")
	pg.Size = UDim2.fromScale(1, 1); pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0
	pg.ScrollBarThickness = 5; pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pg.CanvasSize = UDim2.new(0, 0, 0, 0); pg.Visible = false; pg.Parent = body
	local l = Instance.new("UIListLayout", pg); l.Padding = UDim.new(0, 8)
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pages[name] = pg
	return pg
end

local function show(name)
	for n, pg in pairs(pages) do pg.Visible = (n == name) end
	if name == "Play" then MenuRefreshPlay() end
	if name == "Tasks" then MenuRefreshTasks() end
	if name == "Leaders" then MenuRefreshLeaders() end
	if name == "Index" then MenuRefreshIndex() end
	if name == "Spin" then MenuRefreshSpin() end
	if name == "Clan" then MenuRefreshClan() end
end

local function tab(name)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 80, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(35, 38, 48); b.Font = Enum.Font.GothamBold; b.TextSize = 14
	b.TextColor3 = Color3.new(1, 1, 1); b.Text = name; b.Parent = tabbar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.Activated:Connect(function() show(name) end)
end

local function bigBtn(parent, text, color, cb)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -6, 0, 46)
	b.BackgroundColor3 = color; b.Font = Enum.Font.GothamBlack; b.TextSize = 16
	b.TextColor3 = Color3.new(1, 1, 1); b.Text = text; b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	b.Activated:Connect(cb)
	return b
end

local function infoLabel(parent, text)
	local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -6, 0, 0)
	t.AutomaticSize = Enum.AutomaticSize.Y; t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamMedium; t.TextSize = 15; t.TextWrapped = true
	t.TextColor3 = Color3.fromRGB(225, 225, 225); t.Text = text; t.Parent = parent
	return t
end

-- ===== PLAY (rebirth + jeep) =====
local playPage = makePage("Play")
local playInfo = infoLabel(playPage, "...")
function MenuRefreshPlay()
	local pr = GetProgress:InvokeServer() or {}
	playInfo.Text = ("🔧 LIFT KITS: %d  •  earnings x%.1f\nNext kit: %d Duck Droppings\nYou have: %d  •  Kindness streak: %d")
		:format(pr.rebirths or 0, pr.mult or 1, pr.nextCost or 0, pr.droppings or 0, pr.kindness or 0)
end
bigBtn(playPage, "🔧 INSTALL LIFT KIT (Rebirth)", Color3.fromRGB(255, 170, 60), function()
	RebirthDo:InvokeServer()
	MenuRefreshPlay()
end)
bigBtn(playPage, "🚙 SUMMON MY JEEP", Color3.fromRGB(120, 160, 90), function()
	SummonJeep:FireServer(); panel.Visible = false
end)
infoLabel(playPage, "Park your Jeep, then have a friend walk up and 'Duck it' — you BOTH get rewards, and you get a surprise duck. Spread it around for a kindness streak!")

-- ===== TASKS (daily quests) =====
local tasksPage = makePage("Tasks")
function MenuRefreshTasks()
	for _, c in ipairs(tasksPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local tasks = GetTasks:InvokeServer() or {}
	for i, q in ipairs(tasks) do
		local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 76)
		card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = tasksPage
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local n = Instance.new("TextLabel"); n.Position = UDim2.new(0, 12, 0, 8)
		n.Size = UDim2.new(0.62, 0, 0, 40); n.BackgroundTransparency = 1
		n.Font = Enum.Font.GothamBold; n.TextSize = 14; n.TextWrapped = true
		n.TextXAlignment = Enum.TextXAlignment.Left; n.TextYAlignment = Enum.TextYAlignment.Top
		n.TextColor3 = Color3.new(1, 1, 1); n.Text = q.name; n.Parent = card
		local p = Instance.new("TextLabel"); p.Position = UDim2.new(0, 12, 0, 48)
		p.Size = UDim2.new(0.62, 0, 0, 22); p.BackgroundTransparency = 1
		p.Font = Enum.Font.Gotham; p.TextSize = 13; p.TextXAlignment = Enum.TextXAlignment.Left
		p.TextColor3 = Color3.fromRGB(190, 195, 205)
		p.Text = ("%d/%d  •  reward: %s"):format(q.progress, q.target, q.reward); p.Parent = card
		local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -12, 0.5, 0); b.Size = UDim2.new(0, 96, 0, 44)
		b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextColor3 = Color3.new(1, 1, 1); b.Parent = card
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		if q.claimed then
			b.BackgroundColor3 = Color3.fromRGB(70, 74, 86); b.Text = "Claimed"; b.AutoButtonColor = false
		elseif q.progress >= q.target then
			b.BackgroundColor3 = Color3.fromRGB(70, 200, 110); b.Text = "Claim"
			b.Activated:Connect(function() ClaimQuest:InvokeServer(i); MenuRefreshTasks() end)
		else
			b.BackgroundColor3 = Color3.fromRGB(60, 64, 76); b.Text = "Go"; b.AutoButtonColor = false
		end
	end
end

-- ===== CODES =====
local codesPage = makePage("Codes")
infoLabel(codesPage, "Enter a code for free rewards:")
local codeBox = Instance.new("TextBox"); codeBox.Size = UDim2.new(1, -6, 0, 44)
codeBox.BackgroundColor3 = Color3.fromRGB(35, 38, 48); codeBox.Font = Enum.Font.GothamBold
codeBox.TextSize = 16; codeBox.TextColor3 = Color3.new(1, 1, 1); codeBox.PlaceholderText = "type code..."
codeBox.ClearTextOnFocus = false; codeBox.Text = ""; codeBox.Parent = codesPage
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 10)
bigBtn(codesPage, "REDEEM", Color3.fromRGB(120, 130, 245), function()
	if codeBox.Text ~= "" then RedeemCode:InvokeServer(codeBox.Text); codeBox.Text = "" end
end)
infoLabel(codesPage, "Try: WELCOME • QUACK • DUCKDUCKJEEP • SHIMMER")

-- ===== LEADERS =====
local leadersPage = makePage("Leaders")
function MenuRefreshLeaders()
	for _, c in ipairs(leadersPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	infoLabel(leadersPage, "🏆 Top Duck Tycoons (lifetime earnings)")
	local top = GetLeaderboard:InvokeServer() or {}
	if #top == 0 then infoLabel(leadersPage, "No entries yet — be the first!") end
	for i, e in ipairs(top) do
		local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 40)
		card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = leadersPage
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -16, 1, 0); t.Position = UDim2.new(0, 12, 0, 0)
		t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 14
		t.TextXAlignment = Enum.TextXAlignment.Left; t.TextColor3 = Color3.fromRGB(255, 221, 51)
		t.Text = ("#%d  %s — %s"):format(i, e.name, tostring(e.value)); t.Parent = card
	end
end

-- ===== MODE (Normal/Hardcore) lives on the Play page =====
local modeInfo = { unlocked = false, mode = "normal", unlockLevel = 150 }
ModeSync.OnClientEvent:Connect(function(d) modeInfo = d end)
local modeBtn = bigBtn(playPage, "🔥 TOGGLE HARDCORE", Color3.fromRGB(200, 70, 70), function()
	SetMode:InvokeServer(modeInfo.mode == "hardcore" and "normal" or "hardcore")
	task.wait(0.3); MenuRefreshPlay()
end)
local origPlay = MenuRefreshPlay
function MenuRefreshPlay()
	origPlay()
	local locked = not (modeInfo and modeInfo.unlocked)
	modeBtn.Text = locked and ("🔒 Hardcore (reach Lv " .. (modeInfo.unlockLevel or 150) .. " or VIP)")
		or (modeInfo.mode == "hardcore" and "🌿 Switch to NORMAL" or "🔥 Switch to HARDCORE (2.5x rewards)")
	modeBtn.BackgroundColor3 = locked and Color3.fromRGB(80, 60, 60) or Color3.fromRGB(200, 70, 70)
end

-- ===== INDEX =====
local indexPage = makePage("Index")
function MenuRefreshIndex()
	for _, c in ipairs(indexPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local s = GetIndex:InvokeServer() or {}
	for _, row in ipairs(s.rows or {}) do
		local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 44)
		card.BackgroundColor3 = row.discovered and Color3.fromRGB(34, 38, 50) or Color3.fromRGB(24, 26, 32)
		card.Parent = indexPage
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local t = Instance.new("TextLabel"); t.Position = UDim2.new(0, 12, 0, 0); t.Size = UDim2.new(0.6, 0, 1, 0)
		t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = row.discovered and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(120, 120, 130)
		t.Text = (row.discovered and ("📖 " .. row.name .. "  x" .. row.found) or ("❓ " .. row.name)); t.Parent = card
		local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -10, 0.5, 0)
		b.Size = UDim2.new(0, 90, 0, 34); b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.new(1,1,1); b.Parent = card
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		if row.claimed then b.BackgroundColor3 = Color3.fromRGB(70,74,86); b.Text = "Claimed"; b.AutoButtonColor = false
		elseif row.discovered then b.BackgroundColor3 = Color3.fromRGB(70,200,110); b.Text = "Claim"
			b.Activated:Connect(function() ClaimIndex:InvokeServer(row.name); MenuRefreshIndex() end)
		else b.BackgroundColor3 = Color3.fromRGB(50,54,64); b.Text = "Find it"; b.AutoButtonColor = false end
	end
end

-- ===== SPIN =====
local spinPage = makePage("Spin")
function MenuRefreshSpin()
	for _, c in ipairs(spinPage:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
	local s = GetSpin:InvokeServer() or {}
	infoLabel(spinPage, ("🎡 Daily Spin — %d/%d used today"):format(s.used or 0, s.allowed or 1))
	bigBtn(spinPage, "🎡 SPIN THE WHEEL", Color3.fromRGB(255, 180, 60), function()
		DoSpin:InvokeServer(); task.wait(0.3); MenuRefreshSpin()
	end)
	infoLabel(spinPage, "Prizes: Droppings, Splats, Lucky Ducks, and a rare MEGA Duck! VIP spins twice a day.")
end

-- ===== CLAN =====
local clanPage = makePage("Clan")
function MenuRefreshClan()
	for _, c in ipairs(clanPage:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextBox") then c:Destroy() end end
	local info = ClanInfo:InvokeServer() or {}
	if info.inClan then
		infoLabel(clanPage, ("🛡️ %s\nMembers: %d  •  Clan XP: %d%s"):format(info.name, info.members or 1, info.xp or 0, info.owner and "  •  👑 Owner" or ""))
		bigBtn(clanPage, "Leave Clan", Color3.fromRGB(200, 80, 80), function() ClanLeave:InvokeServer(); task.wait(0.3); MenuRefreshClan() end)
	else
		infoLabel(clanPage, "Create or join a clan — members pool earnings into Clan XP for the global clan board.")
		local box = Instance.new("TextBox"); box.Size = UDim2.new(1, -6, 0, 42); box.BackgroundColor3 = Color3.fromRGB(35,38,48)
		box.Font = Enum.Font.GothamBold; box.TextSize = 15; box.TextColor3 = Color3.new(1,1,1)
		box.PlaceholderText = "clan name..."; box.ClearTextOnFocus = false; box.Text = ""; box.Parent = clanPage
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
		bigBtn(clanPage, "Create Clan", Color3.fromRGB(150, 120, 255), function() if box.Text ~= "" then ClanCreate:InvokeServer(box.Text); task.wait(0.3); MenuRefreshClan() end end)
		bigBtn(clanPage, "Join Clan", Color3.fromRGB(120, 160, 230), function() if box.Text ~= "" then ClanJoin:InvokeServer(box.Text); task.wait(0.3); MenuRefreshClan() end end)
	end
	infoLabel(clanPage, "🏆 Top Clans")
	local top = ClanTop:InvokeServer() or {}
	for i, e in ipairs(top) do
		local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 34); card.BackgroundColor3 = Color3.fromRGB(30,33,44); card.Parent = clanPage
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -16, 1, 0); t.Position = UDim2.new(0, 12, 0, 0)
		t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Color3.fromRGB(180, 150, 255); t.Text = ("#%d %s — %d XP"):format(i, e.name, e.xp); t.Parent = card
	end
end

tab("Play"); tab("Tasks"); tab("Index"); tab("Spin"); tab("Clan"); tab("Codes"); tab("Leaders")

openBtn.Activated:Connect(function() panel.Visible = true; show("Play") end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
