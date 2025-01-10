--// Types
export type DataTemplate = {
    PlayerStats: {
        Survivals: number,
        Coins: number
    }
}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Modules
local DataManager = {
    Profiles = {} :: {Player},

    ValueTypes = {
        number = "NumberValue",
        string = "StringValue",
        boolean = "BoolValue"
    }
}

local DataTemplate: DataTemplate = require(script.DataTemplate)
local ProfileService = require(script.ProfileService)

--// Variables
local playerProfileStore = ProfileService.GetProfileStore("PlayerDataT2", DataTemplate) 

local function createValue(parent: Folder, data: any, name: string)
    local value = Instance.new(DataManager.ValueTypes[type(data)], parent)
    value.Name = name
    value.Value = data
end

--//  Additional functions
local function GiveInstances(player: Player)
    local profile = DataManager.Profiles[player]
    if not profile then warn(`Couldn't find player's {player.Name} profile`) return end

    local profileData: DataTemplate = profile.Data
    local playerData = Instance.new("Folder", player)
    playerData.Name = "PlayerData"

    for dataName1, data in pairs(profileData) do
        if typeof(data) == "table" then
            local folder = Instance.new("Folder", playerData)
            folder.Name = dataName1

            for dataName2, dataObject in pairs(data) do
                createValue(folder, dataObject, dataName2)
            end

            continue
        end

        createValue(playerData, data, dataName1)
    end
end

--// Main Functions 
function DataManager.PlayerAdded(player: Player)
    DataManager.LoadData(player)
end

function DataManager.PlayerRemoving(player: Player)
    DataManager.SaveData(player)
end

function DataManager.LoadData(player: Player)
    local profile = playerProfileStore:LoadProfileAsync(tostring(player.UserId))
    if not profile then warn(`Couldn't load player's {player.Name} profile`) return end

    profile:AddUserId(player.UserId)
    profile:Reconcile()

    profile:ListenToRelease(function()
        DataManager.Profiles[player] = nil

        if player:IsDescendantOf(Players) then
            player:Kick("Your profile has been loaded remotely. Please rejoin");
        end
    end)

    if not DataManager.Profiles[player] then
        DataManager.Profiles[player] = profile
        GiveInstances(player)
    end
end

function DataManager.SaveData(player: Player)
    if not RunService:IsStudio() then
        local profile = DataManager.Profiles[player]
        if not profile then warn(`Couldn't find player's {player.Name} profile`) return end
        profile:Release()
    end
end

function DataManager.SetData(player: Player, data: string | number | {}, value: string | number | boolean | {})
    local profile = DataManager.Profiles[player]
    if not profile then warn(`Couldn't find player's {player.Name} profile`) return end
    local profileData: DataTemplate = profile.Data
    local playerData = player.PlayerData

    if typeof(data) == "table" then
        profileData[data[1]][data[2]] = value
        player.PlayerData[data[1]][data[2]].Value = value
        return
    end

    playerData[data] = value
    player.PlayerData[data].Value = value
end

--// Return
return DataManager