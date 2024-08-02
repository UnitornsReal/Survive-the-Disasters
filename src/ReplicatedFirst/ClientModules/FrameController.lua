--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local Client: Player = Players.LocalPlayer
local PlayerGui = Client.PlayerGui
local TestBtn = PlayerGui:WaitForChild("MainGui").Test

--// Modules
local FrameController = {}
local Modules = require(ReplicatedStorage.Modules)

function FrameController.Init()
    local testClick = Modules.UIController.Connection(TestBtn)
    testClick:RegisterDefaultTweens()

    testClick:EnableTips("Test Tip", "Just a hover test, don't mind me!")

    task.wait(10)

    testClick:DisableTips()
end

return FrameController