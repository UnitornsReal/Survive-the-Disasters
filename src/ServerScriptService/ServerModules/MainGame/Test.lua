local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Test = {}
local Modules = require(ReplicatedStorage.Modules)

function Test.Init()
    local destroyPart = workspace.DestroyTest

    local destroy = Modules.VoxelDestruction.NewHitbox(destroyPart, 2)
    destroy:StartDestruction()
end

return Test