-- src/server/Remotes.lua  | get-or-create RemoteEvents/Functions under ReplicatedStorage.Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = {}

local function folder()
	local f = ReplicatedStorage:FindFirstChild("Remotes")
	if not f then f = Instance.new("Folder"); f.Name = "Remotes"; f.Parent = ReplicatedStorage end
	return f
end

local function getOrMake(name, className)
	local f = folder()
	local r = f:FindFirstChild(name)
	if not r then r = Instance.new(className); r.Name = name; r.Parent = f end
	return r
end

function Remotes.event(name) return getOrMake(name, "RemoteEvent") end
function Remotes.func(name)  return getOrMake(name, "RemoteFunction") end

return Remotes
