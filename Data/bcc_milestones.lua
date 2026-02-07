-- Guild Achieves - BCC (Burning Crusade Classic) Milestone Messages
-- Author: heyaapl
-- These messages are ONLY used in Burning Crusade Classic where achievements don't exist.
-- Instead, milestone level-ups (10, 20, 30, 40, 50, 58, 60, 70) are detected via guild roster polling.

--[[
Message Placeholders:
{player} - The player's name who leveled up
{level} - The level number they reached
]]

GuildAchievesData = GuildAchievesData or {}

-- =============================================================================
-- BCC LEVEL MILESTONE MESSAGES
-- Themed around The Burning Crusade, level 70 cap, Outland, and all things TBC
-- =============================================================================

GuildAchievesData.BCCLevels = {

	-- =========================================================================
	-- Level 10 - Baby Steps in Azeroth (20 messages)
	-- =========================================================================
	[10] = {
		"Grats {player}! Level 10! Only 60 more to go until you can actually see Outland.",
		"{player} just hit level 10! The Dark Portal is... very, very far away. Keep going.",
		"Level 10 for {player}! You've officially figured out which buttons make things die.",
		"{player} dinged 10! At this rate, the Burning Crusade will be the Burning Retirement.",
		"Congrats {player} on level 10! The boars of Elwynn Forest send their regards.",
		"{player} reached level 10! That's about one-seventh of the way to max. Glass half... partially full.",
		"Level 10, {player}! Illidan has absolutely no idea you exist yet. And that's probably fine.",
		"Grats {player}! 10 levels down. The Dark Portal doesn't even have you on the guest list yet.",
		"{player} hit 10! Double digits! The journey of a thousand deaths begins with a single ding.",
		"Level 10 for {player}! Your gear is terrible and your spec is wrong, but hey, progress!",
		"{player} dinged 10! Somewhere in Outland, a fel orc just yawned.",
		"Congrats {player}! Level 10! You can now die in slightly more interesting ways.",
		"{player} is level 10! That's enough to make a blood elf mildly acknowledge your existence.",
		"Level 10 {player}! You've graduated from hitting things with a stick to hitting things with a slightly better stick.",
		"Grats {player} on 10! Only 48 more levels until you're allowed through the Dark Portal.",
		"{player} reached level 10! The training wheels haven't come off yet, but they're loose.",
		"Level 10 for {player}! Azeroth's wildlife is starting to take you semi-seriously.",
		"{player} hit 10! The road to 70 is long, but at least the scenery changes occasionally.",
		"Congrats {player}! Level 10! Your character is now old enough to have an opinion about talents.",
		"{player} dinged 10! Pro tip: the glowing green portal in the Blasted Lands is your eventual goal. Eventually.",
	},

	-- =========================================================================
	-- Level 20 - Still on Foot, Getting Your Bearings (20 messages)
	-- In TBC Classic, the first mount is at level 30, not 20
	-- =========================================================================
	[20] = {
		"Grats {player}! Level 20! Still hoofing it for 10 more levels. Your feet are filing a complaint.",
		"{player} hit level 20! Almost a third of the way to the Dark Portal. Almost.",
		"Level 20 for {player}! The world is opening up. So is your repair bill.",
		"{player} dinged 20! No mount yet, but your legs are getting a great workout.",
		"Congrats {player} on level 20! The Burning Crusade is still a distant rumor at this point.",
		"{player} reached level 20! 10 more levels of walking before you can ride. Hang in there.",
		"Level 20, {player}! Halfway to Dark Portal eligibility. The demons can wait.",
		"Grats {player}! 20 levels in and your addiction is progressing nicely.",
		"{player} hit 20! The quests are getting more creative. 'Kill 10 of these slightly different things.'",
		"Level 20 for {player}! Outland is 38 levels away. That's practically next week. It's not.",
		"{player} dinged 20! Still walking everywhere like a true adventurer. A slow, tired adventurer.",
		"Congrats {player}! Level 20! You're starting to resemble an actual adventurer. Squint hard enough.",
		"{player} is level 20! The Horde and Alliance are both pretending they noticed.",
		"Level 20 {player}! Fun fact: Illidan has been waiting in the Black Temple longer than you've been playing.",
		"Grats {player} on 20! You've survived this long without quitting. That's the real achievement.",
		"{player} reached level 20! Two-sevenths of the way to max. The fractions will get better.",
		"Level 20 for {player}! Your class trainer is getting tired of seeing you. Good.",
		"{player} hit 20! Enjoy the classic zones while you can. Outland is... different.",
		"Congrats {player}! Level 20! Your quest log is full and your bags are fuller.",
		"{player} dinged 20! The journey continues. The repair costs also continue.",
	},

	-- =========================================================================
	-- Level 30 - First Mount! (20 messages)
	-- In TBC Classic, level 30 is when you can learn Apprentice Riding
	-- =========================================================================
	[30] = {
		"Grats {player}! Level 30! First mount time! Your legs can finally take a break.",
		"{player} hit level 30! You can ride now! No more running everywhere like a peasant.",
		"Level 30 for {player}! Mount acquired! Now you can travel to your death slightly faster.",
		"{player} dinged 30! Three-sevenths of the way to max, and you finally get to ride something.",
		"Congrats {player} on level 30! Your first mount! Assuming you can afford one. Can you? Awkward.",
		"{player} reached level 30! Outland is 28 levels away, but at least you can ride there now.",
		"Level 30, {player}! Halfway to 60, and you finally don't have to walk. About time.",
		"Grats {player}! 30 levels of walking and it's finally over. Mount up and never look back.",
		"{player} hit 30! The zones are getting bigger, but now you have a mount to match. Sort of.",
		"Level 30 for {player}! You now have enough abilities for an action bar crisis and a mount to ride away from it.",
		"{player} dinged 30! The demons of Outland have penciled you in for... eventually. At least you can ride there.",
		"Congrats {player}! Level 30! At this pace, Illidan might actually need to start preparing.",
		"{player} is level 30! First mount! Your character's calves were getting unreasonably huge from all that running.",
		"Level 30 {player}! The classic grind is real, but so is the dream of flying in Outland someday. For now, enjoy the ground mount.",
		"Grats {player} on 30! Your spec is probably a mess and your gear doesn't match, but hey, you have a mount now.",
		"{player} reached level 30! Fun fact: a level 70 could sneeze and one-shot you. But at least you'd die mounted.",
		"Level 30 for {player}! Mount training costs gold you don't have. The WoW experience in a nutshell.",
		"{player} hit 30! You're in the thick of classic Azeroth. Now you can explore it on horseback. Or kodo. Or ram.",
		"Congrats {player}! Level 30! Halfway to the portal, a third to the cap, and finally on a mount.",
		"{player} dinged 30! The adventure is picking up. Literally, you're moving faster now.",
	},

	-- =========================================================================
	-- Level 40 - Over the Hump (20 messages)
	-- In TBC Classic, epic ground mount is at 60, not 40
	-- =========================================================================
	[40] = {
		"Grats {player}! Level 40! Over the hump. Outland is 18 levels away and counting.",
		"{player} hit level 40! Over halfway to max. The Dark Portal is starting to seem real.",
		"Level 40 for {player}! You've been at this a while now. The mobs have started to notice.",
		"{player} dinged 40! Four-sevenths of the way to 70. I'll stop with the fractions soon. I won't.",
		"Congrats {player} on level 40! Mail armor, plate armor, new ranks... it's all happening.",
		"{player} reached level 40! The second half of the leveling experience begins. So does the burnout.",
		"Level 40, {player}! You're past the halfway mark. Outland is only 18 levels away.",
		"Grats {player}! 40 down, 30 to go. That's fewer levels than you've already done. Glass half full.",
		"{player} hit 40! The world is your oyster. An oyster full of quests and repair bills.",
		"Level 40 for {player}! You've been playing long enough to have opinions about talent specs. Dangerous.",
		"{player} dinged 40! The Burning Crusade content is getting closer. Can you feel the fel?",
		"Congrats {player}! Level 40! At 58 you can walk through the Dark Portal. Only 18 levels away.",
		"{player} is level 40! Middle-aged in leveling terms. The midlife crisis spec respec is coming.",
		"Level 40 {player}! Forty levels in and your slow mount is starting to feel even slower.",
		"Grats {player} on 40! Your character has seen more of Azeroth than most NPCs ever will.",
		"{player} reached level 40! The grind continues but the gear is getting better. Slightly.",
		"Level 40 for {player}! Hellfire Peninsula is preparing for your arrival. In 18 levels.",
		"{player} hit 40! Pro tip: save some gold for epic mount at 60 and flying at 70. You'll need it.",
		"Congrats {player}! Level 40! You're officially past the hump. Downhill from here. Metaphorically.",
		"{player} dinged 40! The Outland dream grows stronger. So does the 'just one more quest' urge.",
	},

	-- =========================================================================
	-- Level 50 - Outland on the Horizon (20 messages)
	-- =========================================================================
	[50] = {
		"Grats {player}! Level 50! Single digits away from the Dark Portal. The demons are getting nervous.",
		"{player} hit level 50! Only 8 more levels until Outland opens its doors. And its many, many demons.",
		"Level 50 for {player}! You can practically see the Dark Portal from here. Squint harder.",
		"{player} dinged 50! Five-sevenths of the way to max. The end is actually visible now.",
		"Congrats {player} on level 50! The classic zones are running out. Outland is warming up.",
		"{player} reached level 50! 50 down, 20 to go. You're in the home stretch of the home stretch.",
		"Level 50, {player}! Outland is 8 levels away. Your gear is ready. Your spirit? Questionable.",
		"Grats {player}! 50 levels of Azeroth under your belt. Time to start mentally preparing for green fire everywhere.",
		"{player} hit 50! The classic endgame zones are calling. So is the Dark Portal. It never shuts up.",
		"Level 50 for {player}! You're getting dangerously close to being useful in Outland.",
		"{player} dinged 50! You've been leveling long enough that your hearth to Ironforge feels like home.",
		"Congrats {player}! Level 50! The Blasted Lands are on the horizon. So is Hellfire Peninsula.",
		"{player} is level 50! At this point, the quest NPCs are starting to look at you with genuine respect.",
		"Level 50 {player}! Almost there. 'There' being a shattered dimension full of demons. Fun.",
		"Grats {player} on 50! Your raid leader is already planning your Karazhan attunement. At 70.",
		"{player} reached level 50! The countdown to Outland has officially begun. 8 levels. You got this.",
		"Level 50 for {player}! The mobs in your current zone are starting to feel beneath you. Literally.",
		"{player} hit 50! Illidan still has no idea who you are, but he's about to find out. In 20 levels.",
		"Congrats {player}! Level 50! The next 8 levels are all that stand between you and another dimension.",
		"{player} dinged 50! You've outlasted most players who said 'I'll just try this game for a bit.'",
	},

	-- =========================================================================
	-- Level 58 - The Dark Portal Opens! (SPECIAL MILESTONE - 30 messages)
	-- This is the level you can enter Outland through the Dark Portal
	-- =========================================================================
	[58] = {
		"Grats {player}! Level 58! The Dark Portal is open for you. Outland awaits, and it is not subtle about it.",
		"{player} hit level 58! Welcome to the club that gets to walk through a giant green swirly portal.",
		"Level 58 for {player}! You're officially portal-eligible. Hellfire Peninsula has been waiting for fresh heroes.",
		"{player} dinged 58! Through the Dark Portal you go. Fair warning: everything is on fire over there.",
		"Congrats {player} on level 58! The Burning Crusade literally starts now. Emphasis on the 'burning' part.",
		"{player} reached level 58! Outland awaits. Leave your expectations at the portal, the demons took them.",
		"Level 58, {player}! The Dark Portal is calling. It's been calling for a while, actually. Very persistent.",
		"Grats {player}! 58! You can now step into a broken planet full of demons. Everyone's jealous, obviously.",
		"{player} hit 58! Hellfire Peninsula: where your classic gear goes to die and get replaced by greens.",
		"Level 58 for {player}! The fel orcs of Hellfire send their warmest 'we will destroy you' wishes.",
		"{player} dinged 58! Step through the portal. Outland has mushroom forests, floating rocks, and existential dread.",
		"Congrats {player}! Level 58! Time to trade the familiar skies of Azeroth for a shattered space rock. Upgrade?",
		"{player} is level 58! The demons beyond the Dark Portal are adjusting their threat assessment. It's low. For now.",
		"Level 58 {player}! Through the portal and into the fire. Literally. Hellfire Peninsula is aptly named.",
		"Grats {player} on 58! Outland welcomes you with open arms. And by arms, I mean angry demons with axes.",
		"{player} reached level 58! Your Azeroth chapter is ending. Your 'what is this place' chapter begins.",
		"Level 58 for {player}! The Dark Portal doesn't have a bouncer anymore. You're in. Congratulations and condolences.",
		"{player} hit 58! Pro tip for Outland: if it glows green, it's probably bad. If it glows red, it's definitely bad.",
		"Congrats {player}! Level 58! Illidan whispers 'you are not prepared.' He's right. Go anyway.",
		"{player} dinged 58! The broken world of Draenor is your new playground. It's very broken. Very.",
		"Level 58, {player}! Outland bound! Your quest rewards are about to make your current gear weep.",
		"Grats {player}! 58! The Dark Portal is the most dramatic doorway you'll ever walk through. Until Karazhan.",
		"{player} hit level 58! Crossing into Outland. The loading screen alone is worth the 58 levels.",
		"Level 58 for {player}! Welcome to the Burning Crusade. Things are burning and being crusaded. As advertised.",
		"{player} dinged 58! Outland tip: the guys with the big wings are usually the ones you should avoid.",
		"Congrats {player} on 58! The portal awaits. Beyond it lies adventure, demons, and clown-colored gear.",
		"{player} is level 58! The Dark Portal is basically a door to a whole new world. A shattered, demon-infested world.",
		"Level 58 {player}! You made it to portal age. It's like a coming-of-age story, but with more fel fire.",
		"Grats {player}! 58! Pack your bags for Outland. Actually, empty your bags. You'll need the space.",
		"{player} reached level 58! The broken planet of Outland is your oyster. A fel-tainted, demon-guarded oyster.",
	},

	-- =========================================================================
	-- Level 60 - Classic Cap in a TBC World (30 messages)
	-- =========================================================================
	[60] = {
		"Grats {player}! Level 60! In another timeline, you'd be max level. In this one? Ten more to go.",
		"{player} hit level 60! Once upon a time, this was the top. Now it's just a scenic overlook on the way to 70.",
		"Level 60 for {player}! Classic cap reached, but the Burning Crusade has other plans for you.",
		"{player} dinged 60! Welcome to what used to be endgame. The new endgame is 10 levels up and full of demons.",
		"Congrats {player} on level 60! You're now max level... circa 2004. Welcome to the future.",
		"{player} reached level 60! Back in vanilla, guilds would have thrown a party. Now it's just Tuesday.",
		"Level 60, {player}! Ten more levels. That's it. You can almost taste the arena rating. Almost.",
		"Grats {player}! 60! If this were classic, you'd be raiding Molten Core right now. Instead, you're questing in Hellfire.",
		"{player} hit 60! The old ceiling is now just another floor. The real ceiling is at 70.",
		"Level 60 for {player}! Your vanilla ancestors would be proud. Your guild leader wants you at 70 by Friday.",
		"{player} dinged 60! Classic complete, Crusade in progress. Only 10 more levels to the promised land.",
		"Congrats {player}! Level 60! Double check your Hellfire Ramparts group. You're ready for it now.",
		"{player} is level 60! The old max level. In TBC, it's the 'your gear is about to get way better' level.",
		"Level 60 {player}! You can now run all the classic dungeons. Or, and hear me out, keep pushing to 70.",
		"Grats {player} on 60! You've outleveled everything in the old world. Outland still has surprises, though.",
		"{player} reached level 60! The final ten levels are the Burning Crusade experience. Embrace the chaos.",
		"Level 60 for {player}! Single digits away from max. The Outland endgame is within reach.",
		"{player} hit 60! You've powered through 60 levels. The remaining 10 are where the story gets good.",
		"Congrats {player}! Level 60! Your character is officially qualified for all TBC dungeon content. Go wild.",
		"{player} dinged 60! Azeroth is in your rearview mirror. Outland's endgame dungeons are dead ahead.",
		"Level 60, {player}! The last stretch. These 10 levels are prime Outland exploration territory.",
		"Grats {player}! 60! Karazhan is at 70, heroics are at 70, arena is at 70. Only 10 levels away.",
		"{player} hit level 60! If vanilla players could see you not stopping at 60, they'd be appalled.",
		"Level 60 for {player}! You're now in the 'just a few more levels' zone. We've heard that before.",
		"{player} dinged 60! The countdown to max level is in single digits. The excitement is palpable.",
		"Congrats {player} on 60! The Outland zones are getting more interesting. Nagrand awaits. It's gorgeous.",
		"{player} is level 60! Ten levels from the cap. Your TBC endgame career is about to start.",
		"Level 60 {player}! Classic cap? More like classic stepping stone. The Crusade demands you keep going.",
		"Grats {player}! 60! The finish line is visible. It's glowing green and surrounded by demons.",
		"{player} reached level 60! You've been playing long enough to have strong opinions about Shattrath.",
	},

	-- =========================================================================
	-- Level 70 - MAX LEVEL! The Burning Crusade Cap! (35 messages)
	-- =========================================================================
	[70] = {
		"Grats {player}! Level 70! You did it! Max level! The Burning Crusade has been thoroughly crusaded.",
		"{player} hit level 70! Welcome to the endgame. Where the real grind... uh... begins. Sorry.",
		"Level 70 for {player}! Max level! Illidan has officially been notified of your existence.",
		"{player} dinged 70! You are now prepared. Well, you're max level at least. Gear is another conversation.",
		"Congrats {player} on level 70! The cap! The top! The summit! Now the fun really starts.",
		"{player} reached level 70! Achievement unlocked: completed the leveling game. Now play the other game.",
		"Level 70, {player}! Max level achieved. Your quest log just went from 'level up' to 'get attuned.'",
		"Grats {player}! 70! You've reached the peak of the Burning Crusade. The view is mostly fire.",
		"{player} hit 70! Time for heroics, Karazhan, and the never-ending quest for better gear.",
		"Level 70 for {player}! Congratulations, you're now qualified to be told your gear isn't good enough.",
		"{player} dinged 70! The level cap! Your XP bar is gone and a reputation bar takes its place. Forever.",
		"Congrats {player}! Level 70! The leveling journey is over. The attunement journey is just beginning.",
		"{player} is level 70! Welcome to the club. Meetings are on raid night. Attendance is mandatory.",
		"Level 70 {player}! No more leveling. Just reputation, gear, keys, attunements, and... actually, there's a lot.",
		"Grats {player} on 70! You've reached the mountaintop. The mountain is in a shattered alien world, but still.",
		"{player} reached level 70! The Outland endgame welcomes you. Bring consumables and patience.",
		"Level 70 for {player}! Max level in TBC! Your arena career can now officially begin. And end. Repeatedly.",
		"{player} hit 70! The leveling race is over. The gear race begins. The gear race never ends.",
		"Congrats {player}! Level 70! You can now fly in Outland. Unless you're broke. Then you walk with shame.",
		"{player} dinged 70! The top of the mountain. Time to start climbing the gear ladder instead.",
		"Level 70, {player}! Karazhan is waiting. The chess event is the real final boss, by the way.",
		"Grats {player}! 70! From level 1 to max. Every boar you killed along the way would be proud.",
		"{player} hit level 70! The grind to 70 is done. The grind for everything else? Welcome to endgame.",
		"Level 70 for {player}! Max level! Your guild is already eyeing you for raid spots. Perform accordingly.",
		"{player} dinged 70! Welcome to the endgame where everyone has opinions about your spec.",
		"Congrats {player} on 70! You've reached the level cap. The rep cap is much, much further away.",
		"{player} is level 70! The Burning Crusade has been burned and crusaded. Well done.",
		"Level 70 {player}! Illidan awaits in the Black Temple. He's not prepared. Or so we keep telling ourselves.",
		"Grats {player}! 70! Max level! The XP bar is gone. In its place: an existential void. And dailies.",
		"{player} reached level 70! You can stop asking 'are we there yet.' You're there. Now gear up.",
		"Level 70 for {player}! Flying mount time! Unless you can't afford it, in which case, awkward.",
		"{player} hit 70! Congratulations. The real World of Warcraft starts at max level. Sorry about the first 70.",
		"Congrats {player}! Level 70! The Aldor and Scryers both want you on their side. Choose wisely. Or don't.",
		"{player} dinged 70! Max level! Heroic dungeon keys, raid attunements, and badge gear await. Deep breath.",
		"Grats {player}! 70! You've conquered every level the Burning Crusade has to offer. Take a bow. Then go farm.",
	},

	-- =========================================================================
	-- Generic Fallback Messages (10 messages)
	-- Used if no specific messages exist for a milestone level
	-- =========================================================================
	["Generic"] = {
		"Grats {player} on level {level}! Another milestone on the road through the Burning Crusade.",
		"{player} just dinged {level}! The journey to 70 continues.",
		"Level {level} for {player}! Keep pushing, the Dark Portal believes in you.",
		"{player} hit level {level}! The Burning Crusade milestone tracker approves.",
		"Congrats {player}! Level {level}! Progress is progress, and progress is good.",
		"{player} reached level {level}! Outland is getting closer with every ding.",
		"Level {level}, {player}! Another step toward the cap. You're doing great.",
		"Grats {player} on {level}! The guild is proud. Mostly. Keep going.",
		"{player} dinged {level}! The road to 70 has another milestone checked off.",
		"Level {level} for {player}! The Burning Crusade awaits your continued progress.",
	},
}
