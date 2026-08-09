# Terminal Sanity

> Make it through a Polaris-style hackathon without running out of social energy, actual energy, or project momentum.

Terminal Sanity is a choice-driven Godot game about navigating a hectic hackathon weekend. Pick your traits, explore the venue, make decisions about your project and team, and put your resources on the line in quick rounds of blackjack.

Your goal is simple: reach the final presentation with enough project progress to place, while keeping your social life and stamina intact.

## Play Loop

1. Choose an exaggerated attribute, a technical focus, and how you arrived.
2. Explore the venue with the map arrows.
3. Make story decisions at each stage of the weekend.
4. When a decision costs social energy or energy, resolve that wager with blackjack.
5. Build project progress and reach the presentation.

Every run tracks three resources:

| Resource | Starts At | What It Does |
| --- | ---: | --- |
| Social energy | 5 | Lets you talk, present ideas, join activities, and make social wagers. |
| Energy | 5 | Pays for late nights, workshops, tournaments, and long work sessions. |
| Project progress | 0 / 10 | Determines whether you can place at the final presentation. |

## Blackjack Wagers

Wagers are not random menu outcomes: you play a quick hand of blackjack.

- **Win:** gain the wager back as profit and receive the event's success effect.
- **Lose:** lose the wager and miss the event opportunity.
- **Draw:** the wager is returned and the event has no effect.

The game locks the wager to the cost of the decision you selected, so every resource choice has a real consequence.

## Endings

Your final presentation and choices can lead to endings including:

- `I platinum'd Polaris` for a complete project and strong social energy.
- `Polaris Podium` for an 8+ point project with social support.
- `B > Avg` for an 8+ point project with no social energy left.
- `Hack Club Was the Friends We Made Along the Way` for finishing with a team.
- `Merge Conflicts` or `We Will Big Back This Club` when the weekend goes sideways.

## Controls

| Context | Controls |
| --- | --- |
| Venue map | Click an arrow to move between tiles. |
| Story events | Click a displayed choice. |
| Blackjack | Click **Hit** or **Stand**. Keyboard shortcuts: `H` and `S`. |
| Blackjack wager | Use `+1`, `-1`, then **Start!** when playing an unlocked hand. |

## Run Locally

### Requirements

- [Godot Engine 4.7](https://godotengine.org/download/)

### Start The Game

1. Clone this repository.
2. Import `project.godot` in the Godot Project Manager.
3. Open the project and press `F6` or use **Run Project**.

The configured main scene is `scenes/menu.tscn`.

## Export For Web

A Web export preset is included. In Godot:

1. Open **Project > Export**.
2. Select **Web**.
3. Export to `exports/index.html`.

## Project Structure

```text
scenes/
	menu.tscn          # Title screen, camera handoffs, scene composition
	who_are_you.tscn   # Opening player choices
	cutscenes.tscn     # Venue map and navigation arrows
	blackjack.tscn     # Wager minigame
scripts/
	global_signals.gd  # Persistent run state and game-wide signals
	cutscenes.gd       # Event sequence, wager handoff, and presentation ending
	blackjack.gd       # Blackjack rules, dealing, and payout result
	arrow.gd           # Clickable map navigation
assets/              # Cards, venue map art, and interface assets
```

## Built With

- Godot 4.7
- GDScript
- Godot Web export

## Design Notes

The full gameplay outline lives in [scripts/gameplay.md](scripts/gameplay.md). It documents the intended hackathon decisions, resource trades, and ending conditions that drive the in-game event sequence.
