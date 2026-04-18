-- Guild Achieves - Midnight (12.0.1) Achievement Messages
-- Author: heyaapl
-- Messages themed around World of Warcraft: Midnight expansion
-- Covers Quel'Thalas, Voidstorm, Haranir, Prey, Devourer DH, Housing,
-- Midnight Keystones, new raids (Voidspire, Dreamrift, March on Quel'Danas),
-- new dungeons (Magister's Terrace, Windrunner Spire, Murder Row, etc.)

--[[
Message Placeholders:
{player} - The player's name who earned the achievement
{achievement} - The name of the achievement earned
{level} - The level number (for level achievements)
]]

GuildAchievesData = GuildAchievesData or {}

-- =============================================================================
-- MIDNIGHT CATEGORY MESSAGES
-- =============================================================================

GuildAchievesData.MidnightCategories = {

	-- =========================================================================
	-- Midnight Level 90 (the new retail cap in 12.0.1)
	-- =========================================================================
	MidnightLevel90 = {
		"Grats {player}! Level 90 in Midnight! Xal'atath is mildly concerned! Mildly!",
		"{player} hit 90! Welcome to the Midnight endgame! The Voidstorm is WAITING!",
		"Level 90 for {player}! Time to march on Quel'Danas! The Sunwell needs SAVING!",
		"{player} dinged 90! Max level! The Void has noticed your existence! RUDE of it!",
		"Congrats {player} on 90! Now the REAL grind begins! Delves, Mythic+, Housing, Prey!",
		"{player} reached level 90! Silvermoon City welcomes you! Watch for Void corruption!",
		"Level 90, {player}! The Voidstorm trembles! Or doesn't! It's a storm, it can't feel!",
		"Grats {player}! 90! You've reached the peak of Midnight! Now buy a HOUSE with your gold!",
		"{player} hit 90! Belo'ren is dusting off his boss abilities! Specifically for YOU!",
		"Level 90 for {player}! The Devourer demon hunters are JEALOUS of your dedication!",
		"{player} dinged 90! Alleria and Sylvanas both approve! In their own messed up ways!",
		"Congrats {player}! Level 90! Time to hunt Prey in Murder Row! SPOOKY name!",
		"{player} is level 90! The Haranir bioluminescent welcoming committee is READY!",
		"Level 90 {player}! Grats! Your character now lives in the Midnight endgame rent-free!",
		"Grats {player} on 90! Lorthemar is IMPRESSED! His standards are historically low!",
		"{player} reached level 90! Achievement: Survived the Voidstorm's gravitational pull!",
		"Level 90 for {player}! Welcome to season one! Now go do your Keystones! GO! GO!",
		"{player} hit 90! Xal'atath's machinations are threatened! BY YOU! Go ruin her day!",
		"Congrats {player}! Level 90! Dalaran is conspicuously absent! For ONCE!",
		"{player} dinged 90! Magister's Terrace has been REWORKED just for you! You're WELCOME!",
		"Level 90, {player}! The Sunwell needs saving! AGAIN! It can't stop getting corrupted!",
		"Grats {player}! 90! Time to Skyride through Eversong Woods! The foliage is GOLDEN!",
		"{player} hit level 90! Welcome to the Quel'Thalas tour! Zul'Aman is a FULL ZONE now!",
		"Level 90 {player}! The Dreamrift raid has ONE boss! That's efficient storytelling!",
		"{player} dinged 90! L'ura the Dark Naaru is checking your gear! She's unimpressed!",
		"Congrats {player} on 90! Housing awaits! Decorate that digital home of yours!",
		"{player} is 90! The Sin'dorei council has granted you permission to exist! GENEROUS!",
		"Level 90 {player}! Nexus-Point Xenas is PENCILED in for your first deaths! Exciting!",
		"Grats {player}! 90! The Prey system has you in its sights! YOU ARE the Preyseeker!",
		"{player} reached level 90! Velen is probably praying about this! He's always praying!",
	},

	-- =========================================================================
	-- Midnight Raids (Voidspire, Dreamrift, March on Quel'Danas)
	-- =========================================================================
	MidnightRaids = {
		"Grats {player} on {achievement}! The Voidstorm just got smaller! YOU did that!",
		"{player} cleared {achievement}! Xal'atath is filing a complaint with HR!",
		"Raid boss DOWN! {player} earned {achievement}! The loot table wept with joy! And fear!",
		"Grats {player}! {achievement}! Belo'ren sends his regards! From the AFTERLIFE!",
		"{player} finished {achievement}! The Sunwell is SLIGHTLY less corrupted! Progress!",
		"Achievement unlocked for {player}! {achievement}! L'ura is now feeling L'ucky! WAIT!",
		"Grats {player} on {achievement}! The Dreamrift is MILDLY embarrassed right now!",
		"{player} conquered {achievement}! Midnight Falls? More like Midnight BARELY CLEARED!",
		"Grats {player}! {achievement}! The Void just noticed you're the main character!",
		"{player} earned {achievement}! Quel'Danas is SAVED! For this week! Resets are brutal!",
		"Raid achievement for {player}! {achievement}! Add it to the Hall of Fame! MAYBE!",
		"Grats {player} on {achievement}! Your item level just went UP! Like your ego!",
		"{player} did {achievement}! The Voidspire quivered! Or it was an EARTHQUAKE! WHO KNOWS!",
		"Achievement: {achievement}! {player} is carrying this guild! PROBABLY! Let's check logs!",
		"Grats {player}! {achievement}! The Ashes of Belo'ren mount is IN YOUR SIGHTS!",
		"{player} completed {achievement}! The Horde and Alliance both salute! BEGRUDGINGLY!",
		"Raid night success! {player} got {achievement}! The healers cried! Tears of JOY!",
		"Grats {player} on {achievement}! Tier tokens incoming! Your Nullcore slots are HUNGRY!",
		"{player} finished {achievement}! Silvermoon's magisters are IMPRESSED! Or confused!",
		"Achievement {achievement} acquired by {player}! The Chiming Void Curio says HELLO!",
		"Grats {player}! {achievement}! You've saved Quel'Thalas AGAIN! It keeps needing SAVING!",
		"{player} cleared {achievement}! The Worldsoul Saga chapter continues! THANKS TO YOU!",
	},

	-- =========================================================================
	-- Midnight Dungeons / Mythic+ Keystones
	-- =========================================================================
	MidnightKeystones = {
		"Grats {player} on {achievement}! Another keystone BITES the dust! Or depletes! OOF!",
		"{player} earned {achievement}! The timer was KIND! This time!",
		"Keystone champion {player}! {achievement} unlocked! Calamitous Carrion is CLOSER!",
		"Grats {player}! {achievement}! Xal'atath's Bargain is giving you NIGHTMARES!",
		"{player} did {achievement}! Magister's Terrace is TIRED of seeing you!",
		"Achievement {achievement} for {player}! Degentrius is filing for workers' comp!",
		"Grats {player} on {achievement}! Murder Row's fel-smugglers are running SCARED!",
		"{player} finished {achievement}! Windrunner Spire's ghosts are MILDLY impressed!",
		"Keystone done! {player} got {achievement}! The Mythic+ leaderboard trembles! SLIGHTLY!",
		"Grats {player}! {achievement}! Nexus-Point Xenas just points back at YOU!",
		"{player} completed {achievement}! Maisara Caverns echoes with your VICTORY! And DEATHS!",
		"Mythic+ achievement for {player}! {achievement}! The affixes wish they knew you!",
		"Grats {player} on {achievement}! Nalorakk is DONE with your generation of adventurers!",
		"{player} cleared {achievement}! Pit of Saron made a return! Just for YOU! Kinda!",
		"Achievement: {achievement}! {player} is grinding keystones like it's a PART-TIME JOB!",
		"Grats {player}! {achievement}! The Calamitous Carrion mount caws in APPROVAL!",
		"{player} earned {achievement}! Skyreach is STILL a thing! WoW's favorite old dungeon!",
		"Keystone conqueror {player}! {achievement}! Your DPS meter is SMUG right now!",
		"Grats {player} on {achievement}! Seat of the Triumvirate says 'welcome back, sufferer'!",
		"{player} did {achievement}! Algeth'ar Academy is proud of its alumnus!",
	},

	-- =========================================================================
	-- Midnight Delves
	-- =========================================================================
	MidnightDelves = {
		"Grats {player} on {achievement}! Another delve CONQUERED! Brann is PROUD!",
		"{player} finished {achievement}! Solo content destroyed! You didn't need a group anyway!",
		"Delve champion {player}! {achievement}! The Nemesis delve is NEXT!",
		"Grats {player}! {achievement}! Giganto Manis acknowledges your existence! BARELY!",
		"{player} earned {achievement}! Bountiful delves beware! {player} is COMING!",
		"Achievement: {achievement}! {player} is a DELVE MASTER! At least for today!",
		"Grats {player} on {achievement}! The tier set from delves is ADEQUATE! HIGH PRAISE!",
		"{player} did {achievement}! Brann Bronzebeard is impressed! His standards are LOW!",
		"Delve done! {player} got {achievement}! Keys to Glory of the Midnight Delver inc!",
		"Grats {player}! {achievement}! Let Me Solo Him: Nullaeus says HI! Remember him?",
	},

	-- =========================================================================
	-- Prey System
	-- =========================================================================
	MidnightPrey = {
		"Grats {player} on {achievement}! The hunt is GOOD! Astalor Bloodsworn is PLEASED!",
		"{player} earned {achievement}! Preyseeker's Journey advances! LEVEL UP!",
		"Prey achievement for {player}! {achievement}! Construct V'anore is REVERBERATING!",
		"Grats {player}! {achievement}! The Preyseeker's Wrath is IMMINENT!",
		"{player} got {achievement}! Another rank in the Preyseeker's Journey! PROGRESS!",
		"Achievement: {achievement}! {player} is hunting like a TRUE sin'dorei! Edgy!",
		"Grats {player} on {achievement}! The Preyseeker's Nightmare mount is GLARING at you!",
		"{player} finished {achievement}! Murder Row is your OFFICE now! Shady office!",
		"Prey master {player}! {achievement}! The fel-smugglers are on YOUR list now!",
		"Grats {player}! {achievement}! Xal'atath's plans are UNRAVELING! Because of your HUNT!",
	},

	-- =========================================================================
	-- Housing (new in Midnight!)
	-- =========================================================================
	MidnightHousing = {
		"Grats {player} on {achievement}! Your house is NOT ON FIRE! Real estate achievement!",
		"{player} got {achievement}! Home decor in Azeroth! We're all Sims players now!",
		"Achievement: {achievement}! {player} is living the DOMESTIC life! Grats!",
		"Grats {player}! {achievement}! Your virtual mortgage is APPROVED! Digitally!",
		"{player} earned {achievement}! The neighbors are slightly envious! SLIGHTLY!",
		"Housing master {player}! {achievement}! Time to invite friends over! Or DON'T!",
		"Grats {player} on {achievement}! Feng shui in Azeroth is SURPRISINGLY hard!",
		"{player} did {achievement}! Housing patch is the REAL endgame! Who knew?!",
		"Achievement {achievement}! {player} has officially become AN ADULT! Sort of!",
		"Grats {player}! {achievement}! The Housing furniture vendor is RICH because of you!",
		"{player} finished {achievement}! Your WoW character has a better home than YOU do!",
		"Home sweet home {player}! {achievement}! Azeroth real estate values just went UP!",
	},

	-- =========================================================================
	-- Midnight Exploration (Quel'Thalas zones, Voidstorm, Harandar)
	-- =========================================================================
	MidnightExploration = {
		"Grats {player} on {achievement}! Quel'Thalas has been FULLY explored! By YOU!",
		"{player} earned {achievement}! Eversong Woods is GOLDEN! The foliage approves!",
		"Achievement: {achievement}! {player} has seen every Haranir mushroom in HARANDAR!",
		"Grats {player}! {achievement}! The Voidstorm's chaos has been MAPPED! Still chaotic!",
		"{player} got {achievement}! Zul'Aman is no longer just a RAID! It's a full ZONE now!",
		"Explorer {player}! {achievement}! Silvermoon City's back alleys are WELL DOCUMENTED!",
		"Grats {player} on {achievement}! The Dead Scar is HEALED! Plot convenience FTW!",
		"{player} finished {achievement}! Isle of Quel'Danas remembers you! From 2007!",
		"Achievement {achievement}! {player} has Skyridden through EVERY zone! No loading screens!",
		"Grats {player}! {achievement}! Cynosure of Twilight has SEEN things! And so have you!",
	},

	-- =========================================================================
	-- Devourer Demon Hunter / Class achievements
	-- =========================================================================
	MidnightClass = {
		"Grats {player} on {achievement}! The new Devourer DH spec is SAVAGE! Apparently!",
		"{player} earned {achievement}! Void Elves getting DH access was OVERDUE! But GOOD!",
		"Achievement: {achievement}! {player} is rocking the new class changes! ALL 10 talent points!",
		"Grats {player}! {achievement}! Class tuning patch gave you MORE power! FEARSOME!",
		"{player} got {achievement}! Soul-harvesting is CANON for your spec now! CREEPY!",
		"Class master {player}! {achievement}! Your rotation is IMMACULATE! Or it's AFK! HARD to tell!",
		"Grats {player} on {achievement}! The Devourer spec is EATING well tonight!",
		"{player} finished {achievement}! Void-themed midrange DPS is the NEW meta! Probably!",
		"Achievement {achievement}! {player} has mastered their class! Again! Each patch again!",
		"Grats {player}! {achievement}! Blizzard's class designers approve! QUIETLY!",
	},

	-- =========================================================================
	-- Haranir (new allied race)
	-- =========================================================================
	MidnightHaranir = {
		"Grats {player} on {achievement}! The Haranir are SHINY! Literally bioluminescent!",
		"{player} earned {achievement}! A fungal jungle ally! Every faction NEEDS one!",
		"Achievement: {achievement}! {player} has unlocked the MUSHROOM people! Grats!",
		"Grats {player}! {achievement}! Hara'ti rep grinding was WORTH it! Probably!",
		"{player} got {achievement}! The Ivory Grimlynx mount purrs in APPROVAL!",
		"Allied race achievement {player}! {achievement}! Light up the darkness LITERALLY!",
		"Grats {player} on {achievement}! Bioluminescent adventurers rejoice! That's YOU now!",
		"{player} finished {achievement}! The Haranir are GLAD you survived their trials!",
	},
}

-- =============================================================================
-- MIDNIGHT LEVEL 90 - OVERRIDE MESSAGES
-- These replace the generic "MoP level 90" messages when playing on retail Midnight
-- Only used when the client is actually Midnight (tocVersion >= 120000)
-- =============================================================================

GuildAchievesData.MidnightLevel90Messages = GuildAchievesData.MidnightCategories.MidnightLevel90
