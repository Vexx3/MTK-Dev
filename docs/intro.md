---
sidebar_position: 1
---

# Introduction

The Multi-Tower Kit (MTK) is a kit that lets you combine multiple [Juke's Towers of Hell](https://www.roblox.com/games/8562822414/) (JToH)-styled towers (or any obby made with the JToH Tower Creation Kit) into a single place, in a way that closely resembles a single realm from JToH itself. It uses a batteries-included approach, being distributed as a single place file with scripts and various components of the kit already set up. All you need to do is add the towers and portals, build the lobby, and customize anything else as you seem fit. After that, the place will be fully functional.

## Using the kit

### Adding a tower

Adding a tower is at the core of this kit, It's pretty much the whole reason one would use this kit. To add a tower, start by inserting a tower, or even a blank kit, into the workspace. After it is inserted, move it into the `Towers` folder.

![workspace Towers Folder](./images/workspace_towers.png)

Rename the tower to the acronym of the tower; Be reasonable, as it's acronym will be used as the tower's internal identifier, and will be shown next to the timer on the client's GUI.

The tower should be organized the same way any tower is normally organized. The kit folder should contain:

- The `Obby` folder which contains all of the normal, static parts. Most of which make up the gameplay of the tower.
- The `Frame` folder/model, which contains the parts that make up the frame of the tower. This functionally is exactly the same as the obby folder, but a distinction will be important in the future, as I plan on adding a low-detail mode[^1] to the kit in the future.
- The `ClientSidedObjects` folder contains all of the client objects for the tower. When the game loads, every tower’s `ClientSidedObjects` folder is moved into storage (`game.ServerStorage.TowerClientObjects`), and is served to a client whenever they load a tower.
  - Optionally, you may move this folder to the `TowerClientObjects` folder yourself in studio, just as long as the folder is renamed to be the same as the tower’s acronym.
  - The folder itself is optional too, the kit will function if this folder is removed completely, making it a true **“purist”**[^2] tower.

[^1]: Low-Detail Mode (LDM) is a feature in Juke’s Towers of Hell where the Obby folder’s contents of every tower are hidden, unless that tower is being played. However, the frame folder will be left untouched. The point of this feature is to put less stress on lower-end devices by having less things onscreen for the device to render.
[^2]: Although sometimes the definition is stretched to allow for purely cosmetic client objects, the MTK defines “purist” towers as having no client objects at all.