local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Test = {}
local Modules = require(ReplicatedStorage.Modules)

function Test.Init()
    local tornadoPart = workspace.Tornado
    local tornado = Modules.VoxelDestruction.NewHitbox(tornadoPart.Hitbox, 2, true)
    local OverlapParams = OverlapParams.new()
    OverlapParams.FilterDescendantsInstances = {tornadoPart}
    OverlapParams.FilterType = Enum.RaycastFilterType.Exclude

    task.wait(4)

    tornado:StartDestruction(function(part: BasePart)
        part.Anchored = false
        local direction = (tornadoPart.Position - part.Position).Unit
        local impulseMagnitude = 1000
        part:ApplyImpulse(direction * impulseMagnitude)

        task.delay(1, function()
            part:Destroy()
        end)
    end, OverlapParams)

    while true do
        local randomDirection = Vector3.new(
            math.random() * 2 - 1, 
            0, 
            math.random() * 2 - 1
        ).Unit
    
        local startCFrame = tornadoPart.CFrame
        local endCFrame = startCFrame + randomDirection * 50  -- Adjust the multiplier as needed
    
        local tweenInfo = TweenInfo.new(
            5,  -- Duration of the tween
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            0,  -- Number of times to repeat the tween
            false,  -- Reverse the tween?
            0  -- Delay before starting the tween
        )
    
        local tweenGoal = {CFrame = endCFrame}
        local tween = TweenService:Create(tornadoPart, tweenInfo, tweenGoal)
    
        tween:Play()
        tween.Completed:Wait()
        task.wait(1)
    end
end

return Test