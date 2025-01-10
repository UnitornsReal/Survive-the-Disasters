local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = require(ReplicatedStorage.Modules)
local Lightning = {
    Name = "🌩 Lighting 🌩",
    Time = 60,
    Points = 100,
    Running = false
}

local mapDimension1, mapDimension2: Vector3 = Vector3.new(-110.102, 0, 168.418), Vector3.new(231.748, 0, -160.082)

function Lightning.CreateLightning(startingPoint: Vector3, endPoint: Vector3)
    local parts = {}
    local points = {}
    local segmentCount = 10  -- Number of segments in the lightning bolt

    -- Generate random points between the starting and ending points
    for i = 0, segmentCount do
        local t = i / segmentCount
        local randomOffset = Vector3.new(
            math.random(-5, 5),  -- Random x offset
            0,  -- Random y offset
            math.random(-5, 5)  -- Random z offset
        )

        local point = startingPoint:Lerp(endPoint, t) + randomOffset
        table.insert(points, point)
    end

    for i = 1, #points - 1 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0)  -- Length based on distance between points
        part.Anchored = true
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(34, 174, 255)  -- White color for lightning

        part.Position = points[i]
        part.CFrame = CFrame.lookAt(part.Position, points[i + 1])
        part.Parent = workspace

        local tween: Tween = TweenService:Create(part, TweenInfo.new(0.0155), {Position = (points[i] + points[i + 1]) / 2, Size = Vector3.new(part.Size.X, part.Size.Y, (points[i] - points[i + 1]).Magnitude)})
        tween:Play()
        tween.Completed:Wait()

        table.insert(parts, part)
    end

    task.delay(0.5, function()
        for _, part in parts do
            part:Destroy()
        end
    end)
end

function Lightning.HandleDebris(debris: {BasePart})
    local force = 500/2
    for _, part in pairs(debris) do
        part.Anchored = false
        Modules.VoxelDestruction.BreakJoints(part)
        part:SetNetworkOwner(nil)
        part.AssemblyLinearVelocity = Vector3.new(math.random(-force, force), math.random(-force, force), math.random(-force, force))
		part.AssemblyAngularVelocity =  Vector3.new(math.random(-force / 2, force / 2), math.random(-force / 2, force / 2), math.random(-force / 2, force / 2))
        part.CanCollide = false
        task.delay(1, function()
            Modules.VoxelDestruction.ReturnPart(part)
        end)
    end
end

function Lightning.StartDisaster()
    Lightning.Running = true
    while Lightning.Running do
        local yStart = 250
        local startingPoint = Vector3.new(math.random(mapDimension1.X, mapDimension2.X), yStart, math.random(mapDimension2.Z, mapDimension1.Z))
        
        local rayResult  = workspace:Raycast(startingPoint, Vector3.new(0, -yStart, 0))

        if rayResult then
            local hitpoint = rayResult.Position
            local hitPart = rayResult.Instance

            Lightning.CreateLightning(startingPoint, hitpoint)
            local newHitboxPart: Part = ReplicatedStorage.Hitbox
            newHitboxPart.Position = hitpoint
            local hitbox = Modules.VoxelDestruction.NewHitbox(newHitboxPart, 1)
            local debris = hitbox:StartDestruction(10)
            --Lightning.HandleDebris(debris)
            --newHitboxPart:Destroy()
        end

        task.wait(0.25)
    end
end

function Lightning.StopDisaster()
    Lightning.Running = false;
end

return Lightning