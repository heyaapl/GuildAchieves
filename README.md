# Guild Achieves

**Automatically congratulates your guildies on their achievements with hilarious, sarcastic messages!**

When a guild member earns an achievement, Guild Achieves waits 1-3 seconds (to seem human) and then sends a randomly selected funny congratulation to guild chat. With **950+ unique messages** across all achievement categories, your guild chat will never be boring again!

---

## Features

### 🎯 Smart Achievement Batching (NEW in v1.1.0!)

No more spam! The addon intelligently handles multiple achievements:

- **3-second collection window** - Gathers all achievements before responding
- **Multi-achievement detection** - When one player earns multiple achievements at once
- **Group achievement detection** - When raid/dungeon groups earn the same achievement
- **Smart name formatting** - "Player1, Player2, Player3, and 22 others" for large groups

### 🎉 Combo Messages - One Player, Multiple Achievements

When someone levels up, finishes a dungeon, AND completes a questline all at once:
> "WHOA {player}! 3 achievements at ONCE?! Were you SAVING those up?! Show-off!"

**40 unique combo messages** for overachievers!

### 🏆 Group Celebration Messages

Different message pools based on group size - no more spamming 25 individual messages when a raid kills a boss!

| Group Size | Type | Example |
|------------|------|---------|
| 2-4 players | Small Group | "Look at {players} being COMPETENT together! Squad goals!" |
| 5-9 players | Dungeon Party | "DUNGEON DOMINATION! The instance didn't stand a CHANCE!" |
| 10-19 players | Raid | "TEN-MAN TAKEOVER! COORDINATION LEVEL: EXPERT!" |
| 20+ players | Large Raid | "TWENTY-FIVE MAN DOMINATION! THE GUILD IS UNSTOPPABLE!" |

**110 unique group messages** across all sizes!

### 😂 800+ Individual Achievement Messages

Every achievement category has **40 unique sarcastic/funny responses**:

| Category | Messages | Humor Style |
|----------|----------|-------------|
| **Level 10-90** | 40 per level | Extra sarcastic for milestones! |
| **Quests** | 40 | "Did you actually read the quest text?" |
| **Exploration** | 40 | "Found any treasure or just more mobs?" |
| **Dungeons** | 40 | "Did the healer survive this time?" |
| **Raids** | 40 | "The wipe counter... we won't mention it!" |
| **PvP** | 40 | "Someone got rekt!" |
| **Professions** | 40 | "Your auction house empire grows!" |
| **Reputation** | 40 | "All those dailies FINALLY paid off!" |
| **Pet Battles** | 40 | "Gotta catch 'em... wait, wrong game!" |
| **Scenarios** | 40 | "Quick content is BEST content!" |
| **World Events** | 40 | "Holiday champion!" |
| **General** | 40 | Fallback for everything else |

### 🎚️ Special Level Messages

**Level 85** gets special treatment with messages highlighting the upcoming grind:
> "Level 85, {player}! Hope you packed snacks because the road to 90 is LONG!"

**Level 90** celebrates the gear grind ahead:
> "MAX LEVEL! {player} hit 90! Congratulations! Your gear grind subscription is now ACTIVE!"

### ⚙️ Fully Configurable

- **Enable/Disable** the entire addon with one click
- **Category Toggles** - Turn off specific achievement types
- **Cooldown Control** - Prevent spam when multiple achievements happen
- **Self-Congratulation** - Option to congratulate yourself too!
- **Debug Mode** - See what's happening under the hood

### 🗺️ Minimap Button

- **Left-click** to toggle on/off
- **Right-click** to open settings

---

## Slash Commands

- `/guildachieves` or `/ga` - Open settings panel

---

## Installation

1. Download from CurseForge
2. Extract to `World of Warcraft/_classic_/Interface/AddOns/` (for MoP Classic; use `_retail_` for Retail or `_forever_` for WoW Forever)
3. Restart WoW or `/reload`
4. Check that "Guild Achieves" appears in your AddOns list

---

## Supported Versions

- ✅ **Mists of Pandaria Classic** (5.5.0)
- ✅ **World of Warcraft Retail** (12.1.7)
- ✅ **Classic Era** (1.15.x)
- ✅ **Burning Crusade Classic** (2.5.x)
- ✅ **Wrath of the Lich King Classic** (3.4.x)
- ✅ **Cataclysm Classic** (4.4.x)
- ✅ **WoW Forever** (1.60.x) - no achievements, so level-ups are congratulated instead (see below)

> **Burning Crusade Classic and WoW Forever** have no achievement system. On those clients the addon polls the guild roster every 30 seconds and congratulates level-ups instead. BCC congratulates milestone levels only (10/20/30/40/50/58/60/70). WoW Forever congratulates every level by default, with 600+ Vanilla-themed messages drawn from milestone, class-specific, level-range, and generic pools; a "Congratulate Every Level" toggle in General settings switches it to milestones only (10/20/30/40/50/60).

---

## Example Messages

**When someone hits Level 20:**
> "Grats {player}! Level 20! You can now ride a mount and look slightly less pathetic!"

**When someone completes a dungeon:**
> "Dungeon master {player}! The bosses fear your queue button!"

**When someone gets a PvP achievement:**
> "PvP warrior {player}! The enemy faction fears your keyboard!"

**When someone maxes a profession:**
> "Profession master {player}! Your skill bar is MAXED!"

**When one player earns multiple achievements at once:**
> "ACHIEVEMENT AVALANCHE from {player}! 4 at once! Were you HOARDING?!"

**When a dungeon group completes an achievement together:**
> "DUNGEON CLEARED! {players} earned {achievement}! The mobs are CRYING!"

**When a 25-man raid kills a boss:**
> "FULL RAID ACHIEVEMENT! 25 people! {achievement}! THIS IS WHAT PEAK PERFORMANCE LOOKS LIKE!"

---

## FAQ

**Q: Will this spam guild chat?**
A: No! The smart batching system collects achievements for 3 seconds before responding. Multiple achievements from one player become one message. Raid achievements for 25 players become one celebration!

**Q: What if my raid kills a boss and everyone gets the achievement?**
A: You'll get ONE epic group celebration message instead of 25 individual spam messages!

**Q: Can I turn off specific categories?**
A: Yes! Every category can be individually enabled/disabled in the settings.

**Q: Does this work for my own achievements?**
A: By default, no. But you can enable "Congratulate Yourself" in settings if you want!

**Q: Why the 1-3 second delay?**
A: So it doesn't look like an instant bot response! The randomized delay makes it feel more natural.

---

## Support

Found a bug or have a suggestion? Open an issue on GitHub!

---

*Made with ❤️ and sarcasm*
