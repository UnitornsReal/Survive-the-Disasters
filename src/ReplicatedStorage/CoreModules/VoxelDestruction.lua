--[[
    Written by Pomatthew

    EXAMPLE:
    local part = script.Parent
    local voxelSize = 1
    local hitbox = VoxelDestruction.NewHitbox(part, voxelSize)
    hitbox:StartDestruction(time) -- Time is optional, without the time it'll just keep going until hitbox:DisableDestruction() is called
]]

--// Type
export type Hitbox = {
    hitBox: Part,
    isActive: boolean,
    applyForce: boolean,
    voxelSize: number,
}

--// Variables
local MAX_PARTS_PER_FRAME = 10 -- Limit the number of parts processed per frame
local partPool = {} -- Object pool for parts

--// Module
local VoxelDestruction = {}

--// Functions

-- Retrieve the root model or folder of a part
local function GetRoot(part: Part) : Model | Folder
    if part.Parent == workspace then return part end

    while part.Parent ~= workspace do
        part = part.Parent
    end

    return part
end

-- Check if a part is large enough to be divided
local function SizeCheck(part: Part, voxelSize: number) : boolean
    local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
    return (x/2 >= voxelSize) or (y/2 >= voxelSize) or (z/2 >= voxelSize)
end

-- Determine if a part can be divided
local function IsDividable(part: Part) : boolean
    local partParent = GetRoot(part)
    if not partParent:HasTag("Destructable") then return false end
    if not part:IsA("Part") and not part:IsA("UnionOperation") then return false end
    return true
end

-- Copy relevant properties from one part to another
local function CopyProperties(source: Part, target: Part)
    target.Color = source.Color
    target.Material = source.Material
    target.Transparency = source.Transparency
    target.Reflectance = source.Reflectance
    target.Anchored = source.Anchored
    target.CanCollide = source.CanCollide
    target.CastShadow = source.CastShadow

    if #source:GetChildren() > 0 then
        for _, child in pairs(source:GetChildren()) do
            local newChild = child:Clone()
            newChild.Parent = target
        end
    end
    -- Add more properties as needed
end

-- Retrieve a part from the pool or clone a new one if none are available
local function GetPooledPart(template: Part) : Part
    local part = table.remove(partPool) or template:Clone()
    CopyProperties(template, part) -- Copy properties from the template to the pooled part
    part:AddTag("Destructable")
    part.Parent = template.Parent
    return part
end

-- Return a part to the pool for reuse
local function ReturnPartToPool(part: Part)
    part:ClearAllChildren()
    part:RemoveTag("Destructable")
    part.Anchored = true
    part.AssemblyLinearVelocity = Vector3.zero
    part.Size = Vector3.new(1, 1, 1)
    part.CFrame = CFrame.new()
    part:SetAttribute("Reused", true) -- For debugging purposes
    part.Parent = nil -- Temporarily remove it from the workspace
    table.insert(partPool, part)
end

-- Divide a part into two smaller parts along a given axis
local function DividePart(part: Part, axis: Vector3)
    local a = GetPooledPart(part)
    local b = GetPooledPart(part)

    a.Size = part.Size * (-(axis/2) + Vector3.new(1,1,1))
    a.CFrame = part.CFrame * CFrame.new(-part.Size * (Vector3.new(1,1,1) * axis/4))

    b.Size = part.Size * (-(axis/2) + Vector3.new(1,1,1))
    b.CFrame = part.CFrame * CFrame.new(part.Size * (Vector3.new(1,1,1) * axis/4))
end

-- Subdivide a part into smaller parts based on the voxel size
local function SubdividePart(part: Part, voxelSize: number) : boolean
    local check = SizeCheck(part, voxelSize)
    if not check then return false end
    
    local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
    local greaterDimension  = math.max(part.Size.X, part.Size.Y, part.Size.Z) :: number
    local axis: Vector3 = Vector3.new(
        (x == greaterDimension) and 1 or 0,
        (y == greaterDimension) and 1 or 0,
        (z == greaterDimension) and 1 or 0
    )

    DividePart(part, axis)
    ReturnPartToPool(part) -- Return the old part to the pool

    return true
end

-- Apply random force to a part
local function applyForce(part: Part, force: number)
    part.AssemblyLinearVelocity = Vector3.new(math.random(-force, force), math.random(-force, force), math.random(-force, force))
end

--// Main Functions

-- Create a new hitbox instance
function VoxelDestruction.NewHitbox(hitBox: Part, voxelSize: number?) : Hitbox
    local self = setmetatable({}, {__index = VoxelDestruction})

    self.hitBox = hitBox
    self.isActive = true
    self.applyForce = true
    self.voxelSize = voxelSize or 1

    return self
end

-- Start the destruction process
function VoxelDestruction:StartDestruction(activeTime: number?)
    self.isActive = true

    if activeTime and activeTime > 0 then
        task.delay(activeTime, function() self:DisableDestruction() end)
    end

    task.spawn(function()
        while self.isActive do
            self:UnanchorInBounds()
            task.wait()
        end
    end)
end

-- Disable the destruction process
function VoxelDestruction:DisableDestruction()
    self.isActive = false
end

-- Unanchor parts in bounds and apply destruction logic
function VoxelDestruction:UnanchorInBounds(params: OverlapParams?)
    local parts
    repeat
        parts = workspace:GetPartsInPart(self.hitBox, params)
        if #parts == 0 then break end

        local processedCount = 0
        for i = 1, #parts do
            if processedCount >= MAX_PARTS_PER_FRAME then break end

            if not IsDividable(parts[i]) then
                parts[i] = nil
                continue
            end

            local divided = SubdividePart(parts[i], self.voxelSize)
            if not divided then
                parts[i]:RemoveTag("Destructable")
                parts[i].Anchored = false
                parts[i].Size = Vector3.new(self.voxelSize, self.voxelSize, self.voxelSize)
                if self.applyForce then applyForce(parts[i], 150) end
                parts[i] = nil
            end

            processedCount = processedCount + 1
        end

        task.wait()
    until #parts <= 0
end

return VoxelDestruction
