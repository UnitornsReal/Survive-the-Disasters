--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local Client: Player = Players.LocalPlayer
local PlayerGui = Client.PlayerGui
local Bottom = PlayerGui:WaitForChild("MainGui").Bottom
local Holder = Bottom.Holder

--// Modules
local FrameController = {}
local Modules = require(ReplicatedStorage.Modules)

function FrameController.Init()
    for _, button in pairs(Holder:GetChildren()) do
        if button:IsA("TextButton") then
            local click = Modules.UIController.Connection(button)
            local uiGradient = button.TextLabel.UIGradient
            local firstColor = uiGradient.Color.Keypoints[1].Value

            click:RegisterDefaultTweens()
            click:AddShadow({
                Shape = "Circle", 
                Spread = 70,
                Transparency = 0.25,
                Color = firstColor,
                Events = {"MouseEnter", "MouseLeave"}
            })
        end
    end
end

return FrameController