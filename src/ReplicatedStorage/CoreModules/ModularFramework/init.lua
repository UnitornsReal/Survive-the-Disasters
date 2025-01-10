--// Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService");

--// Modules
local ModularFramework = {
    Modules = {},
}

--// Additional Functions
local function CallEvent(EventName: string, ...: any?)
    for name, script in pairs(ModularFramework.Modules) do
        if script[EventName] and typeof(script[EventName]) == "function" then
            task.spawn(function(...)
                local success, errMsg = pcall(script[EventName], ...)
                if not success then
                    warn("Error in module:", name, "Event:", EventName, "Error:", errMsg)
                end
            end, ...)
        end
    end
end

local function GetModules(path: Folder)
    for index, module in pairs(path:GetDescendants()) do
        if module:IsA("ModuleScript") then
            ModularFramework.Modules[module.Name] = require(module)
        end
    end

    ModularFramework.RunInits()
end
--// Main Functions
function ModularFramework.Load()
    local startTime: number = os.clock()

    if RunService:IsClient() then --// Runs scope of code if client
        local ClientModules: Folder = ReplicatedFirst.ClientModules
        GetModules(ClientModules)
    end

    if RunService:IsServer() then
        local ServerModules: Folder = ServerScriptService.ServerModules
        GetModules(ServerModules)
    end

    ModularFramework.SetUpEvents()

    print(`{RunService:IsClient() and "Client" or "Server"} Loaded in {tostring(os.clock() - startTime)} seconds!`);
end

function ModularFramework.RunInits()
    for name, script in pairs(ModularFramework.Modules) do
        if not script.Init then continue end

        task.spawn(function()
            local success, errMsg = pcall(script.Init)
            if not success then
                warn("Initialization error in module:", name, "Error:", errMsg)
            end
        end)
    end
end

function ModularFramework.SetUpEvents()
    local function CharacterAdded(character: Model)
        CallEvent("CharacterAdded", character)
    end

    local function PlayerAdded(player: Player)
        CallEvent("PlayerAdded", player)
        player.CharacterAdded:Connect(CharacterAdded)
    end

    local function PlayerRemoving(player: Player)
        CallEvent("PlayerRemoving", player)
    end

    Players.PlayerAdded:Connect(PlayerAdded)
    Players.PlayerRemoving:Connect(PlayerRemoving)
end

--// Return
return ModularFramework