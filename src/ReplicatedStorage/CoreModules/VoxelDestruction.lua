--[[
    Written by Pomatthew

    EXAMPLE:
    local part = script.Parent
    local voxelSize = 1
    local hitbox = VoxelDestruction.NewHitbox(part, voxelSize)
    hitbox:StartDestruction(time) -- Time is optional; without it, destruction will continue until hitbox:DisableDestruction() is called
]]

--// Variables
local partCache = {}
local poolSize = 1000
local destructTaG = "Destructible"

--// Modules
local VoxelDestruction = {}

--// Functions
local function initializeCache()
    for i = 1, poolSize do
        local part = Instance.new("Part")
        part.Parent = nil -- Keep parts out of workspace until needed
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1 -- Make parts invisible until used
        table.insert(partCache, part)
    end
end

local function getPartFromCache(): BasePart
    if #partCache > 0 then
        local part = table.remove(partCache)
        part.Transparency = 0 -- Make part visible when used
        part.Parent = workspace -- Add part to workspace
        return part
    else
        return Instance.new("Part") -- Create a new part if cache is empty
    end
end

local function returnPartToCache(part: BasePart)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1 -- Hide the part
    part.CFrame = CFrame.new(0, -100, 0) -- Move it out of the way
    part.Parent = nil -- Remove part from workspace
    part:ClearAllChildren()
    table.insert(partCache, part)
end

local function getRoot(part: Part) : Part | Model | Folder
    if part.Parent == workspace then return part end

    while part.Parent ~= workspace and not part.Parent:HasTag("Map") do
        part = part.Parent
    end

    return part
end

local function partDividable(part: BasePart)
    if part.Parent ~= workspace and not part.Parent:HasTag("Map") then
        part = getRoot(part)
    end

	if not part:HasTag(destructTaG) then return end

	return true
end

local function clonePart(template): BasePart
    -- Use part cache instead of cloning directly
    local part = getPartFromCache()

    for _, child in pairs(template:GetChildren()) do
        local newChild = child:Clone()
        newChild.Parent = part
    end

    part.Size = template.Size
    part.Anchored = template.Anchored
    part.CanCollide = template.CanCollide
    part.CFrame = template.CFrame
    part.Color = template.Color
    part.Material = template.Material
    part.Parent = template.Parent
    part.Name = template.Name

    if template:HasTag(destructTaG) then part:AddTag("Destructible") end

    return part
end

local function SizeCheck(part: Part, voxelSize: number) : boolean
    local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
    return (x/2 >= voxelSize) or (y/2 >= voxelSize) or (z/2 >= voxelSize)
end

--// Core Functions
function VoxelDestruction.Init()
    initializeCache()
end

function VoxelDestruction.NewHitbox(hitbox: Part, voxelSize: number, isLooped: boolean)
    local self = setmetatable({}, {__index = VoxelDestruction})

    self.hitbox = hitbox
    self.voxelSize = voxelSize
    self.isActive = false
    self.isLooped = isLooped or false

    self.remainingParts = {}

    return self
end

function VoxelDestruction:DividePart(part: BasePart, axis: Vector3)
	local a = clonePart(part)
	local b = clonePart(part)

	a.Size = part.Size * (-(axis/2)+Vector3.new(1,1,1))
	a.CFrame = part.CFrame * CFrame.new(-part.Size * (Vector3.new(1,1,1)*axis/4))	

	b.Size = part.Size * (-(axis/2)+Vector3.new(1,1,1))
	b.CFrame = part.CFrame * CFrame.new(part.Size * (Vector3.new(1,1,1)*axis/4))

    table.insert(self.remainingParts, a)
    table.insert(self.remainingParts, b)
end

function VoxelDestruction:Subdivide(part: Part)
    local check = SizeCheck(part, self.voxelSize)
    if not check then return false end
    
    local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
    local greaterDimension  = math.max(part.Size.X, part.Size.Y, part.Size.Z) :: number

    if greaterDimension == part.Size.X then
        self:DividePart(part, Vector3.new(1, 0, 0))
    elseif greaterDimension == part.Size.Y then
        self:DividePart(part, Vector3.new(0, 1, 0))
    elseif greaterDimension == part.Size.Z then
        self:DividePart(part, Vector3.new(0, 0, 1))
    end

    return true
end

function VoxelDestruction:StartDestruction(callback: () -> (), params: OverlapParams)
    self.isActive = true
    task.spawn(function()
        self:DestructInBounds(callback, params)
    end)
end

function VoxelDestruction:DestructInBounds(callback: () -> (), params: OverlapParams)
    local parts
    repeat
        parts = workspace:GetPartsInPart(self.hitbox, params)

        for _, part in ipairs(parts) do
            local handled = self:HandlePart(part, callback)
            part = nil
        end

        task.wait()
    until #parts <= 0 or not self.isActive

    if self.isLooped and self.isActive then self:StartDestruction(callback, params) end
end

function VoxelDestruction:HandlePart(part: BasePart, callback: () -> ())
    if not partDividable(part) then
        return false
    end

    local divided = self:Subdivide(part)
    if not divided then
        local smallerDimension = math.min(part.Size.X, part.Size.Y, part.Size.Z)
        part.Size = Vector3.new(smallerDimension, smallerDimension, smallerDimension)

        if part:HasTag(destructTaG) then part:RemoveTag(destructTaG) end
        part.Parent = workspace
        callback(part)
    else
        returnPartToCache(part)
    end

    return
end

function VoxelDestruction:GreedyMeshParts()

    local availableParts = {}

    for _, part in ipairs(self.remainingParts) do
        if part and part:IsA("BasePart") then
            table.insert(availableParts, part)
        end
    end

    if #availableParts > 0 then

    end

    for _, part in ipairs(availableParts) do
        if part then
            part:Destroy()
        end
    end

    self.remainingParts = {}
end

return VoxelDestruction