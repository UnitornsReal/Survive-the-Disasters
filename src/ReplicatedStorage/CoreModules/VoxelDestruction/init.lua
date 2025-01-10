--// Types
type partInfo = {Position: Vector3, Size: Vector3, Orientation: Vector3} 
type subdivisions = {partInfo}
export type Hitbox = {
	hitbox: BasePart,
	voxelSize: number,
	DividePart: (partInfo: partInfo, hitbox: BasePart, subdivisions: subdivisions) -> void,
	SubDivide: (parts: {BasePart}, hitbox: BasePart, maxDebris: number) -> {BasePart},
	IsWithinPart: (data: partInfo, part: BasePart) -> boolean,
	StartDestruction: (maxDebris: number) -> {BasePart}
}

--// Modules
local VoxelDestruction = {}
local Settings = require(script.Settings)
local Mesher = require(script.Mesher)
local Signal = require(script.Signal)

--// Functions
local function checkSize(size: Vector3, voxelSize: number): boolean
	return math.floor(size.X) <= voxelSize and  math.floor(size.Y) <= voxelSize and math.floor(size.Z) <= voxelSize
end

local function getRoot(part: Part) : Part | Model | Folder
	local root = part

	while root.Parent and root.Parent ~= workspace and not root.Parent:HasTag("Map") do
		root = root.Parent
	end

	return root
end

local function canDivide(part: BasePart) : boolean
	if not part:IsA("BasePart") then return false end
	if part:IsA("MeshPart") then return false end
	if not getRoot(part):HasTag(Settings.DestructionTag) then return false end
	if part:HasTag(Settings.DebrisTag) then return false end

	return true
end

local function createVoxel(originalPart: BasePart, sub: partInfo): BasePart
	local voxel = Settings.Cache:GetPart(CFrame.new(sub.Position) * CFrame.Angles(math.rad(sub.Orientation.X), math.rad(sub.Orientation.Y), math.rad(sub.Orientation.Z)))
	voxel.Size = sub.Size
	voxel.Material = originalPart.Material
	voxel.Anchored = originalPart.Anchored
	voxel.Color = originalPart.Color
	voxel.CanCollide = originalPart.CanCollide
	voxel.Transparency = originalPart.Transparency
	voxel.Parent = script.NewVoxels

	for _, child in pairs(originalPart:GetChildren()) do
		if child:IsA("BaseWrap") then continue end
		local clonedChild = child:Clone()
		clonedChild.Parent = voxel
	end

	if originalPart:HasTag(Settings.DestructionTag) then
		voxel:AddTag(Settings.DestructionTag)
	end

	return voxel, originalPart.Parent
end

--// Breaks any welds/motors the part is connected to
function VoxelDestruction.BreakJoints(Part:Part)
	for _,child in Part:GetJoints() do
		child:Destroy()
	end
end

--// Returns part to cache
function VoxelDestruction.ReturnPart(part: BasePart)
	Settings.Functions.ReturnPart(part)
end

--// Initialize Functions
function VoxelDestruction.NewHitbox(hitbox: BasePart, voxelSize: number?): Hitbox
	if not hitbox or not hitbox:IsA("Part") then warn("Hitbox is nil or an invalid type, make sure Hitbox exist and is a part!") return end 

	local self = setmetatable({}, {__index = VoxelDestruction})

	self.hitbox = hitbox
	self.voxelSize = voxelSize or 2

	return self
end

--// Hitbox Functions
function VoxelDestruction:DividePart(partInfo: partInfo, hitbox: BasePart, subdivisions: subdivisions)
	local position = partInfo.Position
	local rotation = partInfo.Orientation
	local size = partInfo.Size

	-- Check if the current part size is below or equal to voxel size
	if checkSize(size, self.voxelSize) then
		table.insert(subdivisions, { Position = position, Size = size, Orientation = rotation })
		return
	end

	-- Check if the part is within the hitbox
	if not VoxelDestruction.IsWithinPart({ Position = position, Size = size, Orientation = rotation }, hitbox) then
		table.insert(subdivisions, { Position = position, Size = size, Orientation = rotation })
		return
	end

	-- Determine which axis to split along
	local axisOperations = {
		X = { size = size.X, offset = Vector3.new(-size.X / 4, 0, 0), sizeDiv = Vector3.new(size.X / 2, size.Y, size.Z) },
		Y = { size = size.Y, offset = Vector3.new(0, -size.Y / 4, 0), sizeDiv = Vector3.new(size.X, size.Y / 2, size.Z) },
		Z = { size = size.Z, offset = Vector3.new(0, 0, -size.Z / 4), sizeDiv = Vector3.new(size.X, size.Y, size.Z / 2) }
	}
	-- Find the axis with the maximum size to split along
	local maxAxis = 'X'
	local maxSize = size.X

	for axis, op in pairs(axisOperations) do
		if size[axis] > maxSize then
			maxSize = size[axis]
			maxAxis = axis
		end
	end

	local axisOp = axisOperations[maxAxis]

	-- Calculate new sizes and positions
	local newSize1 = axisOp.sizeDiv
	local newSize2 = axisOp.sizeDiv
	local offset = axisOp.offset

	local offsetAdjustment = Vector3.new(
		maxAxis == 'X' and size.X / 2 or 0,
		maxAxis == 'Y' and size.Y / 2 or 0,
		maxAxis == 'Z' and size.Z / 2 or 0
	)

	-- Adjust the positions based on the rotation
	local cFrameRotation = CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	local newPos1 = position + (cFrameRotation * CFrame.new(offset)).Position
	local newPos2 = position + (cFrameRotation * CFrame.new(offset + offsetAdjustment)).Position

	local newParts = {
		{ Position = newPos1, Size = newSize1, Orientation = rotation },
		{ Position = newPos2, Size = newSize2, Orientation = rotation }
	}

	-- Recursively divide the new parts
	for _, part in pairs(newParts) do
		self:DividePart(part, hitbox, subdivisions)
	end
