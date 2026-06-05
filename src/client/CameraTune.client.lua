-- src/client/CameraTune.client.lua  | makes the camera ignore decor/trees/houses so they never block
-- the view (only the outer invisible border constrains the player), and sets a comfortable zoom.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- raise min zoom so tall props can't shove the camera into the player's face
player.CameraMinZoomDistance = 12
player.CameraMaxZoomDistance = 90
player.CameraMode = Enum.CameraMode.Classic

-- decor/breakables/trees should not push the camera. We flag them non-collidable to the camera by
-- moving them to a CameraIgnore handling: set their parts' CanQuery so camera raycasts skip them.
local function ignore(inst)
	if inst:IsA("BasePart") then
		-- camera popper uses raycasts; CanCollide stays for gameplay where set, but we make purely
		-- decorative parts transparent to the camera by disabling their query when tagged.
		inst.CanQuery = false
	end
end

-- tag-driven: anything tagged "CamIgnore" (decor) is skipped by the camera
for _, t in ipairs({"SwayTree","Breakable","Facility","CamIgnore"}) do
	for _, inst in ipairs(CollectionService:GetTagged(t)) do
		if inst:IsA("Model") then for _,d in ipairs(inst:GetDescendants()) do ignore(d) end else ignore(inst) end
	end
	CollectionService:GetInstanceAddedSignal(t):Connect(function(inst)
		if inst:IsA("Model") then for _,d in ipairs(inst:GetDescendants()) do ignore(d) end else ignore(inst) end
	end)
end
