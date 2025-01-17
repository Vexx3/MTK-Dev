local PlayerData = require(script.Parent.Parent.Configs.Configuration)

export type PlayerData = PlayerData.PlayerData

export type StateAction = 
    {
        action: "UpdateTowers",
        towerCount: number,
    }

return function(playerData: PlayerData, action: StateAction)
    if action.action == "UpdateTowers" then
        playerData.towers += action.towerCount
    end
end
