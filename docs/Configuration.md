---
sidebar_position: 4
---

# Configuration

There exist many configuration modules throughout the kit that each serve their own purpose. Most properties inside these modules are documented inside of the modules themselves via comments. Otherwise, they are touched on in other parts of the manual. A list of all of them can be found below:

- `ServerScriptService.GameData.Config` – Settings for the server-side of the kit. Contains most general-purpose settings related to how the game should work.
- `ServerScriptService.GameData.Difficulties` – Contains every difficulty in the game, more information about this module can be found in [here](#configuring-difficulties).
- `ServerScriptService.GameData.KickMessages` – Nothing complex, just a list of messages that are randomly picked when the anti-cheat kicks a player from the game. All instances of `{Player}` will be replaced with the player’s username.
- `ServerScriptService.RealmData.TowerRushes` – Contains every tower rush in this realm. More information about it can be found in [here](#adding-a-tower-rush).
- `StarterPlayer.StarterPlayerScripts.MultiTowerClient.Config` – Settings for the client-side of the kit. Mostly cosmetic.

## Configuring difficulties

Many objects in the MTK (specifically Towers, Tower Rushes, and Endings), depend on Difficulty objects for describing it’s difficulty. These objects store information about single difficulty, it’s proper name, it’s color, etc.

All difficulty objects are stored in a `ModuleScript` named `Difficulties`, located in the `ServerScriptService.GameData` folder. From here you can modify existing difficulties, remove them, or add more. Here is a what an entry looks like:

```lua
Challenging = {
    Title = "Challenging",
    Rating = 5,

    FancyFont = false,
    Color = Color3.fromRGB(194, 0, 0),
    GlobalAnnouncement = false
},
```

- For this example, the **ID** of the difficulty is `Challenging`, the ID should be unique for every difficulty, as it’s used for referring to this difficulty by other objects in the MTK. For example, if I had a difficulty with the ID `Nefarious`, and I wanted to configure a tower to use this difficulty, I would set it’s `Difficulty` property to `Nefarious` as well.
- The `Title` property should be the proper name of the difficulty that is displayed to the players.
- The `Rating` property is currently unused, but describes the difficulty’s placement if mapped on the spectrum of every other difficulty. For example, JToH places Easy at 1, Medium at 2, Hard at 3, etc.
- The `FancyFont` property describes whether or not an alternate font should be used for win messages. If false, the default font used for chat messages are used, Source Sans Bold 18pt. Otherwise, Bodoni 20pt will be used instead. In JToH this is typically used for Catastrophic and above.
- The `Color` property describes the color of the difficulty, at the moment it’s only used for win messages.
- The `GlobalAnnouncement` property dictates whether or not completions of towers using this difficulty should be broadcast globally, meaning across all servers in the game. In JToH, this is used for all soul-crushing difficulties.

## Configuring endings

An `ending` is a special object that is unique to the towers themselves, and whenever a tower is beaten, an appropriate ending is selected depending on which winpad was touched, and uses it for displaying the win message.

The process of configuring endings is not immediately clear, whenever the place loads, the game will scan through every tower. For every tower it finds, a default ending is automatically created for that tower, inheriting the tower’s proper name and difficulty, as well as the tower’s acronym for the ending’s own ID. Furthermore, every tower has a unique list of endings, meaning 2 towers can have an ending with the same ID without there being problems, but this is not recommended as endings may be used in the future to track tower completions while differentiating alternate routes in towers.

| Example Tower 1 (ET1) | Example Tower 2 (ET2) |
| :-------------------: | :-------------------: |
|          ET1          |          ET2          |
|                       |       ET2Secret       |

An example of how the default MTK place has it’s endings configured, each tower has an ending inheriting it’s ID from the tower acronym. Meanwhile, `Example Tower 2` also has an alternate ending registered as `ET2Secret`.

To add an ending to a tower, start by giving it another winpad. In other words, add a part to the tower’s obby folder and name it `WinPad`. Next, add a `StringValue` to the winpad–and name it `EndingID`. Set the ending ID to any value, ideally formatted in PascalCase (though, it doesn’t matter), and just as long as it’s not the same as the tower’s acronym itself, as that ID is reserved for the tower’s default ending. You have now created an alternate ending for the tower! From here you can add extra properties to the ending.

:::note

If a winpad has no extra information (specifically an EndingID), it is implied that it triggers the default ending. So if you don’t want to bother configuring a tower’s endings, you do not need to do anything more for the tower’s winpad to be functional.

:::

![Example Secret Ending Winpad](./images/secret_ending.png)

Picture here is a winpad with extra properties added (especially EndingID), which will result in a new ending being created for this tower.

- The **EndingName** `StringValue` describes the proper name of the ending. If this value is not supplied it will default to the proper name of the tower.
- The **Difficulty** `StringValue` references the ID of a difficulty. If this value is omitted, it will inherit the difficulty from the tower.
- The **BadgeID** `IntValue` is the badge ID to award the player when this specific ending is reached. This is completely seperate from the tower’s own badge, and will be awarded alongside the tower’s badge, unless the `PreventTowerBadge` BoolValue is present and set to `true`. Furthermore, just like any other `BadgeID` property, no badge will be awarded if the ID value is set to 0.
- The **WinroomMarker** `StringValue` will determine where the player is teleported when this ending is reached. Normally, when an ending is reached, you are teleported to the `WinroomSpawn` in the `Markers` folder. However, if this value is present, it will search for any part in the markers folder named the value of this property, and teleport you to that part instead.

After doing this, you will have successfully added another ending to your tower! Of course, you can repeat this process as many times as you like, just as long as every ending ID is unique.

:::note

As of now, there is unfortunately no way to add multiple endings to a tower rush, as it has no list of endings. The tower rush’s own data is used for constructing a win message.

:::

## Adding a tower rush

To start, open up the `RealmData` folder in `ServerScriptService`, and open up the module in the folder named `TowerRushes`. This module contains the information for every tower rush in the realm. In order to add your own tower rush, duplicate the following code, and change the properties as explained below it:

```lua
ExampleTowerRush = {
    BadgeID = 0,
    Title = "Example Tower Rush",
    Difficulty = "Medium",
    WinroomMarker = "",
    Towers = {
        "ET1",
        "ET2",
    }
},
```

- `ExampleTowerRush` is the ID of the tower rush, change it to something sensible, like **Ring5TowerRush**, or **SecretTowerGauntlet**, etc.
- The `BadgeID` property serves the same function it does for towers. It is the ID of the badge to be awarded upon completion of the tower rush, if set to 0, no badge is awarded.
- The `Title` property is the proper, displayed name of the tower rush.
- The `Difficulty` property serves the same function it does for towers. It references the name of a difficulty, and should be representative of the tower rush’s overall difficulty
  - Again, for more information on configuring difficulties, see [here](#configuring-difficulties).
- The `WinroomMarker` property lets you choose where the player is teleported upon completion of the tower rush. If set to a blank string, it will simply teleport the player to the default win room; In other words, the `WinroomSpawn` part in the `Workspace.Markers` folder. Otherwise, it should be the name of any part in the markers folder.
- Finally, there is the `Towers` property. It contains an array of towers (described via their acronyms) in order of appearance. Every item in this array should be the name of one of the towers inside of the Workspace.Towers folder surrounded by double-quotation marks.

:::note

All tower rushes must have a unique ID for reference later, and must never conflict with another. Ideally they should be formatted in PascalCase, or be the acronym of the tower rush’s title, but it doesn’t truly matter.

:::

:::danger

In-case you are not familiar with Luau syntax, any item in a table must be separated by commas, if you do not do this, you will be met with an error. This applies to the entire tower rush info, and the tower acronyms in the `Towers` property.

:::

## Ever-present client objects

The MTK has included "ever-present client objects" (ECOs), these are client objects that are always loaded in, even when a player enters or leaves a tower. They are useful for adding client objects to the lobby, or adding decorative client objects to a tower that are always loaded in.

Implementing ECOs is fairly straightforward. All ECOs are located in the `EverpresentCOs` folder found inside the towers folder. Treat it like you would any `ClientSidedObjects` folder, simply insert COs into this folder and they will become ECOs.

![EverpresentCOs Folder](./images/everpresentcos.png)

The EverpresentCOs as found inside the Towers folder.

Furthermore, the kit also provides every CO from the JToH Kit V5.4 already inside of the ECO folder for easy access.

![EverpresentCOs Workspace](./images/ecosworkspace.png)

ECOs included in the kit for easy access.

## Creating a custom GUI

Creating a custom GUI for the MTK has always been a relatively easy task, assuming basic knowledge in creating UI in Roblox. You can format and organize anything in the TowerGUI ScreenGUI any way you want. As long as a UI element of a certain name exists, it will be controlled; You can even remove elements from the ScreenGUI, and it should still work.

## Adding items

You are free to implement items in whatever way you want, whether that be as simple as placing tools in the StarterPack, or creating some intricate system for managing it like what JToH itself has. However, there are a few things to know when adding items.

If you want to add a boost item, you need to make sure it’s marked as such. Reason for doing so is because boost items tend to let players progress through the tower in unusual ways not normally intended, so it’s necessary for the builtin anti-cheat measures to be disabled when this happens to stop a player from being kicked for beating the tower in an unnatural way that the boost item made possible. Debug items (like the Noclip and Heal tools) should also be marked as such.

:::tip

To mark an item as a boost item, add an attribute to it, name it `BoostName`, and make sure it’s type is `string`. To add a debug item that is only given to players in studio, place it in the `StarterPackStudio` folder, located in `ServerStorage`; It will automatically be marked as a debug item this way.

:::
