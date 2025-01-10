--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local coreModules = ReplicatedStorage:WaitForChild("CoreModules")

--// Modules
local Dependencies = { -- Modules list
    UIController = require(coreModules.UIController),
    ModularFramework = require(coreModules.ModularFramework),
    VoxelDestruction = require(coreModules.VoxelDestruction)
}

return Dependencies