end



function VoxelDestruction:Subdivide(parts: {BasePart}, hitbox: BasePart, maxDebris: number): {BasePart}
	local debris = {}
	local voxels = {}
	local deleteParts = {}

	for _, part in pairs(parts) do
		if not canDivide(part) then continue end
		local subdivisions = {}

		self:DividePart({Position = part.Position, Size = part.Size, Orientation = part.Orientation}, hitbox, subdivisions)

		for _, sub in pairs(subdivisions) do
			local voxel, originalParent
			if not checkSize(sub.Size, self.voxelSize) then
				voxel, originalParent = createVoxel(part, sub)
			elseif checkSize(sub.Size, self.voxelSize) and #debris < maxDebris then
				voxel, originalParent = createVoxel(part, sub)
				voxel:AddTag(Settings.DebrisTag)
				table.insert(debris, voxel)
			end

			if voxel then table.insert(voxels, {voxel = voxel, originalParent = originalParent}) end
		end

		table.insert(deleteParts, part)
	end

		local parts = {}
		for _, v in pairs(voxels) do
			v.voxel.Parent = v.originalParent
			if not table.find(debris, v.voxel) then table.insert(parts, v.voxel) end
		end

	for _, part in pairs(deleteParts) do
		if not part:IsA("UnionOperation") then VoxelDestruction.ReturnPart(part) else part:Destroy() end
	end

	return debris
end

function VoxelDestruction.IsWithinPart(data: partInfo, part: BasePart)
	local shape = part.Shape
	local partPosition = part.Position
	local partSize = part.Size

	if shape == Enum.PartType.Ball then
		return VoxelDestruction.IsSphereWithinPart(data, part)
	elseif shape == Enum.PartType.Cylinder then
		return VoxelDestruction.IsCylinderWithinPart(data, part)
	elseif shape == Enum.PartType.Block then
		return VoxelDestruction.IsBoxWithinPart(data, part)
	else
		return false
	end
end

function VoxelDestruction.IsBoxWithinPart(data: partInfo, part: BasePart)
	local partCFrame = part.CFrame
	local partSize = part.Size
	local halfPartSize = partSize / 2

	-- Calculate the corners of the data box in world space
	local dataMin = data.Position - (data.Size / 2)
	local dataMax = data.Position + (data.Size / 2)

	-- Calculate the corners of the part box in world space
	local partMin = part.Position - halfPartSize
	local partMax = part.Position + halfPartSize

	-- Create local space for the part based on its CFrame
	local corners = {
		Vector3.new(partMin.X, partMin.Y, partMin.Z),
		Vector3.new(partMin.X, partMin.Y, partMax.Z),
		Vector3.new(partMin.X, partMax.Y, partMin.Z),
		Vector3.new(partMin.X, partMax.Y, partMax.Z),
		Vector3.new(partMax.X, partMin.Y, partMin.Z),
		Vector3.new(partMax.X, partMin.Y, partMax.Z),
		Vector3.new(partMax.X, partMax.Y, partMin.Z),
		Vector3.new(partMax.X, partMax.Y, partMax.Z)
	}

	-- Transform corners to local space
	for i, corner in ipairs(corners) do
		corners[i] = partCFrame:pointToObjectSpace(corner)
	end

	-- Check if data box overlaps with part box
	return (dataMin.X <= partMax.X and dataMax.X >= partMin.X and
		dataMin.Y <= partMax.Y and dataMax.Y >= partMin.Y and
		dataMin.Z <= partMax.Z and dataMax.Z >= partMin.Z) or
		(VoxelDestruction.CheckCornersAgainstDataBox(corners, dataMin, dataMax))
end

-- Helper function to check corners against the data box
function VoxelDestruction.CheckCornersAgainstDataBox(corners, dataMin, dataMax)
	for _, corner in ipairs(corners) do
		if corner.X >= dataMin.X and corner.X <= dataMax.X and
			corner.Y >= dataMin.Y and corner.Y <= dataMax.Y and
			corner.Z >= dataMin.Z and corner.Z <= dataMax.Z then
			return true
		end
	end
	return false
