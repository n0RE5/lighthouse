# Lighthouse

Lighthouse is a lighting and atmosphere editor for Luanti. You can apply a visual filter to your world, adjust it while playing, or enable automatic scenes that follow player's surroundings.

Filters control brightness, color, shadows, glow, sky, fog clouds, sun, moon, stars, light curve settings and so on.

## Requirements

Use Luanti 5.18.0 or newer on both the server and client. Lighthouse requires features introduced in latest versions.

There are no required mod dependencies. Automatic scene selection supports Minetest Game and Ethereal biomes. MineClone 2 support is planned in a future releases...

## Apply a filter

Open **Scenes** with `/lh` command and choose a built-in preset.

**Preview** feature applies only to you and allows you to interactively adjust filters without affecting other players.

**Compare** switches between Preview and the engine defaults. **End Preview** restores your current world, automatic and personal settings.

**Apply** applies the filter globally (turns automation off!).

To create your own filter, adjust the settings in **Editor**, then save it under a new name in **Library**. Built-in presets cannot be overwritten. Saved filters and the applied world appearance are kept after a restart.

## Automatic scenes

Open **Environments** and enable **Automatic environments**, or enter:

```text
/lh auto on
```

The built-in `lighthouse` source chooses a scene for each player using their biome, world time, weather signal, height and whether they are underwater. Two players in different locations can see different scenes.

## Commands

| Command | Action |
| --- | --- |
| `/lh` | Open the editor |
| `/lh scene Golden Hour` | Preview a scene |
| `/lh preview` | Preview the current editor settings |
| `/lh next` and `/lh prev` | Preview another scene in the current category or biome family |
| `/lh compare` | Compare Preview with engine defaults |
| `/lh revert` | End Preview |
| `/lh apply` | Apply the current editor settings to the world and pause automation |
| `/lh auto on` and `/lh auto off` | Enable or disable automatic scenes |
| `/lh source lighthouse` | Select the built-in automation source |
| `/lh tool` | Give yourself the editor tool |

## Graphics and troubleshooting

Enable Bloom, volumetric lighting and dynamic shadows in your client's graphics settings to see the corresponding effects. Exposure controls also depend on the client's exposure settings. 

> To see all the Lighthouse effects players need to enable the listed options in the graphics settings.