end

-- Sphere collision check
function VoxelDestruction.IsSphereWithinPart(data: partInfo, part: BasePart)
	local partRadius = math.min(part.Size.X, part.Size.Y, part.Size.Z) / 2
	local partCenter = part.Position

	-- Calculate the box center and half size from data
	local boxCenter = data.Position
	local boxHalfSize = data.Size / 2

	-- Find the closest point on the box to the sphere's center
	local closestPoint = Vector3.new(
		math.clamp(partCenter.X, boxCenter.X - boxHalfSize.X, boxCenter.X + boxHalfSize.X),
		math.clamp(partCenter.Y, boxCenter.Y - boxHalfSize.Y, boxCenter.Y + boxHalfSize.Y),
		math.clamp(partCenter.Z, boxCenter.Z - boxHalfSize.Z, boxCenter.Z + boxHalfSize.Z)
	)

	-- Transform the closest point into the local space of the part
	local localClosestPoint = part.CFrame:pointToObjectSpace(closestPoint)

	-- Calculate the distance from the sphere's center to this closest point
	local distance = (localClosestPoint - part.CFrame:pointToObjectSpace(partCenter)).Magnitude

	-- Check if the distance is less than or equal to the sphere's radius
	return distance <= partRadius
end

-- Cylinder collision check
function VoxelDestruction.IsCylinderWithinPart(data: partInfo, part: BasePart)
	-- Determine the cylinder's radius and height based on the part's size
	local cylinderRadius = math.min(part.Size.Y / 2, part.Size.Z / 2)
	local cylinderHeight = part.Size.X
	local cylinderCenter = part.Position

	-- Calculate the bounds of the data box
	local dataMin = data.Position - (data.Size / 2)
	local dataMax = data.Position + (data.Size / 2)

	-- Check if there is vertical overlap between the cylinder and the data box
	local heightOverlap = (dataMax.Y >= cylinderCenter.Y - (cylinderHeight / 2)) and
		(dataMin.Y <= cylinderCenter.Y + (cylinderHeight / 2))

	if not heightOverlap then
		return false
	end

	-- Project onto the XY plane and check circle overlap
	local closestPoint = Vector3.new(
		math.clamp(cylinderCenter.X, dataMin.X, dataMax.X),
		cylinderCenter.Y,
		math.clamp(cylinderCenter.Z, dataMin.Z, dataMax.Z)
	)

	-- Transform the closest point and the cylinder center into the local space of the part
	local localClosestPoint = part.CFrame:pointToObjectSpace(closestPoint)
	local localCylinderCenter = part.CFrame:pointToObjectSpace(cylinderCenter)

	-- Calculate the distance between the transformed closest point and the transformed cylinder center
	local distance = (localClosestPoint - localCylinderCenter).Magnitude

	-- Check if the distance is less than or equal to the cylinder's radius
	return distance <= cylinderRadius
end

function VoxelDestruction:StartDestruction(maxDebris: number)
	local maxDebris = maxDebris or 500
	--local partsInHitbox = workspace:GetPartsInPart(self.hitbox)

	--local debris = self:Subdivide(partsInHitbox, self.hitbox, maxDebris)
	
	Signal.FireAllClientsUnreliable("Destruction", self.hitbox, maxDebris, self.voxelSize)

	--return debris
end

Signal.ListenRemote("HitboxCheck", function(player: Player, divisions: subdivisions, hitbox: BasePart)
	for _, partInfo: partInfo in divisions do
		local isInHitbox = VoxelDestruction.IsWithinPart(partInfo, hitbox)
		if isInHitbox then continue else return false end
	end
	
	return true
end)

Signal.ListenRemote("Destruction", function(hitbox: BasePart, maxDebris: number, voxelSize: number)
	repeat task.wait() until hitbox
	
	local newHitbox = hitbox:Clone()
	local destruction = VoxelDestruction.NewHitbox(newHitbox, voxelSize)
	local partsInHitbox = workspace:GetPartsInPart(destruction.hitbox)
	
	local divisions: subdivisions = {}

	for _, part: BasePart in partsInHitbox do
		table.insert(divisions, {Position = part.Position, Size = part.Size, Orientation = part.Orientation})
	end
	
	--[[local result = Signal.InvokeServer("HitboxCheck", divisions, hitbox)
	if not result then return end]]
	
	local debris = destruction:Subdivide(partsInHitbox, destruction.hitbox, maxDebris)
	
	for _, part: BasePart in debris do
		part.Anchored = false
		part.CanCollide = false
		
		local direction = Vector3.new(math.random() - .5, math.random() - .5, math.random() - .5)
		part:ApplyImpulse(direction * 750)
		part:ApplyAngularImpulse(direction * 10000)
		
		task.delay(0.5, function()
			VoxelDestruction.ReturnPart(part)
		end)
	end
	
	newHitbox:Destroy()
end)

--// Return
return VoxelDestruction