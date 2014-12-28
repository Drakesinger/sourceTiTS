const HYPNOSIS_LEVEL_MAX:int = 4;

/*
Lanes Hypnosis Mechnic
----

PC can freely be hypnotised once every 24 hours with no ill-effect.

If they return to Lane with an existing effect already in place, the hypnosis level will increase.

Hypnosis level increases by "decreasing" a seeded value by some modifier of the players willpower:

	Level 1: 75
	Level 2: 100
	Level 3: 125
	Level 4: 150

	=> 50 + (level * 25)

	On event   => current power += math.round(1.5 - pc.WQ() * 50)

	@ <= 25%  will == 5  events to go from 0 to level 3
	@ <= 50%  will == 7 events to go from 0 to level 3
	@ <= 100% will == 12 events to go from 0 to level 3

Once hypnosis level has increased, it will not decay outside of special events. I think there are some crew-related things that this will be hinged upon.

There are a number of status effects:
	"Lane's Hypnosis - [Stat]" -- These are used to track the individual treatments (and statboosts) that he can give the player, and are isolated so the player can have many.
	"Lane Hypnosis" -- This indicates that the player has been subject to Lane's illicit hypnosis.
*/

/*
Check if the player is subject to Lane's illicit hypnosis effect.
All of the stat-boosting effects will have unique names, so that they can co-exist, but each will create/bump this effect up as a hidden marker where appropriate.
*/
function hasLaneHypnosis():Boolean
{
	if (pc.hasStatusEffect("Lane Hypnosis")) return true;
	return false;
}

/*
Get the players current hypnosis level
*/
function laneHypnosisLevel():int
{
	if (flags["LANE_HYPNOSIS_LEVEL"] == undefined) return 0;
	else return flags["LANE_HYPNOSIS_LEVEL"];
}

/*
Figure out the level-up mechanic for hypnosis levels. Uses weights based on the PCs current hypnosis level versus the PCs willpower.
Returns true if a levelup occured.
*/
function increaseLaneHypnosisLevel():Boolean
{
	if (flags["LANE_HYPNOSIS_LEVEL"] == HYPNOSIS_LEVEL_MAX) return false;

	// Init the "power" tracker
	if (flags["LANE_HYPNOSIS_POWER"] == undefined)
	{
		flags["LANE_HYPNOSIS_POWER"] = (laneHypnosisLevel() * 25) + 50;
	}

	// Decrease power
	flags["LANE_HYPNOSIS_POWER"] -= math.round((1.5 - pc.WQ()) * 50); // This includes a potential will-boost from lanes stat bonuses, because fuck complicating this any more than it already is.

	// Check if "power" was entirely consumed, if so level up
	if (flags["LANE_HYPNOSIS_POWER"] <= 0)
	{
		flags["LANE_HYPNOSIS_LEVEL"] += 1;
		flags["LANE_HYPNOSIS_POWER"] = (laneHypnosisLevel() * 25) + 50;
		return true;
	}
	else
	{
		return false;
	}
}

/*
Decrease the PCs hypnosis level, and forces the level-up power required for the next hypnosis level to reset back to the default for the *new* lower level.
*/
function decreaseLaneHypnosisLevel():Boolean
{
	if (flags["LANE_HYPNOSIS_LEVEL"] > 0) flags["LANE_HYPNOSIS_LEVEL"] -= 1;
	flags["LANE_HYPNOSIS_POWER"] = undefined; // Force the next increase event to work from the "base" of the reduced level.
}

function hasMaxedLaneHypnosis():Boolean
{
	if (laneHypnosisLevel() >= HYPNOSIS_LEVEL_MAX) return true;
	return false;
}

function baseHypnosisWearsOff(effectToRemove:String):void
{
	clearOutput();
	if (flags["HYPNO_EFFECT_SMALL_MESSAGES"] == undefined)
	{
		if (flags["LANE_FIRST_HYPNO_RETURN"] != 2)
		{
			outputText("As you walk the biomes of {planet}, you can’t help but feel something is a little... off. Different, from when it was just a few moments ago. You flex your ears, listening for anything out of the ordinary, but you can’t hear anything. You look down your body, for anything alien that might have attached itself to you, but you’re completely clean.");

			outputText("\n\nFor whatever reason, you’re drawn to your codex, to know the time. It displays the time on all known and visited planets, including a clock for Terran’s time in the right hand corner. Seeing that clock there reminds you of something about Terran’s time, but what....");

			outputText("\n\nJust then, your thoughts are drawn to Lane. You recall the lizard-person’s hut in the caves of Venar, and the business {he} runs in hypnotism, and – wait. Hypnotism?");

			switch (effectToRemove)
			{
				case HYPNO_STAT_PHYS:
					outputText(" You look to your hands and make a pair of tight fists. Your grip is still plenty strong, but something just feels off somehow. You look to your bicep and you flex, and you swear your arm wasn’t as big as it was a few hours ago.");
					break;

				case HYPNO_STAT_REF:
					outputText(" You look around your feet for a pebble, or a coin, or something, and the glint of a rounded scrap of metal catches your eye. You pick it up and, without looking, toss it straight up into the air. When it passes your vision, you reach out to grab it, but you come up short, and it hits the ground in front of you.");
					break;

				case HYPNO_STAT_AIM:
					outputText(" You focus your eyes on the space around you, to the dust flitting through the air before your eyes. You spot a particular speck and try to focus on it, but it soon disappears in a cloud of likewise-looking specks, and then it might as well have vanished entirely.");
					break;

				case HYPNO_STAT_INT:
					outputText(" You start trying to do long division in your head. You recall an obscure method of doing it back in middle school – you could always get the first few steps down but then the lessons got murky the further you went, until it became just a total mess of numbers and integers. You probably could have worked it out an hour ago, but now your equation dissolves to nothing in your mind’s eye after a minute.");
					break;

				case HYPNO_STAT_WILL:
					outputText(" You place your [pc.tongue] firmly between your teeth. Lane gave you the strength of will, so if you wanted, you could probably draw blood if you bit hard enough. Just as you begin to bite yourself, the pain shocks you away from the notion, and you grunt. You don’t want to hurt yourself just to make a point to yourself, though you probably would have an hour ago.");
					break;

				case default:
					throw new Error("Couldn't match selected effect.")
					break;
			}

			outputText(" That lying Daynar" + lane.mf(" son of a", "") + " bitch gipped you out of your money! You paid to have something about you changed, and it only lasted a day! You don’t go to the doctor to cure a disease just for the weekend; you shouldn’t have to do the same with a hypnotist! The next time you’re on the planet, you make a mental note to yourself to give that scaly " + lane.mf("prick", "cunt") +" a piece of your mind.");
		}
		else
		{
			outputText("As you walk the biomes of {planet}, you hear a beep and feel a vibration on your [hip]. You reach for your codex; on it flashes a reminder you had programmed into it the day before about Lane’s hypnosis wearing off.");

			outputText("\n\nRight on time, you feel your body change, on a sort of metaphysical level.");

			switch (effectToRemove)
			{
				case HYPNO_STAT_PHYS:
					outputText(" You look to your hands and make a pair of tight fists. Your grip is still plenty strong, but something just feels off somehow. You look to your bicep and you flex, and you swear your arm wasn’t as big as it was a few hours ago.");
					break;

				case HYPNO_STAT_REF:
					outputText(" You look around your feet for a pebble, or a coin, or something, and the glint of a rounded scrap of metal catches your eye. You pick it up and, without looking, toss it straight up into the air. When it passes your vision, you reach out to grab it, but you come up short, and it hits the ground in front of you.");
					break;

				case HYPNO_STAT_AIM:
					outputText(" You focus your eyes on the space around you, to the dust flitting through the air before your eyes. You spot a particular speck and try to focus on it, but it soon disappears in a cloud of likewise-looking specks, and then it might as well have vanished entirely.");
					break;

				case HYPNO_STAT_INT:
					outputText(" You start trying to do long division in your head. You recall an obscure method of doing it back in middle school – you could always get the first few steps down but then the lessons got murky the further you went, until it became just a total mess of numbers and integers. You probably could have worked it out an hour ago, but now your equation dissolves to nothing in your mind’s eye after a minute.");
					break;

				case HYPNO_STAT_WILL:
					outputText(" You place your [pc.tongue] firmly between your teeth. Lane gave you the strength of will, so if you wanted, you could probably draw blood if you bit hard enough. Just as you begin to bite yourself, the pain shocks you away from the notion, and you grunt. You don’t want to hurt yourself just to make a point to yourself, though you probably would have an hour ago.");
					break;

				case default:
					throw new Error("Could find selected effect.");
					break;
			}
			outputText("\n\nYou sigh – it was fun while it lasted. You put your codex away and make a mental note to return to Lane about another boost the next time you’re in the area.");
		}
	}

	// Revert whatever stat the PC paid to increase back to normal
	// If the PC gets hypnotized multiple times, in more than one stat, I think it might be better to revert them all at the same time, starting the clock with the first hypnosis they get (so they can’t wait 23 hours and then scum the clock back). This is mostly just to avoid having the ‘hypnosis wears off’ message several times in succession, but this is, of course, just a suggestion.

	// Rather than removing them all at once, the first one removed trips a flag that will change us from delivering the "full fat" messages, to a lite message.
	// TODO: Add this small message!
	flags["HYPNO_EFFECT_SMALL_MESSAGES"] = 1;

	var modValue:Number = 0;

	switch (effectToRemove)
	{
		case HYPNO_STAT_PHYS:
			modValue = pc.statusEffectv1("Lane's Hypnosis - Physique");
			pc.physiqueMod -= modValue;
			pc.removeStatusEffect("Lane's Hypnosis - Physique");
			break;

		case HYPNO_STAT_REF:
			modValue = pc.statusEffectv1("Lane's Hypnosis - Reflexes");
			pc.reflexesMod -= modValue;
			pc.removeStatusEffect("Lane's Hypnosis - Reflexes");
			break;

		case HYPNO_STAT_AIM:
			modValue = pc.statusEffectv1("Lane's Hypnosis - Aim");
			pc.aimMod -= modValue;
			pc.removeStatusEffect("Lane's Hypnosis - Aim");
			break;

		case HYPNO_STAT_INT:
			modValue = pc.statusEffectv1("Lane's Hypnosis - Intelligence");
			pc.intelligenceMod -= modValue;
			pc.removeStatusEffect("Lane's Hypnosis - Intelligence");
			break;

		case HYPNO_STAT_WILL:
			modValue = pc.statusEffectv1("Lane's Hypnosis - Willpower");
			pc.willpowerMod -= modValue;
			pc.removeStatusEffect("Lane's Hypnosis - Willpower");
			break;

		case default:
			throw new Error("Couldn't find selected effect.");
			break;
	}

	if (flags["HYPNO_EFFECT_SMALL_MESSAGES"] != undefined)
	{
		eventBuffer += "\n\nAnother one of Lane's hypnotic augmentations is beginning to dissipiate. You sigh – it was fun while it lasted. You put your codex away and make a mental note to return to Lane about another boost the next time you’re in the area.";
		mainGameMenu();
	}
	else
	{
		clearMenu();
		addButton(0, "Next", mainGameMenu);
	}
}

/*
Add a hypnosis effect that boosts a stat. Also creates the time-checking hidden effect that will be used to determine if we're doing special things.
*/
const HYPNO_STAT_PHYS:String = "Physique";
const HYPNO_STAT_REF:String = "Reflexes";
const HYPNO_STAT_INT:String = "Intelligence";
const HYPNO_STAT_AIM:String = "Aim";
const HYPNO_STAT_WILL:String = "Willpower";

function hasHypnosisEffect():void
{
	if (pc.hasStatusEffect("Lane's Hypnosis - Physique")) return true;
	if (pc.hasStatusEffect("Lane's Hypnosis - Reflexes")) return true;
	if (pc.hasStatusEffect("Lane's Hypnosis - Intelligence")) return true;
	if (pc.hasStatusEffect("Lane's Hypnosis - Willpower")) return true;
	if (pc.hasStatusEffect("Lane's Hypnosis - Aim")) return true;
	return false;
}

function addHypnosisEffect(stat:String):Boolean
{
	if (flags["LANE_TIMES_HYPNOTISED"] == undefined) flags["LANE_TIMES_HYPNOTISED"] = 0;
	flags["LANE_TIMES_HYPNOTISED"]++;

	throw new Error("Ensure the statmods are removed appropriately!");

	var alreadyUnder:Boolean = false;

	if 	(	pc.hasStatusEffect("Lane's Hypnosis - Physique") 
		|| 	pc.hasStatusEffect("Lane's Hypnosis - Reflexes") 
		|| 	pc.hasStatusEffect("Lane's Hypnosis - Intelligence") 
		|| 	pc.hasStatusEffect("Lane's Hypnosis - Willpower") 
		|| 	pc.hasStatusEffect("Lane's Hypnosis - Aim")
		)
	{
		increaseLaneHypnosisLevel();

		if (pc.hasStatusEffect("Lane Hypnosis"))
		{
			pc.setStatusMinutes("Lane Hypnosis", 60 * 24);
		}
		else
		{
			flags["HAS_HAD_LANE_HYPNOSIS"] = 1;
			pc.createStatusEffect("Lane Hypnosis", 0, 0, 0, 0, true, "", "", false, 60 * 24);
		}
		alreadyUnder = true;
	}

	if (stat == HYPNO_STAT_PHYS)
	{
		if (!pc.hasStatusEffect("Lane's Hypnosis - Physique"))
		{
			pc.createStatusEffect("Lane's Hypnosis - Physique", 5, 0, 0, 0, false, "Pill", "Lane's hypnosis session has improved your physique!", false, 60 * 24);
			pc.physiqueMod += 5;
		}
		else
		{
			pc.setStatusMinutes("Lane's Hypnosis - Physique", 60 * 24);
		}
	}
	else if (stat == HYPNO_STAT_REF)
	{
		if (!pc.hasStatusEffect("Lane's Hypnosis - Reflexes"))
		{
			pc.createStatusEffect("Lane's Hypnosis - Reflexes", 5, 0, 0, 0, false, "Pill", "Lane's hypnosis session has improved your reflexes!", false, 60 * 24);
			pc.reflexesMod += 5;
		}
		else
		{
			pc.setStatusMinutes("Lane's Hypnosis - Reflexes", 60 * 24);
		}
	}
	else if (stat == HYPNO_STAT_INT)
	{
		if (!pc.hasStatusEffect("Lane's Hypnosis - Intelligence"))
		{
			pc.createStatusEffect("Lane's Hypnosis - Intelligence", 5, 0, 0, 0, false, "Pill", "Lane's hypnosis session has improved your intelligence!", false, 60 * 24);
			pc.intelligenceMod += 5;
		}
		else
		{
			pc.setStatusMinutes("Lane's Hypnosis - Intelligence", 60 * 24);
		}
	}
	else if (stat == HYPNO_STAT_AIM)
	{
		if (!pc.hasStatusEffect("Lane's Hypnosis - Aim"))
		{
			pc.createStatusEffect("Lane's Hypnosis - Aim", 5, 0, 0, 0, false, "Pill", "Lane's hypnosis session has improved your aim!", false, 60 * 24);
			pc.aimMod += 5;
		}
		else
		{
			pc.setStatusMinutes("Lane's Hypnosis - Aim", 60 * 24);
		}
	}
	else if (stat == HYPNO_STAT_WILL)
	{
		if (!pc.hasStatusEffect("Lane's Hypnosis - Willpower"))
		{
			pc.createStatusEffect("Lane's Hypnosis - Willpower", 5, 0, 0, 0, false, "Pill", "Lane's hypnosis session has improved your willpower!", false, 60 * 24);
			pc.willpowerMod += 5;
		}
		else
		{
			pc.setStatusMinutes("Lane's Hypnosis - Willpower", 60 * 24);
		}
	}

	if (laneHypnosisLevel() == 2) pc.lust(20);
	if (laneHypnosisLevel() == 3) pc.lust(40);

	return alreadyUnder;
}

function enterLanesShop():void
{
	// Reset the "mini" flag so we'll get the full version of the effect-removal messages.
	if (flags["HYPNO_EFFECT_SMALL_MESSAGES"] != undefined) flags["HYPNO_EFFECT_SMALL_MESSAGES"] = undefined;

	if (flags["MET_LANE"] == undefined) discoverLanesShop();
	else if (flags["LANE_FIRST_HYPNO"] == 1 && flags["LANE_TIMES_HYPNOTISED"] > 0 && !hasHypnosisEffect()) lanesShopFirstRepeat();
	else if (hasMaxedLaneHypnosis()) lanesShopFullyUnder();
	else repeatEnterLanesShop();
}

function discoverLanesShop():void
{
	flags["MET_LANE"] = 1;

	clearOutput();
	output("You see a large hut off the beaten pathway of the desert cave’s dirt and sands. The hut is made of hardened mud and stone, but is dressed from top to bottom with fine, lacy fabrics and thin streamers blowing in the calm breeze, making it look quite inviting and standoffish, compared to the blandness of the surrounding area. The hut looks to have three rooms, and is only one story tall. There is a sign nailed above the open, door-less doorway that reads ‘Lane’s Plane: Unlocking the New You.’ Your curiosity is piqued, and you head inside.");
	
	output("\n\nThe first room is really quite plain: there is a small desk to the side, made of concrete but smooth as glass, as well as a pair of chairs on either side, each with a thick, plushy cushion. A small sign on the desk details what services the store provides, but at the top, in huge, bolded letters, are the words ‘No Refunds’. A small bookcase sits behind the desk and faces the inside chair – it’s likely a secretary’s desk or something. Some potted plants, with exotic leaves and stems from parts of the world you’ve yet to explore, sit in the corners. There are no windows. The second half of the room is draped in more of those fabrics and streamers; they don’t conceal what lies beyond them, but they do obfuscate your vision enough to hide the details.");
	
	output("\n\nThere is nobody sitting at the desk to greet you. You hear the sound of bare feet stepping over the stone of the floor beyond the curtains, and you turn to see who is there. On the other side you see a humanoid-shaped person fidgeting with what you assume is some furniture. Whatever it is they’re doing, it appears to be giving regular flashes of red and blue light, dimly illuminating the whole room. They’re not standing profile, so you can’t tell if they have breasts or not, but you can make out the tell-tale sway of a tail reaching down their legs and nearly reaching their ankles.");
	
	output("\n\nWhoever is over there is clearly distracted and hasn’t noticed you yet. You think to clear your throat and call out to them, but, with just the silhouette, you can’t think of which gender-pronoun to address them as. Do you just assume it’s a male, or do you take the chance and assume it’s a female?");

	clearMenu();
	addButton(0, "Male", laneGenderSelect, "male");
	addButton(1, "Female", laneGenderSelect, "female");
}

function laneGenderSelect(g:String):void
{
	if (g == "male")
	{
		lane.configMale();
		meetMaleLane();
	}
	else if (g == "female")
	{
		lane.configFemale();
		meetFemaleLane();
	}
	else
	{
		throw new Error("Invalid gender detected. Wakka wakka.");
	}
}

function meetMaleLane():void
{
	clearOutput();
	outputText("<i>“Excuse me, sir?”</i> you call out, hoping you’ve made the right decision. The figure immediately straightens out, bumping its feet on whatever it was shuffling around, and turns around, towards the curtains. A pair of brown, scaly, webbed, four-fingered ‘hands’ reaches between the gap of the curtains and pulls them wide open: there, a sort of lizard-man greets you, eye-to-eye, looking a little flustered that you had managed to get the drop on him.");

	outputText("\n\n<i>“I’m sorry!”</i> he says, stepping forward and shutting the curtain behind him. <I>“This is embarrassing! I was a little distracted, and I didn’t hear you step in. You haven’t been here for too long, I hope?”</I>");

	outputText("\n\nYou tell him that you had only just walked in. You’re quickly distracted yourself by the lizard-man’s appearance. He’s wearing even more of the white, lacy fabric all over his body, which does a poor job of concealing his skin and his bodily features: he has no nipples on his chest and he has no belly-button, and the whole front of his body appears to have thin, enviously smooth skin. His pelvis is concealed by a much thicker white fabric, concealing his privates and keeping him half-decent. When he first poked his head through the curtains, a pair of large, thin membranes, going from his jaw to his shoulders, seemed to flair wide open for a moment in his surprise before he shut them against his neck again. But the most mesmerizing thing of all is that the lizard-man appears to be... <i>glowing,</i> for lack of a better term. His skin is constantly flashing red and blue, giving away what the pale light from before was.");

	outputText("\n\nHe notices your odd, abject staring at his body, and his lizard-lips curl into a well-meaning smirk. <I>“You must never have seen a Daynar before, I take it?”</i> he asks you, putting his hands on his hips and striking a sassy pose. You hesitate for a moment, trying to find the willpower to break free from the hypnotic glowing underneath his skin, and you nod, confirming his assumption. <i>“Well, there’s a first time for everything.”</i> He reaches forward with his right hand. <i>“My name is Lane. Welcome to my little plane of existence.”</i>");

	outputText("\n\nYou shake his hand and give it a few strong pumps, replying with your own name. He quickly takes his spot behind the concrete desk, pulls his chair forward, and takes a seat, adopting a more professional demeanor for his new customer. <i>“[pc.name] Steele? As in, Steele Tech? Didn’t you inherit that company from your father – may he rest in peace?”</i> You tell him that, yes, of Steele Tech, but no, you haven’t, and that you’re working on it. His eyes wander for the briefest of moments, before he straightens himself out and looks you in the eye. <i>“So, [pc.name] Steele, what can I help you with?”</i>");

	laneShowMenu();
}

function meetFemaleLane():void
{
	clearOutput();
	outputText("<i>“Excuse me, ma’am?”</i> you call out, hoping you’ve made the right decision. The figure immediately straightens out, bumping its feet on whatever it was shuffling around, and turns around, towards the curtains. A pair of brown, scaly, webbed, four-fingered ‘hands’ reaches between the gap of the curtains and pulls them wide open: there, a sort of lizard-woman greets you, eye-to-eye, looking a little flustered that you had managed to get the drop on her.");

	outputText("\n\n<i>“I’m sorry!”</i> she says, stepping forward and shutting the curtain behind her. <I>“This is embarrassing! I was a little distracted, and I didn’t hear you step in. You haven’t been here for too long, I hope?”</I>");

	outputText("\n\nYou tell her that you had only just walked in. You’re quickly distracted yourself by the lizard-woman’s appearance. She’s wearing even more of the white, lacy fabric all over her body, which does a poor job of concealing her skin and her bodily features: she has no nipples on her (rather generous) chest; she has no belly-button; and the whole front of her body appears to have thin, enviously smooth skin. Her pelvis is concealed by a much thicker white fabric, concealing her privates and keeping her half-decent. When she first poked her head through the curtains, a pair of large, thin membranes, going from her jaw to her shoulders, seemed to flair wide open for a moment in her surprise before she shut them against her neck again. But the most mesmerizing thing of all is that the lizard-woman appears to be... <i>glowing,</i> for lack of a better term. Her skin is constantly flashing red and blue, giving away what the pale light from before was.");

	outputText("\n\nShe notices your odd, abject staring at her body, and her lizard-lips curl into a well-meaning smirk. <I>“You must never have seen a Daynar before, I take it?”</i> she asks you, putting her hands on her hips and striking a sassy pose. You hesitate for a moment, trying to find the willpower to break free from the fancy glowing underneath her skin, and you nod, confirming her assumption. <i>“Well, there’s a first time for everything.”</i> She reaches forward with her right hand. <i>“My name is Lane. Welcome to my little plane of existence.”</i>");

	outputText("\n\nYou shake her hand and give it a few strong pumps, replying with your own name. She quickly takes her spot behind the concrete desk, pulls her chair forward, and takes a seat, adopting a more professional demeanor for her new customer. <i>“[pc.name] Steele? As in, Steele Tech? Didn’t you inherit that company from your father – may he rest in peace?”</i> You tell her that, yes, of Steele Tech, but no, you haven’t, and that you’re working on it. Her eyes wander for the briefest of moments, before she straightens herself out and looks you in the eye. <i>“So, [pc.name] Steele, what can I help you with?”</i>");

	laneShowMenu();
}

function lanesShopFirstRepeat():void
{
	flags["LANE_FIRST_HYPNO_RETURN"] = 2;
	clearOutput();
	outputText("You march right into Lane’s little hut, a hundred angry things to say to [lane.himHer] all at once. [lane.heShe]’s there, lounging at [lane.hisHer] desk and playing with [lane.hisHer] codex, and [lane.heShe] hardly seems phased at all when you start stomping into [lane.hisHer] business with a look like you’re going to rip [lane.hisHer] head off.");

	outputText("\n\n<i>“Lane!”</i> you shout, slapping at [lane.hisHer] desk forcefully, rumbling the little knicks and knacks [lane.heShe] has placed all around it. [lane.HeShe] looks up from his codex and into your eyes, fearlessly.");

	outputText("\n\n<i>“Ah, [pc.name],”</i> [lane.heShe] says nonchalantly. <i>“You must be here because the last hypnosis wore off, and you’re upset that it didn’t last forever.”</i> You’re a bit surprised that [lane.heShe] had deduced it so quickly. <i>“Yeah, that’s happened almost every single time, now. Everyone assumes that it’s a one-pay thing, and then they get the clarity I give them for the rest of their lives.”</i>");

	outputText("\n\nYou’re not the first person to yell at [lane.himHer] for giving you a temporary service? <i>“And I very much doubt you’ll be the last,”</i> [lane.heShe] says. <i>“I can understand why you’d be upset, but think about it from a " + lane.mf("businessman", "businesswoman") + "’s point of view, [pc.name]. Where would I get my money if I didn’t have repeat customers? I can’t survive on just one-offs. I</i> am <i>trying to run a business, here.”</i>");

	outputText("\n\nYou remain indignant and insist that [lane.heShe] could have at least told you beforehand that [lane.hisHer] ‘improvements’ were temporary. In response, [lane.heShe] taps at the bottom line of words at [lane.hisHer] ‘No Refunds’ sign. The font is small, but it clearly says that each service of [lane.hisHers] is strictly temporary and will wear off after twenty-four Terran hours, but can be reinstated the following day at the same charge.");

	outputText("\n\nSheepish, you sit and apologize for your outburst. <i>“Think nothing of it,”</i> [lane.heShe] tells you. <i>“Your response was actually quite contained compared to some of my more... animate customers. Besides, if you’re here, it means you liked my business enough to get yourself into a stink over it.”</i> [lane.HeShe] leans back casually. <i>“Let’s put that all behind us. What can I do for you today?”</i>");

	laneShowMenu();
}

function repeatEnterLanesShop():void
{
	clearOutput();
	outputText("You approach Lane’s Plane, interested in another dose of [lane.hisHer] medicine. You enter [lane.hisHer] familiar hut and you see [lane.himHer], lazily lounging on [lane.hisHer] seat behind [lane.hisHer] desk as usual. [lane.HeShe] perks up, lifting [lane.hisHer] head at the sound of a coming customer’s footsteps, and [lane.hisHer] expression lights right up as soon as you walk into the store. <i>“Welcome again, [pc.name]!”</i> [lane.heShe] says, opening [lane.hisHer] arms warmly to greet you. <i>“Please, have a seat. To what do I owe the pleasure today? How can Lane help you in [lane.hisHer] plane?”</i>");

	outputText("\n\n[lane.HeShe] sits there, crossing [lane.hisHer] arms patiently while you take the seat across from [lane.himHer], and waits for your response.");

	laneShowMenu();
}

function lanesShopFullyUnder():void
{
	clearOutput();
	outputText("You approach Lane’s Plane, eager for another dose of your "+ lane.mf("master", "mistress") +"’s medicine. [lane.HisHer] hut has been taking on a rather extravagant turn lately, with all that extra money [lane.heShe]’s been siphoning from you. When you enter, you see [lane.himHer] lounging languidly, [lane.hisHer] legs spread and [lane.hisHer] chair leaned back, waiting for some other unlucky- or lucky, from your twisted, controlled perspective- customer to walk into [lane.hisHer] trap.");

	outputText("\n\n[lane.HeShe] smirks that familiar smirk when you walk in, and [lane.heShe] drops his feet to the floor" + lane.mf("", ", making her bust bounce just slightly from the motion and the vibration") + ".");
	outputText(" [lane.heShe] regulates [lane.hisHer] pulse, and already you’re weak in the knees and horny in the loins,");
	if (pc.hasCock() && !pc.hasVagina()) outputText(" your [pc.eachCock] rousing to attention, hoping Lane will provide you some ‘other’ service. Beads of your [pc.cum] begin to stain your clothing as you sit.");
	else if (pc.hasVagina() && !pc.hasCock()) outputText(" your [pc.vagina] moistening in rapt optimism that Lane will use [lane.hisHer] power over to you give you another life-altering orgasm.");
	else if (pc.hasVagina() && pc.hasCock()) outputText(" each and every part of you ready to sink deeper into [lane.hisHer] control, if it means getting off the way only [lane.heShe] can get you off anymore.");
	else outputText(" which only serves to frustrate you, but your waking mind knows that your needs are secondary to [lane.hisHer], and providing yourself to Lane is the greatest pleasure you'll ever need.");

	outputText("\n\n[lane.HeShe] flairs his tassels open, only for a moment, to let you taste of the sweet pleasure you’ve come to [lane.himHer] for. Teasingly, they shut again, and you’re left horny and thirsty for more of [lane.himHer]. <i>“Welcome back, my pet,”</i> [lane.heShe] says sensually, dragging a loving claw gently over your [pc.face]. <i>“Have you come to Lane for more of [lane.hisHer] magic? Or are you here to pay your ‘taxes’?”</i>");

	laneShowMenu();
}

function laneShowMenu():void
{
	clearMenu();
	addButton(0, "Talk", talkToLane);
	addButton(1, "Services", lanesServices);
	addButton(2, "Taxes", lanesTaxes);
	addButton(5, "Appearance", lanesAppearance);
	addButton(14, "Leave", leaveLanes);
}

function talkToLane():void
{
	clearOutput();

	if (hasLaneHypnosis())
	{
		outputText("[lane.HeShe] laughs, not derisively, but not amusedly either. <i>“You and I have gotten plenty intimate over your visits. I’ve charmed you quite enough, I think.”</i> [lane.HeShe] flairs his tassels open again, and his power over you is refreshed. If [lane.heShe] doesn’t want to talk, that’s perfectly fine with you. <i>“But,”</i> [lane.heShe] yawns, closing [lane.hisHer] membranes against [lane.hisHer] neck, <i>“you’ve come all this way just to taste of your "+ lane.mf("Master", "Mistress") +"’s voice some more. Who would I be to turn down such a loyal pet?”</i>");
	}
	else
	{
		outputText("\n\n<i>“Oh, this is a social call, is it?”</i> Lane says, trilling amusedly. [lane.HeShe] leans back in [lane.hisHer] chair, slumping and relaxing, stretching [lane.hisHer] limbs out. <i>“Sure, I wouldn’t mind shooting the breeze for a moment. What’s on your mind?”</i>");
	}

	generateLaneTalkMenu();
}

function generateLaneTalkMenu():void
{
	clearMenu();
	
	addButton(0, "Occupation", laneTalkOccupation);
	
	if (flags["LANE_OCCUPATION_TALK"] != undefined) addButton(1, "Daynar", laneTalkDaynar);
	else addDisabledButton(1, "Daynar");

	if (flags["LANE_DAYNAR_TALK"] != undefined) addButton(2, lane.mf("Him", "Her") + "self", laneTalkThemself);
	else addDisabledButton(2, lane.mf("Him", "Her") + "self");
	
	addButton(14, "Back", laneShowMenu);
}

function laneTalkOccupation():void
{
	flags["LANE_OCCUPATION_TALK"] = 1;
	clearOutput();
	outputText("You ask Lane what [lane.hisHer] occupation is, out here in the middle of the Venar desert, setting up shop in some little mud hut. Beyond the codex lying atop [lane.hisHer] desk, [lane.hisHer] business seems very... rustic. There’s very little in the way of modernization here.");

	outputText("\n\n<i>“Yeah, you’re right,”</i> [lane.heShe] says proudly. <i>“I know my way around the modern world about as well as anyone else, but I try to keep my house, and my business, as down-to-earth as possible. I specialize in....”</i> [lane.HeShe] pauses, tapping a claw against [lane.hisHer] chin. <i>“</i>Spiritualistic medicine<i> is one way of putting it.”</i> You ask [lane.himHer] to elaborate.");

	outputText("\n\n<i>“Well, think about it. Say you don’t like something about yourself – maybe you’re too meek, or shy, or you have a nervous tic, or something. Maybe you’re just depressed. Today, most of those things can be fixed with a bottle of pills, or the push of a button, or a needle in your arm. Modern medicine is all well and good, and if I ever get sick with the pony pox, you’ll find me elbow-deep in my medicine cabinet. But maybe you have something a pill can’t fix, or maybe you’re not a fan of putting things in your body. That’s where I can help out.”</i>");

	outputText("\n\nA pair of thin, fleshy membranes unstick from the sides of [lane.hisHer] neck and flare open. They reach from the very edges of [lane.hisHer] shoulders to the bottom of [lane.hisHer] jaw on either side of [lane.hisHer] head. They have some markings and piercings on them, but they’re so thin that the glowing from the inside of [lane.hisHer] body is especially intense on them. <i>“I specialize in hypnosis,”</i> [lane.heShe] says, after letting you gawk at the red-and-blue flashing of [lane.hisHer] thin skin a bit. [lane.HeShe] presses the membranes flat against [lane.hisHer] neck again, stopping the light show. <i>“I can hypnotize anybody.”</i>");

	outputText("\n\nYou shake the lights from your eyes, and you scoff at [lane.himHer]. Hypnosis? You’d have thought something as archaic as that would have phased out centuries before the first Great Planet Rush.");

	outputText("\n\n<i>“A lot of people thought so,”</i> [lane.heShe] said, lifting up [lane.hisHer] codex and pressing a few buttons on its screen. [lane.HeShe] then turned it towards you. <i>“Here are some customer testimonials if you’re unconvinced.”</i> On the bright screen was a sort of guestbook: different names and handwriting from every unique customer Lane ever had was there, and each of them sang [lane.hisHer] praises, assuring whoever read them that Lane was the real deal. [lane.HeShe] turns towards his bookcase. <i>“I also have a work permit, and a certification of guaranteed quality from the UGC, if you’d like.”</i> From its top shelf, [lane.heShe] pulls out two certificates, both of them framed, stamped, and signed. You can’t deny it – Lane is running a real, legitimate business in hypnotism.");

	outputText("\n\nYou return his codex to [lane.himHer] and, intrigued, you ask [lane.himHer] how hypnosis works, and how [lane.heShe] can use it as a business. <i>“The most important part is that the customer has to want it. If, say, you came to me complaining about your depression and you paid me to hypnotize it out of you, but you didn’t actually want it, then it would fail.”</i> [lane.HeShe] nods to the sign on [lane.hisHer] desk, tapping at the top line of the sign: the big words that say ‘No Refunds.’ <i>“That’s why there are no refunds. As soon as you give me the credits, I’m not giving them back. If nothing else, it provides a good incentive for people to want to get their money’s worth.”</i>");

	if (pc.isMischevious()) outputText("\n\nYou lean back in your chair and you smirk at [lane.himHer]. If the customer really has to want it, then [lane.heShe] can’t exactly just walk down the street and hypnotize the money out of people’s wallets, then. <i>“Unfortunately, no,”</i> [lane.heShe] says, laughing with you. <i>“If I could do something like that, then I’d have taken up a job as a politician, or a news anchor; something to get me in front of a camera. But unless every single person watching me wants me to hypnotize them, all they’d see is a Daynar with a bunch of tattoos on [lane.hisHer] tassels. I’m afraid universal domination isn’t really in my schedule.”</i> You tell [lane.himHer] that [lane.heShe] must be heartbroken, and [lane.heShe] just waves you off.");

	outputText("\n\n<i>“So, are you convinced?”</i> [lane.heShe] asks, opening [lane.hisHer] hands to you. <i>“Would you like to give it a try? Or is there something I can help you further with?”</i>");

	generateLaneTalkMenu();
	addDisabledButton(0, "Occupation");
}

function laneTalkDaynar():void
{
	flags["LANE_DAYNAR_TALK"] = 1;
	clearOutput();

	outputText("You ask [lane.himHer] about his species. When you first met, [lane.heShe] introduced himself as a ‘Daynar’. <i>“That’s correct,”</i> [lane.heShe] says, crossing [lane.hisHer] arms. <i>“We’re one of the many races natively found on the planet Venar. I’m told we closely resemble a common lizard on the planet Terra.”</i> You confirm. <i>“We’re big fans of hot, dry places, like the desert we’re under. We evolved from a smaller, more... beastly, single-minded creature only a few millenniums ago. A blink of an eye, in geological terms.”</i> [lane.HeShe] scratches the top of [lane.hisHer] bald, scaly head. <i>“Our evolution was natural for the most part, until aliens like yourself started showing up and polluting our sands with your biogenetic drugs. Not that I’m complaining, myself.”</i>");

	outputText("\n\nYou ask [lane.himHer] if all the Daynar have blood that glows. You find it awfully distracting in a pleasant way. <i>“Oh, yes. It’s another evolutionary advantage, one we still use today. How brightly it glows is an indicator of the individual’s health and sexual potency - " + lane.mf("the brighter it is on a male, for instance, then the healthier he is, and the more virile his sperm is.", "the brighter it is on a female, for instance, then the healthier she is, and she’ll lay a larger, healthier clutch of eggs than others.") + " The way the blood pulses can also be a signal if a female Daynar is in heat.”</i> [lane.HeShe] looks away and sighs, twirling a claw on [lane.hisHer] desk. <i>“Back when we were still a fledgling species, we were hunted quite a bit for our blood. They were used for fancy baubles and knick-knacks: tacky, expensive glowsticks and the like. That stopped in a hurry, thankfully, once we learned how to talk. The UGC didn’t like the idea of hunting a sapient species, and outlawed the practice.”</i>");

	outputText("\n\nYou look at Lane’s neck and chest, watching [lane.hisHer] blood course, [lane.hisHer] skin glowing an iridescent red and then a melancholy blue.");
	if (!pc.isMischevious()) outputText(" An obvious, quite personal question comes to mind, but you decide not to embarrass the poor thing.");
	else 
	{
		outputText(" You ask [lane.himHer] what [lane.hisHer] own glowing means for [lane.hisHer] health. <i>“I’m not asked that too often,”</i> [lane.heShe] notes, looking down at [lane.hisHer] chest. <i>“I</i> feel <i>fine... I’m hardly a fitness nut, but I usually start my mornings with a set of " + lane.mf("push-ups", "crunches") +". I think I’m about average.”</i> And, you ask... what about [lane.hisHer] ‘sexual potency?’");
		if (!hasLaneHypnosis()) outputText(" The colour of [lane.hisHer] eyes change from brown to a rosy red, and [lane.heShe] just chuckles and looks away.");
		else outputText(" <i>“I should think you’d know,”</i> [lane.heShe] says, flaring open [lane.hisHer] tassels for a moment, <i>“but I can give you a reminder a little later, pet.”</i> You feel something of yours flaring between your legs as well.");
	}

	outputText("\n\nYou ask Lane about the weird membranes connecting [lane.hisHer] jaw to [lane.hisHer] shoulders. <i>“Oh, these,”</i> [lane.heShe] says, flapping them open. Your eyes are caught on them, watching how [lane.hisHer] blood glows brightest through them, and how the veins in [lane.hisHer] skin work with the tattoos on - [lane.heShe] closes them before you get a little <i>too</i> distracted. <i>“We Daynar call them ‘tassels’. They’re used to regulate our body temperature, and, if we’re in the middle of a fight, we can open them in a flash to scare our opponent. In today’s modern world, though, with air-conditioning, climate control, and not much in the way of natural predators, they don’t see much use anymore.”</i>");

	outputText("\n\n[lane.HeShe] opens [lane.hisHer] eyes wide – unusually wide, making you fidget in your seat – and, just like that, the colour of Lane’s irises begin to change, into every colour you can imagine. <i>“Daynar don’t have the best night vision, so we can open our eyes really wide to draw in more light to compensate. As for the irises... nobody is really sure why we can do that. Our best guess is to unnerve predators: to make us look sickly and unappetizing. Whatever the purpose, they sure make my job easier.”</i> [lane.HeShe] points to the sides of [lane.hisHer] head. <i>“Our ears are pretty plain,”</i> [lane.heShe] begins. You have to lean forward to see where [lane.hisHer] ears even are: they’re just a pair of holes in [lane.hisHer] head, nothing more. <i>“But we have</i> great <i>hearing. Some Daynar pick up jobs as interpreters because we have an easier time picking up different languages than most.”</i>");

	// TODO: Tweak this.
	outputText("\n\n[lane.HeShe] leans forward in [lane.hisHer] seat. <i>“There’s just one more thing I want to mention. It’s about Steele Tech.”</i> You match [lane.hisHer] posture, interested. <i>“I don’t know if you knew this, but most Daynar on the planet are employed by Steele Tech. Venar, it turns out, has a lot of minerals and ores that the rest of the universe is interested in, but no other race can withstand the harsh climate of the hot desert or the planet core like a Daynar can. Which makes us</i> highly <i>desirable for a mining company. Your dad paid us pretty well, and his stickler for safety carried over to Venar; there isn’t a Daynar here that wouldn’t mind calling you ‘boss’ if you kept up his legacy, [pc.name].”</i>");

	outputText("\n\nYou shift in your seat, uncomfortable with the sudden pressure, but you assure [lane.himHer] that you’ll do what you can. Lane leans back, relaxing. <i>“That about covers it, I think. Is there anything else I can help you with?”</i>");

	generateLaneTalkMenu();
	addDisabledButton(1, "Daynar");
}

function laneTalkThemself():void
{
	flags["LANE_SELF_TALK"] = 1;
	clearOutput();

	outputText("You ask [lane.himHer] if hypnosis is a thing that all Daynar can do. <i>“As in, is it something they just intrinsically know? No. Anyone can learn it, of course, but, as far as I know, I’m the only Daynar that bothered to take the time.”</i>");

	outputText("\n\nYou then ask [lane.himHer] about himself. What inspired [lane.himHer] to get into the business of hypnotism? Despite the certificates and the testimonials, you insist that it <i>is</i> a pretty ancient practice. <i>“Yes, I know, and I agree. Hypnosis hasn’t really been in the news, so to speak, for hundreds of years now.”</i> [lane.HeShe] chuckles sheepishly. <i>“If I’m honest, the inspiration for picking it up was because... I was bullied a lot when I was younger. I had a lot of power fantasies about controlling the people around me to do whatever I wanted. Like, commanding them to be my footrest as I sit on my gilded, golden throne; stuff like that. Making them ‘regret’ bullying the wrong Daynar.”</i>");

	outputText("\n\n[lane.HeShe] rests his chin on the palm of [lane.hisHer] scaly hand, reminiscing about [lane.hisHer] younger years. <i>“I didn’t learn about hypnotism until my adolescent years, when I was studying history. One of my textbooks mentioned hypnosis as an old, ancient, spiritual practice. I was intrigued, so I studied it some more, and before I knew it, I was getting a permit to practice it as a business.”</i>");

	if (!hasLaneHypnosis())
	{
		outputText("\n\nYou chuckle uncomfortably, rolling your shoulders. [lane.HeShe] learned how to control people, and [lane.heShe] made it a legitimate business... because of a power fantasy? <i>“I know what you’re thinking,”</i> [lane.heShe] says smoothly, trying to calm your nerves. <i>“If I put a person ‘under’, then I could, theoretically, control what the person feels and thinks and does until they pull out of it. Believe it or not, the UGC thought so too – and they made me swear that I wouldn’t use my skills ‘to the detriment of the peoples that trust my judgment’. Sort of like the Hippocratic Oath for doctors.”</i> You narrow your eyes and chew your bottom lip. You could trust a surgeon, but a hypnotist...?");
	}
	else
	{
		outputText("\n\nYou smile sensually, resting an elbow on Lane’s desk. You tell {him}, in a dulcet tone, that you find power fantasies pretty sexy, yourself – especially when it’s {him} that’s in charge. In response, {he} grins, and opens {his} tassels, letting you absorb more of {him}. <i>“It wasn’t easy at first,”</i> {he} says, enjoying the way you watch the patterns on {his} tassels. <i>“I swore not to use my powers for evil. But then, the heir" + pc.mf("", "ess") + " of Steele Tech had to go and pay me to abuse [pc.himHer] until [pc.heShe] couldn’t get enough of me. And, I have to admit, ‘evil’ feels pretty good when" + lane.mf(" your pretty lips are sucking my dick and swallowing my cum like I was the only fountain in the desert.", " you’re digging for gold with your tongue in my cunny and you try oh-so-hard to hit just the right spots to make your mistress come again and again." + "”</i> {He} closes his tassels, leaving you teased for more.");
	}

	if (lane.mf("m", "f") == "f")
	{
		outputText("\n\nYou decide to broach a rather delicate and personal question, and you preface it by telling Lane that she doesn’t need to answer if she doesn’t want to. If you’re not mistaken, Daynarians are cold-blooded – which she confirms – and that Daynarians lay eggs – which she confirms. So, why does she have breasts?");
		outputText("\n\nShe leans back and stretches her arms, shamelessly showing off her doubly-dangerous jugs to you. <i>“I’m glad you noticed,”</i> she says slyly and without a hint of reserve. <i>“Daynarians were a very sexual species as we transitioned from a lowlier species to one of higher thought. The females don’t have breasts, you’re correct, but, as we discovered the more... carnal pleasures of life, we recognized their appeal and why they’re sexually desirable. Today, breasts on a female Daynarian means she has the means to acquire them in the first place, so they’re something of a status symbol. They don’t serve any purpose other than to be shown off – and,”</i> she says, massaging them right in front of you, <i>“I gotta say, they’re pretty fun.”</i>");
		outputText("\n\nIf they’re considered a status symbol among the Daynarians, does that mean male Daynarians can get them too? You chuckle as you imagine it, but she only smiles. <i>“It’s not unusual.”</i> That silences you in a hurry. <i>“But it is uncommon. It’s something of a clash between Daynarian culture and that of the rest of the universe’s: to us, boobs on anybody means they’re well off and financially stable, but not a lot of other cultures see it that way. So, don’t be surprised if you see a male Daynarian with a set bigger than mine, but try not to be repulsed, either.”</i>");
	}

	outputText("\n\n<i>“Now then, do you have any further questions?”</i> {He} leans back in {his} seat, waiting for your response.");


	generateLaneTalkMenu();
	addDisabledButton(2, lane.mf("Him", "Her") + "self");
}

function laneServices():void
{
	clearOutput();

	if (flags["LANE_SHOWN_SERVICES"] == undefined)
	{
		// First time.
		flags["LANE_SHOWN_SERVICES"] = 1;
		outputText("You ask Lane about {his} service, and you mention that you’re interested. <i>“Of course!”</i> {he} says, giddy that {he} has some business. <i>“I specialize in hypnosis. A lot of problems that a lot of people have are all in their head – if there’s something about yourself that you don’t like, but you’re not comfortable with using drugs or biotech to change your body, I can give you the boost you need. Or maybe you’re struggling with something more cerebral: I’ve had writers come to me before asking me to help with their writer’s block. Whatever the case, there’s no psychological barrier I can’t help you breach.”</i>");

		outputText("\n\nYou ask {him} to elaborate. <i>“Well, in your case, you don’t really seem like the desk-jockey sort. You’re more of a doer, a shaker; you’re out there, exploring new planets and conquering new terrains, or your name isn’t [pc.name] Steele. Am I right?”</i> You confirm. You never were one for desk jobs, and, without telling {him} why, you’ve been exploring the planets rather extensively lately.");

		outputText("\n\n<i>“So, and I don’t want to be presumptuous here, but let’s say you’re in the jungles of Mhen’ga and you see some Naleen in the bushes. You reach for your gun – but it’s faster! It lunges at you, and you point and shoot, but your aim goes wide and now that cat-snake has got you in its coils! You struggle and you struggle, but you don’t have the strength to break free! If only your reflexes were a little better!”</i>");

		outputText("\n\nYou sigh and cross your arms, waiting for {him} to get to the point. <i>“That’s where I can help. I can hypnotize your senses to be more acute, more in-tune with your surroundings and atmosphere. With my help, the next time you’re in those jungles, you’ll be able to turn the surprise around on the Naleen before it could even blink.”</i>");

		outputText("\n\nYou’re definitely intrigued, and you lean forward. {He} can really make your reflexes <i>that</i> good? <i>“Not only your reflexes!”</i> {he} insists. <i>“Have you ever been in a fight, and you wished you were stronger than you were? I can help with that, too! You often hear stories about people performing extraordinary feats of strength, when they look as wiry as a straw, yes? If only a person can harness that sort of strength and call on it whenever they wish. I can help with that! Whatever it is you need – anything at all – I can make you</i> better <i>just by making you believe that you are.”</i>");

		outputText("\n\nYou sit back in your seat, strongly considering Lane’s words. What the fuck, you decide – you’re here, you may as well. You tell {him} that you’re in. <i>“Excellent!”</i> {He} pulls up {his} own codex, and begins tapping at its screen. <i>“I charge one hundred credits per hypnosis. I am contractually obligated to remind you that there are no refunds. As soon as the payment goes through, we can begin.”</i>");

		outputText("\n\n{He} hands you {his} codex. It’s asking for your confirmation, and it lists what you’re purchasing, and for how much. Before you sign your confirmation, you think on it. If you paid Lane to hypnotize you... what would you change about yourself?");

		if (pc.credits < 100)
		{
			outputText("\n\nYou wince, looking at the codex, and you hand it back to {him}, sheepishly telling {him} that you can’t afford it. <i>“Oh.”</i> {He} wipes at its screen, and it goes blank. <i>“Not to worry, I don’t mind this being a social call. Is there anything else I can do for you?”</i>");

			laneShowMenu();
		}
		else
		{
			laneServicesMenu();
		}
	}
	else
	{
		// not hypno
		if (!hasLaneHypnosis())
		{
			if (flags["LANE_TIMES_HYPNOTISED"] > 0)
			{
				outputText("<i>“Of course,”</i> says Lane, already reaching for {his} codex and writing up your receipt. <i>“I’m glad that you enjoyed my service enough to come back, [pc.name].”</i> {He} passes you the codex. <i>“One hundred credits, as usual. Contract, no refunds, blah blah blah. What can I do for you this time?”</i>");
			}
			else
			{
				outputText("<i>“Of course,”</i> says Lane, already reaching for {his} codex and writing up your receipt. <i>“I’m glad to see that you're still interested in my services, [pc.name].”</i> {He} passes you the codex. <i>“One hundred credits, as usual. Contract, no refunds, blah blah blah. What can I do for you?”</i>")
			}

			if (pc.credits < 100)
			{
				outputText("\n\nYou wince, looking at the codex, and you hand it back to {him}, sheepishly telling {him} that you can’t afford it. <i>“Oh.”</i> {He} wipes at its screen, and it goes blank. <i>“I’m afraid I can’t give discounts to my regulars. Sorry. Is there anything else I can do for you, though? Shooting the breeze is always free.”</i>");

				laneShowMenu();
			}
			else
			{
				laneServicesMenu();
			}
		}
		else
		{
			// PC is hypnotized

			outputText("{He} smiles at you, and {he} reaches for his codex. <i>“Of course you do, [pc.name].”</i> {His} tassels flutter just enough so that you can get a taste of what’s to come. {His} claws are jittery on the codex’s screen, proof of {his} own excitement. <i>“I’m sure if I were to charge you three hundred credits, you wouldn’t object.”</i>");
			outputText("\n\nYou tell {him} that you wouldn’t.");
			outputText("\n\n<i>“How about three thousand? And you’re definitely not getting a refund.”</i>");
			outputText("\n\nYou insist that no price is too high.");
			outputText("\n\n<i>“You’re right. Submitting to me and my pleasure is worth more to you than your life. I could ask you to sign everything over to me and you wouldn’t say no, would you?”</i>");

			outputText("\n\nYou shake your head, salivating, eager to get started. {He} hands you the codex – and to your surprise, {he’s} only charging you the standard one hundred credits. <i>“I’m a little kinder than that, though.”</i> You blink, and thank {him} sincerely for {his} unprecedented generosity. <i>“Of course, this isn’t counting the ‘tax’ I’ll be charging you when we’re done.</i>");

			outputText("\n\nYou thank him for his ‘generosity’ again.");

			laneServicesMenu();
		}
	}
}

function laneServicesMenu():void
{
	clearMenu();

	// TODO: ensure this works with the hypno/non-hypno split etc
	if (pc.credits >= 100)
	{
		addButton(0, "Physique", laneServicePhysique);
		addButton(1, "Reflexes", laneServiceReflexes);
		addButton(2, "Aim", laneServiceAim);
		addButton(3, "Intelligence", laneServiceIntelligence);
		addButton(4, "Willpower", laneServiceWillpower);
	}
	else
	{
		addDisabledButton(0, "Physique");
		addDisabledButton(1, "Reflexes");
		addDisabledButton(2, "Aim");
		addDisabledButton(3, "Intelligence");
		addDisabledButton(4, "Willpower");
	}
	if (!hasLaneHypnosis()) addButton(14, "Back", laneServicesBack);
	else addButton(14, "Taxes", laneServicesBack);

	//[=Physique=] [=Reflexes=] [=Aim=] [=Intelligence=] [=Willpower=] [=Back=]
}

function laneServicesBack():void
{
	clearOutput();
	if (!hasLaneHypnosis())
	{
		outputText("{He} frowns as you hand {him} the codex. <i>“Changed your mind?”</i> You apologize, but you’re just not ready for {his} business today. <i>“Don’t worry, I understand. A lot of my customers, even the repeats, get the jitters sometimes. Is there anything else I can help you with, while you’re here?”</i>");

		// Return to main menu
		laneShowMenu();
	}
	else
	{
		if (pc.credits >= 100)
		{
			outputText("You glance up from the codex, your finger hovering teasingly over the confirmation button, when you hand it back to {him}. He looks confused, before you tell {him} that you’d like to skip the foreplay. {He} smiles and stands from {his} chair; {he} crooks a claw at you, ordering you to follow, as {he} leads you behind the curtain and to the left, towards {his} bedroom.");
		}
		else
		{
			outputText("You grin mischievously, returning {his} codex to {him}, and you tell {him} that you just don’t have the funds. Is there, maybe, some other way you can compensate {him} for {his} time and {his} effort? <i>“No.”</i> {He} looks at you rather sternly, and your attempts at being " + pc.mf("suave", "coy") + " quickly fall flat. <i>“Sex with you doesn’t pay for my bills, [pc.name]. Once we’re done here, you’re going out and you’re making some money, I don’t care how.”</i> Just as you slump in your chair, {he} rises from {his}. <i>“But that doesn’t mean I</i> won’t <i>fuck you. Follow me.”</i> Giddy again, you rise from your seat, following {him} like a horny dog as {he} leads you into {his} bedroom.");
		}

		outputText("\n\nBy the time you enter behind your {master/mistress}, {his} shirt and pants have already been pulled off[if {Lane is female}, letting her heavy breasts bounce free in the wind – not that they were especially well concealed to begin with]. {He} turns to you and, with a predatory grin, slides a claw across the fabric of {his} undergarment, tearing it away and revealing " + lane.mf("his throbbing, pointed cock. It’s halfway hard, and you lick your lips as you watch it slide free from his genital slit, inflating in length and in girth", "her wet, puffy cunt. Her genital slit is open and malleable, ready for you to play with; her labia waves at you, waiting for your pleasure") + ".");

		outputText("\n\n<i>“Strip naked,”</i> {he} commands, opening {his} tassels wide, letting you absorb yourself into {him}. You do as you’re commanded, with ease, excitement, and some flair, for {his} benefit. Naked, vulnerable, and horny, you’re completely at {his} mercy. The patterns on {his} tassels swirl in your vision, and you know you’re going to enjoy it.");

		// Go to Randomized sex
		clearMenu();
		addButton(0, "Next", payTheLaneTax);
	}
}

function laneServicePhysique():void
{
	clearOutput();
	outputText("Before you sign your confirmation, you ask {him} if {he} could improve your strength. You know that’s more of a physical thing, but {he} did say <i>anything</i>, after all. <i>“I sure can,”</i> {he} says confidently. <i>“Other customers have asked me the same question. There is a limit to how hard you can push your body without appropriate work or training, of course, but many hurdles are strictly mental. I’ve had thin, spindly little things come to me, telling me that a ten pound barbell feels like a hundred, especially when they’re in a public place like a gym. With just a little bit of my work, you’ll be pushing past your limits and setting new ones within the hour.”</i>");

	outputText("\n\nLane certainly seems cool about it. Do you ask {him} to improve your physique, by removing your inhibitions and your limits?");

	//[=Confirm=] [=Ehh...=]
	clearMenu();
	addButton(0, "Confirm", laneConfirmService, HYPNO_STAT_PHYS);
	addButton(1, "Maybe Not...", laneServiceMaybeNot);
}

function laneServiceReflexes():void
{
	clearOutput();
	outputText("Before you sign your confirmation, you ask {him} if {he} could improve your reflexes. You’ve walked down enough streets, hiked through enough forests, and drank in enough shady bars to know that anything could get the jump on you at any time. <i>“Of course,”</i> {he} says assuredly. <i>“You wouldn’t be the first adventurer I’ve had. I can sharpen each of your senses to be more in-tune with your surroundings: you’ll see, hear, and smell anything stalking you in the sands of Veran before they’d realize it. You’ll know exactly when you are and are not alone, and you’ll be able to react to it faster than you ever could before. I’ve been known to service more than one starship pilot, as well.”</i>");

	outputText("\n\nLane certainly seems sure of himself. Do you ask {him} to improve your reflexes, by attuning your senses to your environment?");

	//[=Confirm=] [=Ehh...=]
	clearMenu();
	addButton(0, "Confirm", laneConfirmService, HYPNO_STAT_REF);
	addButton(1, "Maybe Not...", laneServiceMaybeNot);
}

function laneServiceAim():void
{
	clearOutput();
	outputText("Before you sign your confirmation, you ask {him} if {he} could improve your aim. In the modern world of weaponry and warfare, the better shot is usually the victor, and you want to be sure yours counts. <i>“You bet I can,”</i> {he} says smugly. <i>“I can give you eyesight like... I believe you call it a ‘hawk’ on Terra? While I don’t exactly improve your eyes, I can help your mind process what it is you’re seeing faster than it ever could before. Shapes, velocity, momentum, and distance will become easier for you to discern, and your marksmanship will follow suit. Although... I have to ask. Is there a marksmanship competition coming up somewhere? I’ve had a customer asking the same thing for that reason, and when the judges found out, he was disqualified for having an unfair advantage.”</i>");

	outputText("\n\nYou tell {him} that it’s purely personal, and {he} nods, waving to {his} codex. Lane certainly seems secure about it. Do you ask {him} to improve your aim, by sharpening your mental acuity?");

	//[=Confirm=] [=Ehh...=]
	clearMenu();
	addButton(0, "Confirm", laneConfirmService, HYPNO_STAT_AIM);
	addButton(1, "Maybe Not...", laneServiceMaybeNot);
}

function laneServiceIntelligence():void
{
	clearOutput();
	outputText("Before you sign your confirmation, you ask {him} if {he} could improve your intelligence. You’re... you refuse to call yourself ‘dumb’, but you admit that, sometimes, you... aren’t exactly as ‘worldly’ as you’d like. Is there anything {he} can do to help? <i>“That’s not a problem at all,”</i> {he} insists gently. <i>“You’re not the first to want that changed about yourself, and you won’t be the last. I can’t exactly make you ‘smarter’, per se, but I can improve your memory by streamlining the way your conscious mind recalls thoughts. Those lessons you thought you doodled through in high school will come back to you as easily as recalling your fondest childhood moment. I’ve had college students come to me asking me about it, and my skills have helped them through many cram sessions.”</i>");

	outputText("\n\nLane certainly seems positive about it. Do you ask {him} to improve your memory by, as he put it, ‘streamlining’ how your conscious mind recalls lessons and memories?");

	//[=Confirm=] [=Ehh...=]
	clearMenu();
	addButton(0, "Confirm", laneConfirmService, HYPNO_STAT_INT);
	addButton(1, "Maybe Not...", laneServiceMaybeNot);
}

function laneServiceWillpower():void
{
	clearOutput();
	outputText("Before you sign your confirmation, you ask {him} if {he} could improve your willpower. Sometimes, you feel a little too meek and shy for your own personal safety, and if exploring these planets and encountering their fauna has taught you anything, it’s that having the strength to say ‘no’ can be your strongest weapon sometimes. <i>“Easily,”</i> {he} says surely. <i>“At least three times now, I’ve had wallflowers come up to me and confess that they don’t have the spine to ask a crush out to a date, or something, and if I could help them with that. There’s nothing special about giving you the strength of will: no improved mental acuity or overcoming mental barriers. All I’m doing is giving that little voice in your head, the voice that says what you</i> really <i>feel and what you</i> really <i>want, a helping hand.”</i>");

	outputText("\n\nLane certainly seems confident about it. Do you ask {him} to improve your willpower, by helping your mouth say what your mind is really thinking?");

	//[=Confirm=] [=Ehh...=]
	clearMenu();
	addButton(0, "Confirm", laneConfirmService, HYPNO_STAT_WILL);
	addButton(1, "Maybe Not...", laneServiceMaybeNot);
}

function laneServiceMaybeNot():void
{
	clearOutput();
	outputText("You frown, unsure about the whole thing, but you’re not quite ready to give the codex back to {him}. You tap at the table as you consider what else you can ask {him}.");
	// Return to [=Services=] menu")
	laneServicesMenu();
}

function laneConfirmService(selectedService:String):void
{
	clearOutput();

	player.credits -= 100;

	if (hasMaxedLaneHypnosis() && flags["LANE_FULLY_HYPNOTISED"] == undefined)
	{
		laneFullyHypnotisesYouDumbshit();
		return;
	}

	if (flags["LANE_TIMES_HYPNOTISED"] == 0)
	{
		outputText("You sign your signature in the empty field and tap on the confirmation button. A loading bar appears on the codex, and then it beeps – followed by a beep from your own codex. You hand Lane back {his} as you check your own. The payment’s gone through without a hitch. <i>“Lovely!”</i> {He} stands, placing {his} codex in a drawer under {his} desk, twisting its lock shut and hiding the key in {his} transparent pants’ pocket. From another drawer, {he} pulls out a ‘busy’ sign and lays it on the end of {his} table. <i>“Please follow me, [pc.name]. I have a room in the back where I work my magic.”</i>");

		outputText("\n\nYou follow {him} as he leads you behind the faint, airy curtains, barely hiding the second half of the room. {He} turns right and opens a door into another room of {his} hut, holding it open for you. The second room is much darker and warmer: there are no windows or lights; the only thing providing light is Lane’s glowing body. In the room are two plain, concrete chairs, but both of them are heavily dressed with soft, plump cushions and comfy, giving armrests. Four candles sit in a square around the two chairs, their smoke wafting the wax’s incense through the air and immediately assaulting your nostrils with their burning scent. They all sit on a round, featureless, but thick and plush carpet. The room is otherwise rather large and totally bare.");

		outputText("\n\n{He} shuts the door once you’re in, and you’re concealed in total darkness, except for the constant pulsing reds and blues of Lane’s body. {He} removes his shirt, bearing {his} exposed top to you");
		if (pc.isMischevious()) outputText(" – a rogue thought considers that maybe you’re getting a little extra for what you paid for");
		outputText(". {He} sees you looking at him and {his} topless form curiously. <i>“My hypnosis relies on you having an uninterrupted line of vision with my body,”</i> {he} explains, <i>“which means I have to go topless. It’s not going to go any farther than that, I promise, and you don’t have to take anything off yourself.”</i>");
	}
	else
	{
		outputText("You sign your signature in the empty field and tap on the confirmation button. The two familiar beeps between {his} codex and yours ring out, and you know the funds have transferred properly. With practiced ease, {he} slides {his} codex away and places {his} ‘busy’ sign on the end of {his} table. <i>“Follow me, [pc.name],”</i> {he} instructs, leading you through {his} hut and into {his} hypnosis room.");

		outputText("\n\nWhen {he} shuts the door behind you, it’s as dark as you remember it. The incense from the candles greets your nose, and already you feel yourself relaxing, your legs becoming languid as you walk. You turn to Lane, watching {him} remove his top");
		if (hasLaneHypnosis()) outputText(", your eyes lingering on the smoothness of {his} skin for a little longer than you mean");
		outputText(", and then {he} walks past you, towards {his} seat");
		if (laneHypnosisLevel() >= 3) outputText(". Your eyes glue to {him}, trailing themselves from the ridges of {his} shoulders to where {his} tail meets the small of {his} back....");
	}

	outputText("\n\n");
	if (!pc.isTaur()) outputText("{He} takes the farther seat, and wordlessly invites you to take the one across from {him}.");
	else outputText("{He} picks up the closest seat and sets it aside, leaving you to sit on your haunches on the carpet.");
	outputText(" <i>“First, I want you to close your eyes.”</i> You do so, blocking what little vision you had of the room. The only thing you see is the dull pulse of {his} body through your eyelids.");

	outputText("\n\n<i>“Breathe deep through your nose. Focus on what you’re experiencing. Let it calm your body.”</i> You breathe deep, inhaling the smoky incense – a plethora of spices and scents fill your nose, combining to smell like everything they are and not anything at all, somehow. As your thoughts linger on the scents,");
	if (!pc.isTaur()) outputText(" your body sinks into the comfort of the chair: your arms slack on the rests and your neck begins to roll your head slightly.");
	else outputText(" your body sinks into the comfort of the carpet: your arms begin to go slack and your body feels as though it’s sinking into the floor, in a pleasant way.");

	outputText("\n\n<i>“Now, focus on my voice,”</i> says Lane. <i>“Listen to my words, but</i> feel <i>for my voice. Let my voice into your ears, into your mind. Don’t worry about where I am. Don’t worry about where my voice is coming from. Don’t worry about anything.”</i> Lane’s voice seems to come from everywhere all at once, but at the same time, it feels as though {his} voice is coming from somewhere very close by. With every word {he} says, your chest thrums in vibration, as though {he}’s speaking through you.");

	outputText("\n\nEven with all of these sensations combined, though, you don’t really feel ‘hypnotized’. You still feel in control of your conscious thought. Still, if only to get the most for your money, you follow along with Lane’s commands. <i>“Now, I want you to open your eyes. Don’t force them open. Just let them.”</i> You try to follow {his} command, and you ‘let’ your eyes open....");

	outputText("\n\nYour vision is assaulted with Lane’s glowing, luminescent body. {His} tassels are wide open, where {his} coursing blood glows the brightest. With every heartbeat of {his}, you see {his} red blood flow all throughout {his} neck, tassels, face, " + lane.mf("chest", "breasts") + ", through {his} arms, over {his} stomach, before disappearing underneath {his} undergarments and blurring beneath {his} translucent pants. {His} pulse has taken a rather peculiar rhythm, beating twice quickly, then pausing, flooding your vision with bursts of red and a stream of blue, repeating again and again.");

	outputText("\n\nYour eyes open wider of their own accord as you absorb {him}. Adorned across the inside of {his} tassels are a number of black tattoos with swirling, almost tribal designs on them, and all throughout the skin of {his} membranes are light, glassy piercings. As {his} blood beats through {him}, they mingle with the tattoos and their light bounces all throughout the glass of {his} piercings: the lights distract your focus, and every time you move your eyes between them, the tattoos on {him} begin to swirl with each other in the corners of your eyes. With every movement your eyes make, the coursing blood, the bright trinkets pierced to Lane’s skin, and the moving tattoos draw you deeper and deeper into a trance – into <i>{him}</i>.");

	outputText("\n\n<i>“Watch the swirling lights,”</i> {he} says, but you barely need the instruction. Lane begins to say a lot of other things, but you’ve lost your attention. Your senses begin to overcome your consciousness: your nostrils begin to pick out every individual smell with every breath, and your eyes soon start seeing new shapes and motions that hadn’t existed before. Your mind is completely on autopilot: you’re aware of every sight, every smell, and every vague command Lane tells you, but you barely register them as thoughts. Soon, even your thoughts are leaving you, and you become nothing but a blank slab of a person for Lane to mold and shape as {he} likes. {He} tells you that’s okay, and that becomes <i>your</i> thought, <i>your</i> decision.");

	outputText("\n\nYou’re left hanging limp in Lane’s control. {He} says some other things to you, and they become your thoughts for only a moment before they’re lost in the ether that is your blank consciousness. {His} words become your own, and that’s okay. Your eyes hurt, and you remember to blink – no, Lane reminds you to blink – no, <i>you</i> remember to blink.");

	outputText("\n\nLane watches you, completely enthralled and under {his} spell. Your mouth is dry, and you swallow – no, Lane tells you to swallow – no, <i>you</i> swallow, it was a thought you had. {He} takes a deep breath, remaining calm in {his} seat. Confident that you’re deep enough under {his} spell, {he} begins the work you paid {him} to do.");

	clearMenu();
	addButton(0, "Next", laneApplyService, selectedService);
}

function laneApplyService(selectedService:string):void
{
	clearOutput();

	switch (selectedService)
	{
		case HYPNO_STAT_PHYS:
			outputText("<i>“You feel strength like you’ve never known before course through you,”</i> {he} says smoothly. <i>“What was your limit yesterday is your warm-up today. You have the stability to lift any weight; the endurance to run any distance; the strength to defeat any foe. You are as physically capable as you have ever been. You are a fountain, a geyser, of strength: when you think you can not, you will try, and you</i> will.”");
			break;

		case HYPNO_STAT_REF:
			outputText("<i>“You are constantly aware of your surroundings,”</i> {he} begins. <i>“No sound escapes your perfect ears; no smell escapes your sensitive nose; and no sight escapes your sharp eyes. You can feel the sand beneath the shoes on your feet and you can hear the heartbeat of another creature. You know exactly where everything around you is at all times. You can respond to changes around you with perfect precision. Nothing can escape you. Nothing can approach you.”</i>");
			break;

		case HYPNO_STAT_AIM:
			outputText("<i>“Your mind is clear as a crystal,”</i> {he} instructs. <i>“What your eyes see, your mind can react to. Your weapon is as much an extension of you as your arm holding it. Hitting your target is as natural as blinking and breathing. You can account for motion; velocity; acceleration; wind resistance; distance. There is nothing between you and your target. If your weapon is drawn and your target is not struck, it is because that is what you choose.”</i>");
			break;

		case HYPNO_STAT_INT:
			outputText("<i>“You have no forgotten memory,”</i> {he} tells you. <i>“Every lesson is recalled. Every tidbit is remembered. Every trivia is retained. You remember every plant you were taught to avoid. You remember how to combat every species. Every mistake is recollected and learned from. You are knowledgeable with every scenario, every possibility, because you have learned from them before. Yet, your focus is linear. You do not consider anything that does not need considering.”</i>");
			break;

		case HYPNO_STAT_WILL:
			outputText("<i>“You are as rigid as a stone,”</i> {he} says sternly. <i>“As rooted as a tree. You will not sway. You will not bend. Yours is your will alone. Nobody else will impose theirs upon you. You will not compromise. You will not fall for petty tricks; you cannot be deceived. You will not let any action you take, any course you choose, be altered by someone else’s hand. You will take what you want, and you will not give what is not anyone else’s to take.”</i>");
			break;

		case default:
			throw new Error("Couldn't match stat selection.");
			break;
	}

	outputText("\n\n{He} continues reinforcing those sorts of commands for a few minutes. You are completely and utterly absorbed by {him} and the way {he} overloads each of your senses: everything {he} says becomes your thoughts, since you don’t have any of your own, so absorbed are you in the lights and patterns and smells around you. You are a liquid, and {his} words are the container you take the shape of as you’re poured into it.");

	outputText("\n\n<i>“You will forget all of my previous instructions after twenty-four Terran hours,”</i> {he} says, wrapping up his session with you. <i>“It will be as though we had never had this session. You will know to return to me, but you will do it at your leisure; you will not feel you must. When I close my tassels, [pc.name], we will return to my desk in the front room, and you will awaken.”</i> {He} reinforces those statements for another minute.");

	// If addHynosisEffect returns true, it's the second time in a 24 hour period the player has used his services.
	// Basically just a shortcut to checking hasLaneHypnosis()
	if (addHypnosisEffect(selectedService))
	{
		var msgs:Array;

		if (laneHypnosisLevel() == 0)
		{
			msgs = 
			[
				"Lane bites {his} lip, {his} eyes roaming your body as you sit there, enthralled by {him}. <i>“You...”</i> {he} says softly, unsure with {him}self. <i>“You do not mind Lane’s company. You like speaking with {him}.”</i> {He} reinforces that several more times, before {he} sheepishly stops.",
				"Lane bites {his} lip, {his} eyes roaming your body as you sit there, enthralled by {him}. <i>“You...”</i> {he} says softly, unsure with {him}self. <i>“You do not mind the way Lane looks. {He} is easy on your eyes.”</i> {He} reinforces that several more times, before {he} sheepishly stops.",
				"Lane bites {his} lip, {his} eyes roaming your body as you sit there, enthralled by {him}. <i>“You...”</i> {he} says softly, unsure with {him}self. <i>“You will recommend Lane to your friends and coworkers. You believe {he} does a good job.”</i> {He} reinforces that several more times, before {he} sheepishly stops.",
				"Lane bites {his} lip, {his} eyes roaming your body as you sit there, enthralled by {him}. <i>“You...”</i> {he} says softly, unsure with {him}self. <i>“You find Lane mildly attractive. For a Daynar.”</i> {He} reinforces that several more times, before {he} sheepishly stops.",
				"Lane bites {his} lip, {his} eyes roaming your body as you sit there, enthralled by {him}. <i>“You...”</i> {he} says softly, unsure with {him}self. <i>“You like the way Lane keeps {his} business. You find {him} to be professionally approachable.”</i> {He} reinforces that several more times, before {he} sheepishly stops."
			];
		}
		else if (laneHypnosisLevel() == 1)
		{
			msgs = 
			[
				"Lane hums to {him}self as {he} looks at you, seeing you so open to {him} and {his} suggestions. {He} stutters, unsure if {he} should proceed, but {he} does. <i>“You like Lane. You think you’ll visit {him} more often, and not just for {his} business.”</i> {He} reinforces that several more times, and then stops {him}self.",
				"Lane hums to {him}self as {he} looks at you, seeing you so open to {him} and {his} suggestions. {He} stutters, unsure if {he} should proceed, but {he} does. <i>“Your opinion of the Daynar is improved because of Lane. You enjoy their company and believe them to be a friendly, understanding species.”</i> {He} reinforces that several more times, and then stops {him}self.",
				"Lane hums to {him}self as {he} looks at you, seeing you so open to {him} and {his} suggestions. {He} stutters, unsure if {he} should proceed, but {he} does. <i>“You think Lane is reasonably attractive. {He} is a " + lane.mf("handsome", "beautiful") + " Daynar.”</i> {He} reinforces that several more times, and then stops {him}self.",
				"Lane hums to {him}self as {he} looks at you, seeing you so open to {him} and {his} suggestions. {He} stutters, unsure if {he} should proceed, but {he} does. <i>“You like the way Lane looks at you. You think it’s cute.”</i> {He} reinforces that several more times, and then stops {him}self.",
				"Lane hums to {him}self as {he} looks at you, seeing you so open to {him} and {his} suggestions. {He} stutters, unsure if {he} should proceed, but {he} does. <i>“You consider Lane to be a dependable business" + lane.mf("", "wo") + "man and a good friend. You wonder if Lane could be more to you.”</i> {He} reinforces that several more times, and then stops {him}self."
			];
		}
		else if (laneHypnosisLevel() == 2)
		{
			msgs =
			[
				"Lane chews at {his} lip and {his} claw tacks on {his} chair. You’re so vulnerable, so malleable; {he} begins to rub {his} knees together sensually as {he} looks at you. <i>“You think Lane is sexy. You often fantasize about {him} when you’re by yourself.”</i> {He} reinforces that statement several more times, before {he} forces {him}self to stop.",
				"Lane chews at {his} lip and {his} claw tacks on {his} chair. You’re so vulnerable, so malleable; {he} begins to rub {his} knees together sensually as {he} looks at you. <i>“You find yourself compelled to talk about Lane to your friends. You want to promote {his} business as much as you can.”</i> {He} reinforces that statement several more times, before {he} forces {him}self to stop.",
				"Lane chews at {his} lip and {his} claw tacks on {his} chair. You’re so vulnerable, so malleable; {he} begins to rub {his} knees together sensually as {he} looks at you. <i>“You sometimes wonder what Lane looks like beneath the rest of {his} clothing.”</i> {He} reinforces that statement several more times, before {he} forces {him}self to stop.",
				"Lane chews at {his} lip and {his} claw tacks on {his} chair. You’re so vulnerable, so malleable; {he} begins to rub {his} knees together sensually as {he} looks at you. <i>“You have an urge, an itch, to taste Lane. You resist, with some effort.”</i> {He} reinforces that statement several more times, before {he} forces {him}self to stop.",
				"Lane chews at {his} lip and {his} claw tacks on {his} chair. You’re so vulnerable, so malleable; {he} begins to rub {his} knees together sensually as {he} looks at you. <i>“You want to touch Lane, to feel along the smoothness of {his} front scales. You want to touch {him} everywhere, in a sensual way.”</i> {He} reinforces that statement several more times, before {he} forces {him}self to stop."
			];
		}
		else if (laneHypnosisLevel() == 3)
		{
			msgs = 
			[
				"Lane splays {his} legs. Now that the business is done, {he} can proceed with the pleasure. {He} openly begins to rub at {him}self, enjoying the way {he}’s displaying {him}self to you and you’re too brainwashed to even notice. <i>“You can’t get enough of Lane. You want to visit {him} every day to hypnotize you. You love the way {he} controls you.”</i> When {he} finally stops reinforcing that statement, {he}’s spent more time hypnotizing you for {him}self than {he} has doing what you paid {him} for.",
				"Lane splays {his} legs. Now that the business is done, {he} can proceed with the pleasure. {He} openly begins to rub at {him}self, enjoying the way {he}’s displaying {him}self to you and you’re too brainwashed to even notice. <i>“You think Lane is the sexiest creature you’ve ever seen. Nothing and nobody else excites you the way Lane does.”</i> When {he} finally stops reinforcing that statement, {he}’s spent more time hypnotizing you for {him}self than {he} has doing what you paid {him} for.",
				"Lane splays {his} legs. Now that the business is done, {he} can proceed with the pleasure. {He} openly begins to rub at {him}self, enjoying the way {he}’s displaying {him}self to you and you’re too brainwashed to even notice. <i>“Every time you see Lane, you fantasize about " + lane.mf("his cock and what it’ll take to get him to use it on you", "her cunt and what it would be like to finally taste her") + ".”</i> When {he} finally stops reinforcing that statement, {he}’s spent more time hypnotizing you for {him}self than {he} has doing what you paid {him} for.",
				"Lane splays {his} legs. Now that the business is done, {he} can proceed with the pleasure. {He} openly begins to rub at {him}self, enjoying the way {he}’s displaying {him}self to you and you’re too brainwashed to even notice. <i>“You can no longer imagine life without Lane. Your days aren’t complete without worshiping {him} by giving him your body to mold.”</i> When {he} finally stops reinforcing that statement, {he}’s spent more time hypnotizing you for {him}self than {he} has doing what you paid {him} for.",
				"Lane splays {his} legs. Now that the business is done, {he} can proceed with the pleasure. {He} openly begins to rub at {him}self, enjoying the way {he}’s displaying {him}self to you and you’re too brainwashed to even notice. <i>“Lane turns you on so much that each day " + lane.mf("he doesn’t bend you over his desk and take your ass, body, and soul with his cock", "she doesn’t throw you to the ground and claim you as hers with her sweet, sexy cunt") + " is a day that is wasted.”</i> When {he} finally stops reinforcing that statement, {he}’s spent more time hypnotizing you for {him}self than {he} has doing what you paid {him} for."
			];
		}

		outputText("\n\n" + msgs[rand(msgs.length)]);
	}

	clearMenu();
	addButton(0, "Next", lanePostApplyEffect, selectedService);
}

function lanePostApplyEffect(selectedService:String):void
{
	clearOutput();
	outputText("You awaken with a bit of a start. You’re a little dizzy; you’re seeing stars in your eyes and your ears are ringing and your nose is itchy. And yet... you feel amazing. You’re back at the desk in the front room, sitting in the same chair, and Lane is across from you, smiling confidently. <i>“How do you feel?”</i> {he} asks you.");

	outputText("\n\nYou admit that you’re mostly confused. The last thing you remember is being in Lane’s ‘hypnosis room’, following {his} instructions, but then... nothing, and now you’re back at {his} desk. And yet");
	switch (selectedService)
	{
		case HYPNO_STAT_PHYS:
			outputText(" your body feels stronger, tighter... you feel as though there are no obstacles that you can’t overcome, if you just put in a little effort. You’re half tempted to start running, for the sake of it. <b>Your body has never felt better!</b>");
			break;

		case HYPNO_STAT_REF:
			outputText(" your senses all feel so fine-tuned... you can hear Lane’s heartbeat and you can feel the subtle changes in the air pressure as the breeze flows outside the building. A buzzing flits across your ear, and you turn – and you see a common fly buzzing around just beyond the door. You had heard something so small from so far away before you could see it. <b>Your reflexes are better than ever!</b>");
			break;

		case HYPNO_STAT_AIM:
			outputText(" your eyesight has never been better: you’re seeing objects and details with a sort of clarity you had never thought possible before. You can make out every speck of dust flitting through the air between you and Lane, and, if you squint, you can make out the individual swirls and marks, like fingerprints, on {his} scales. {He} blinks, and you can see {his} pupil dilate just slightly from it. <b>Your aim is better than ever!</b>");
			break;

		case HYPNO_STAT_INT:
			outputText(" this very situation reminds you of this one time you were being quizzed in middle school. You remember the teacher, your classmates, and the class so perfectly… you even remember the quiz, and each of its questions, and more importantly, each of their answers. <b>Your intelligence is better than ever!</b>");
			break;

		case HYPNO_STAT_WILL:
			outputText(" you have this urge to start chewing Lane out, demanding to know what {he}’s done to you, and you’re not leaving without a satisfying answer. You tell {him} exactly what you’re thinking, and {he} only smiles in response – and you reel, surprised at yourself and that sudden, willful outburst. <b>Your willpower is stronger than ever!</b>");
			break;
		
		case default:
			throw new Error("Couldn't match selected service.");
			break;
	}

	if (!hasLaneHypnosis())
	{
		outputText("\n\nYou sit and look at your hands. It was a strange, difficult-to-explain sensation: you knew you were different, but you didn’t really <i>feel</i> different. At the same time, you felt different, but you didn’t know if you really <i>were</i> different. Lane definitely did something to you, and whatever it was {he} did, you like it. You tell {him} as much, and {he} claps {his} four-fingered hands together. <i>“I’m happy that you’re happy with the results, [pc.name],”</i> {he} tells you.");
		if (flags["LANE_TIMES_HYPNOTISED"] <= 1) outputText(" <i>“I hope this changes your perception on hypnotism.”</i> You tell {him} that it definitely does, and that you’ll be coming back for {his} service sometime in the future. You even ask {him} if you could sign {his} guestbook, to give {him} another testimonial to add to {his} collection, and {he} happily hands you {his} codex.");

		outputText("\n\nYou thank him for {his} work again, and you leave {his} little hut, ready to tackle the day with the new and improved you.");

		if (flags["HAS_HAD_LANE_HYPNOSIS"] == 1)
		{
			if (laneHypnosisLevel() == 0) outputText("\n\nAs you leave {his} hut, your thoughts linger on Lane just a little while longer. {He}’s certainly an alright sort. You wouldn’t mind having a drink with {him} sometime later, or something.");
			else if (laneHypnosisLevel() == 1) outputText("\n\nYou’ve been getting rather friendly with Lane lately, and {he} holds {him}self very professionally... and, you decide, {he}’s a bit of a looker. For a bipedal lizard-person. You consider asking {him} out to dinner sometime, to get to know {him} outside of {his} profession.");
			else if (laneHypnosisLevel() == 2) outputText("\n\nYou spare a look back at {his} hut as you leave. Just... something <i>about</i> Lane really pushes all your kinky buttons. You idly fantasize about what it’d be like to get into bed with a sexy Daynar like {him}self...");
			else outputText("\n\nYou can’t seem to get that sexy lizard off your mind as you leave {his} hut. Images of yourself at {his} knees, servicing {him} like {he} was your " + lane.mf("king", "queen") + " and it was your privilege, assault your mind, and you gladly let them. You’re itching to march right back in there and throw yourself at {him}, demanding {he} take you then and there, but, after some struggle, you keep walking. You have others things that need doing.");

			// Place PC one square outside of Lane’s Plane
			// TODO: figure out where PC is gonna go.
			clearMenu();
			addButton(0, "Next", mainGameMenu);
		}
	}
	else
	{
		outputText("\n\nYou’re happy that Lane, righteous and generous as {he} is, kept up {his} end of the bargain and gave you what you paid for. But another part of you is ecstatic about what’s going to happen next. You thank {him} for {his} continued excellence, and that, if {he}’s ready, you’re prepared to pay {him} your ‘taxes’ for the privilege of being {his} to own.");

		outputText("\n\n{He} smiles and stands. You stand with {him}, and with a deft, swift hand, {he} grabs you by the collar of your [pc.armor] and pulls you in for an aggressive, dominant kiss. You melt into {him}, opening your mouth and inviting your {master’s/mistress’s} tongue to play with your [pc.eachTongue]. {He}’s grabbing at you roughly and possessively as {he} suffocates you with {his} lips and {his} tongue, guiding you across the desk and to the curtains hiding the second half of the room.");

		outputText("\n\n{He} finally lets you go as {he} opens {his} eyes and {his} tassels wide at you, letting you fall into {him} a second time. Your body sinks");
		if (pc.hasCock() && !pc.hasVagina()) outputText(" but [pc.eachCock] rises");
		else if (pc.hasVagina() && !pc.hasCock()) outputText(" and your [pc.eachVagina] slickens");
		else if (pc.hasVagina() && pc.hasCock()) outputText(" as [pc.eachCock] fights with [pc.eachVagina] for your blood flow, your attention, and your hopes");
		else outputText(" as you lick your [pc.lips] and your [pc.ass] clenches");
		outputText(" while you consciously fall deeper into {his} control, but {he} doesn’t let you zone out like before.");

		outputText("\n\n{He} leads you to {his} bedroom, across from {his} hypnosis room, and as soon as {he} shuts the door behind you, {he}’s stripped of both {his} airy shirt and {his} flowing pants, leaving {him} with only {his} underwear. " + lane.mf("The unmistakable bulge of his delicious, virile Daynarian cock pushes against the stubborn fabric, outlining the trail of his meat from his tip to his base, and it only gets more pronounced with each heartbeat.", "A small damp patch is clearly visible between the cleavage of her legs, but more than that, the musky scent of her needy, demanding sex penetrates the air, and your nostrils, with ease.") + " Your fingers fidget as you imagine just how Lane is going to use you today.");

		outputText("\n\n<i>“Strip naked,”</i> {he} commands, and you do so with ease and without any flair, eager to just get right to servicing your " + lane.mf("master", "mistress") + " once more. Soon, your [pc.armor] is discarded to a pile in the corner, and you’re left as naked as Lane is, once {he} removes {his} undergarment, bearing all of {him}self to you once more.");

		outputText("\n\nAnd to think, you used to hate doing your taxes.");
		// Go to Randomized sex
		clearMenu();
		addButton(0, "Next", payTheLaneTax);
	}
}

function payTheLaneTax():void
{
	clearOutput();

	var availScenes:Array = [];

	if (lane.mf("m", "f") == "m")
	{
		flags["LANE_MALE_SEXED"] = 1;

		availScenes.push(suckLanesDick);
		availScenes.push(fuckedByMaleLane);
	}
	else
	{
		flags["LANE_FEMALE_SEXED"] = 1;

		availScenes.push(munchLanesCarpet);
		availScenes.push(fuckedByFemLane);
	}
}

function laneSexSelection():void
{
	var availScenes:Array = [];

	if (lane.mf("m", "f") == "m")
	{
		flags["LANE_MALE_SEXED"] = 1;

		if (pc.hasCock() || !pc.hasVagina()) availScenes.push(firstTimeLaneMPCM);
		if (pc.hasVagina()) availScenes.push(firstTimeLaneMPCFH);
	}
	else
	{
		flags["LANE_FEMALE_SEXED"] = 1;

		if (pc.hasCock()) availScenes.push(firstTimeLaneFPCMH);
		if (!pc.hasCock()) availScenes.push(firstTimeLaneFPCFGenderless);
	}
}

function suckLanesDick():void
{
	clearOutput();

	outputText("Lane walks past you and sits on the edge of his large bed, his cock pointing towards the ceiling. <i>“I want to feel your [pc.lips] on me,”</i> he says, taking your hand and insistently pulling you towards him. <i>“I want you to swallow my cock and tell me how much better Daynarian cum tastes compared to anyone else’s.”</i>");

	outputText("\n\nYou admit that that’s a pretty hot idea, and you eagerly sink to your knees, levelling yourself with his dick. It’s long, thin, and tapered; it has no visible bumps or veins anywhere on it, its skin thick and smooth as could be. His genital slit, normally hard and rough, clings to the base of it wetly and is easily malleable between your fingers.");

	outputText("\n\nYou test the waters by wrapping your fingers around it, feeling its heat and its pulse. It’s slimy; he’s not leaking with pre yet, so you’re not sure with what. It’s about six inches long");
	if (pc.hasCock() && pc.averageCockLength() >= 7) outputText(" – you’ve seen longer, but you know it’s not a competition");
	outputText(", and it’s thin: you can easily wrap your fingers all the way around it, and then some. Yet, with every pulse, you can feel it getting just <i>slightly</i> thicker.");

	outputText("\n\nYou pump your hand up and down his length gently, savoring its feel and the way you make your master sigh in delight and jerk his hips involuntarily. Your palm gets soaked in whatever juice was keeping his nice, warm dick all wet and ready for you. Its smell is alien to you: hardly repugnant, but the pheromones are a bit weak and grainy.");

	outputText("\n\nYou feel Lane’s hand on your scalp, massaging you as you work him. You lean in close, getting your [pc.face] right up against the skin of his penis. You feel its heat wash over your nose and Lane quivers every time your breath washes over his crotch. You love teasing your master, taunting him with the service he wants as you slide your hand from the pointed tip to the thick base, his groans sinful music to your ears. He, however, has enough, and insistently pushes on you towards his dick.");

	outputText("\n\nLicking your [pc.lips], you glide your moist hand up and down his pole twice more, and then you replace it with your mouth. You barely open your mouth wide enough for his already thin tip, and suck it in, clamping tightly on the head of his penis. That doesn’t do much for him, though, and you know that; Daynarian penises get more sensitive towards the base, unlike most other species.");

	outputText("\n\nThe taste on your [pc.tongue] is delicious, knowing it’s your master. You lick and lap at the opening of his penis, trying to coax out anything to play with, but he’s being stubborn. As your lips maintain their suction, you can better feel Lane’s unique cock as it expands against you, prying your lips apart with every other pulse. You trail your eyes from his pelvis, across his stomach, up his chest, and innocently into his eyes as you lower yourself ever so slowly.");

	outputText("\n\nHe grins back down at you and grips tighter onto your [pc.hair]. He shows amazing restraint, keeping from thrusting into your throat and taking what he wants; rather, he lets you go at your teasing pace as you slide down his meat, tasting and examining every nuance with your [pc.tongue]. He slides past your teeth and across the flat of your tongue, crawling deeper and deeper into your mouth.");

	outputText("\n\nWithout breaking eye contact, you come to his base. He grunts in appreciation as your lips slide over those hot nerve endings. You stay there, holding your breath, letting his taste conquer your mouth and letting you imprint on his taste. It grows thicker and thicker with each passing second; already it’s maybe twice the thickness of when it started, and you know it’s not about to stop.");

	outputText("\n\nYou feel a small drop of his pre on your tongue before you taste it. It tastes just like his dick, conveniently enough, but stronger. Back down you go, kiss the skin that melds with his penis, making him sigh out in pleasure. Another drop is waiting for you when you get back to the top.");

	outputText("\n\nYou settle into a faster rhythm, for his benefit, and he moans out in appreciation. <i>“You’re a good cocksucker,”</i> he compliments. <i>“You know just what I like. Not too fast...”</i> You smile, his dick splitting your [pc.lips] wider and wider. Every time you sink down, his penis tickles the roof of your mouth and delights your [pc.tongue]; every retreat leaves you both breathless for more.");

	if (pc.hasTongueFlag(GLOBAL.FLAG_HOLLOW))
	{
		outputText("\n\nOne of the advantages of having a new, hollow tongue, is giving amazing blowjobs with it – or, so you’ve ever fantasized, but you figure now would be a good time to try. You pull all the way back from Lane, to his confusion, so you can line up your shot. It takes you a second to feel it out, but once you’ve got it, you slide your [pc.tongue] all the way down, slowly.");

		outputText("\n\nLane visibly shivers as your warm, wet tongue sucks him up, massaging his every nerve with your tastebuds. His pulse beats off-sync with yours; you contract and convulse your tongue, doing your best to simulate a vagina for his benefit, and it seems to work. <i>“Ooooh, that’s new,”</i> he coos, and he tightens his grip on your head.");

		outputText("\n\nYou lower yourself all the way down his shaft, until you connect to his skin, and start to kiss and stroke his base with your [pc.lips] while your tongue undulates around the rest of his cock. The sensations cause his heartbeat to quicken and his hips to thrust upward impishly; you smile, taking your own pleasure from pleasing your master so well.");
	}

	if (pc.biggestTitSize() >= 3 && pc.biggestTitSize() <= 14)
	{
		outputText("\n\n<i>“Let me feel those tits of yours,”</i> he commands, and you’re all too happy to comply. You draw your mouth up and up until you, with some reluctance, you pull away from him completely, leaving his wet cock to the cold air between you. You don’t leave it alone for too long: you lean forward, wrapping your [pc.chest] around his meat, giving it a cushy new home to dwell in.");

		outputText("\n\nPressing your tits together, you begin gently rocking yourself up and down his length.");
		if (pc.biggestTiTSize() <= 7) outputText(" You see the tip of it poke up from between your heaving boobs, slathering your own spit into your cleavage, the cumslit slightly dilated with precum and promises of more if you keep it up.");
		if (pc.biggestTitSize() >= 8 && pc.biggestTitSize() <= 14) outputText(" The only guarantee that his cock is still between your mammoth boobs is the warm feel of it splitting your cleavage and slathering you with your own spit. You occasionally feel a warm bead of liquid spurt out and add to the mess, with promises of more if you keep it up.");

		outputText("\n\nYou lean your head down");
		if (pc.biggestTitSize() >= 8 && pc.biggestTitSize() <= 14) outputText(", searching for his dick in the deep, sweaty valley of your [pc.chest]");
		outputText(", and");
		if (pc.biggestTitSize() >= 8 && pc.biggestTitSize() <= 14) outputText(", after some effort, your face pressed deep into the fat of your tits,");
		outputText(" you wrap your lips around his cock once again, tasting and teasing his tip while your jugs do the rest of the work. He thrusts; you lean and rock against him; and you use your hands to press them together tighter for his pleasure and benefit.");

		if (pc.isLactating())
		{
			outputText("\n\nThe motions of your bodies causes your [pc.milk] to spray from your [pc.nipples] after each bump and squeeze. Your liquids drip and splash from you and onto his body, coating his lower stomach in it. <i>“I understand the appeal behind a big set of boobs,”</i> he says, humping against you with as much fervor as ever, <i>“but the... milk? The milk, I just can’t wrap my head around.”</i> That said, he doesn’t seem to mind it coating you both, even if it makes things a little sticky.");
		}
	}

	outputText("\n\nYou proceed as you are for several minutes, with him feeding you his cock and his precum, until the familiar, bestial quickening of his motions and his breath makes his orgasm obviously close. You don’t stop – in fact, you go faster, eager to taste your master again.");
	if (pc.biggestTitSize() >= 3 && pc.biggestTitSize() <= 14) outputText(" You pull your [pc.chest] away and engulf him in your mouth once more. No sense in letting any of it go to waste on you when it would go so much better <i>in</i> you.");

	outputText("\n\nHis hands go to the edge of the bed for stability as he fucks your throat until he ejaculates. His shaft as rock hard and thick enough to graze your front teeth if you didn’t stretch your jaw to accommodate him. You hear his moans of bliss before you feel the warmth of his cum blossom in the back of your throat, pooling into your cheeks and submerging your tonsils in his ambrosia. He humps into your mouth erratically several times, each one accentuated with another giving of his cream, each blast getting weaker than the one before it until he’s cumming nothing.");

	outputText("\n\nWhatever doesn’t immediately get swallowed bathes your tongue and your gums for a moment before you gulp it down. He moans, enjoying the afterglow of his release; you take the time to bathe and wash his cock, which is still hard and has a warm home in your mouth, but is shrinking. After a minute, it begins to recede into himself; you follow it every inch of the way, washing him lovingly and even hoping to go for another round, but it’s no use. You’re kissing and licking at his genital slit before he pushes you away.");

	outputText("\n\n<i>“That was good, [pc.name],”</i> he tells you, and you smile at the praise. <i>“You’ve done well. Now, tell me what I want to hear.”</i>"0;

	outputText("\n\nYou haven’t forgotten what he told you before you had started. <i>“It was delicious, master Lane. Daynarian jizz is so much better than anything or anyone else’s. I don’t think I’ll ever be satisfied giving head to anyone else again.”</i>");

	outputText("\n\nHe pats you on the head, and from the corner of your eye, you can see his slit bulging slightly, threatening to burst with his dick again, but he stands. <i>“You</i> do <i>know what I like. We’ll be doing that again in the near future, I can promise you that. But, for now, we both have jobs to do.”</i>"0;

	outputText("\n\nDisappointed but understanding, you pull yourself to your feet, trying to ignore the fire in your own loins for the time being. You both get dressed, you stealing glances at his naked ass and form whenever you can.");

	outputText("\n\nWhen you’re both presentable again, you leave his room wordlessly. He returns to his desk and immediately starts playing with his codex again as he waits for another client; he doesn’t so much as give you a glance as you leave his hut.");

	pc.loadInMouth(lane);
	lane.orgasm();
	pc.lust(30);
	processTime(30);

	// Lust increases by 30; place the PC one square outside of Lane’s Plane

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function munchLanesCarpet():void
{
	clearOutput();
	outputText("Lane walks past you and sits on the edge of her large bed, splaying her legs and displaying all of herself to you. <i>“I want that talented tongue of your inside me,”</i> she says, reaching down with one hand and spreading her already moist and welcoming cunny for you. <i>“I want you to lick me until I cum in that pretty mouth of your and I want you to thank me for the opportunity.”</i>");

	outputText("\n\nYou don’t need any further commanding; you take a step forward and sink to your knees, eagerly placing yourself between her open knees and your mouth just inches away from her pussy. It’s similar to most other cunts you’ve seen, but with a few differences: beside her spread labia is her genital slit, which is tough and stiff when she’s unaroused, but is soft and malleable when she is. Her pink, narrow walls wink at you invitingly, waiting for you to take the plunge into her and pull you inside. Unfortunately, she has no clitoris – ");
	if (pc.hasVagina()) outputText("you feel sorry for your mistress. She doesn’t even know what she’s missing.");
	else outputText("you’re told that that’s something women generally enjoy having.");

	outputText("\n\nYou lean in close, breathing hotly on the skin of her sex, resting your cheek on the fat of her thigh. You wrap your hands around her legs, massaging the thick, scaly skin and muscles, worming your fingers forward towards the plush of her ass. You can smell the musk of your mistress emanating from her, conquering your nostrils and teasing your tongue, inviting you to close the gap.");

	outputText("\n\nYou let go of her right thigh and bring your left hand to her entrance; gently, you pet at her pussy, feeling her moisture collect between your digits, making them stick together. She ‘mmms’ at your feathery touch and opens her legs just a little wider, giving you more room to play with. Locking your eyes with hers, you bring your fingers, dewy with her essence, and slowly lick them clean, before putting them back and exploring further.");

	outputText("\n\nTwo fingers easily slide inside her. She arches her back slightly and drags her hips forward, resting her ass on the bedside. The walls of her vagina are streamlined and move in ripples, from her outer lips all the way to her womb. With her every muscle contraction, her pussy grips tighter onto your fingers and subtly drags you into her, wanting you to go as deep as you can.");

	outputText("\n\nYou don’t give her the satisfaction just yet, though. You go as deep as the second knuckles on your fingers, crooking them to feel along the smooth lines and ripples in her snatch. It makes her leap on her seat, but not as much as she <i>could</i> be, you know. You also know that her particular species is very sensitive at the labia; you crane your wrist so that your other two fingers brush and rub against one side of her outer labia, while your thumb toys with the other.");

	outputText("\n\nShe moans in delight at your teasing and rocks her body forward some more, urging you to continue and to go deeper. You sink your hand up to your third knuckles, reaching as deep as you can, but nowhere near where you know her Daynarian G-spot is. She yips in pleasure, swaying her hips side-to-side to grind your hand across as much of her as she can.");

	outputText("\n\n<i>“That’s good, that’s very good,”</i> she tells you, and you feel a sense of belonging when your mistress gives you her praise. <i>“But as well as you’re doing, [pc.name], I asked for your mouth.");
	if (!silly) outputText(" If I want your hands, I’ll ask for them. Now let me feel your mouth on me.”</i>");
	else outputText(" You know the saying: ‘a handjob’s a man’s job; a blowjob’s a ho’s job.’”</i> You look up to Lane’s eyes. <i>“I know what I said.”</i>");

	outputText("\n\nWith just a touch of difficulty, you withdraw your fingers from her pulling snatch, drenched and sticky in her alien girl-jizz. You bring them to your nose, taking a whiff of her undeniably-Lane scent. You lick them clean once more, trying to make a show of it for her, and when they’re totally clean, you lean in for the real deal.");

	outputText("\n\nThere’s no more hesitation or teasing: you kiss her labia, your [pc.lips] sliding over hers, collecting the drops of her lust on them. Your tongue licks and plies along her entrance, dipping in just a little with each pass. She tastes salty; grainy; and a little thick, but the taste in unique to her alone, that the thought that you’re eating your mistress’s box alights a fire in you.");

	outputText("\n\nYour hands, without permission, go forward and clamp directly onto Lane’s thin, scaly ass for support. She sighs out loud as she feels you penetrate her; you moan out yourself as you feel the unique sensation of your tongue being pulled and squeezed by the unique muscles of Lane’s Daynarian sex. With her every pulse, her cunt contracts and you feel her get just a little bit wetter.");

	outputText("\n\nHer hands press down on your [pc.hair], playing with what she finds as she pulls you into her crotch. As your tongue reaches deeper into her, you move your lips to try and cover her own as best as you can, knowing that she derives a great deal of pleasure from it.");
	if (!pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(" Lane’s grip is tight, not painfully so but tight, and she crams as much of her pussy against your face as she can with every hump she makes. You’re reaching as far as you can into her, but it’s just not enough to satisfy her. You don’t dwell on it, though: you hope to make up for your shortcomings with enthusiasm, and you don’t hear her complaining.");
	else outputText(" Lane coos out in delight as she feels your long, slender, wriggling tongue crawl its way deeper into her, feeling along every ridge inside her and tickling all the right spots. She gasps when you reach her G-spot, deep inside her, and you relax – with your lips sealed to her cunt, you didn’t have much slack left to go! Now that you know you’ve hit the mark, you relax and start acting casual with your cunnilingus.");

	// This was "super long", but we don't have a super long flag and fuck adding one.
	if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" Your tongue rolls into her like a long, fleshy pink carpet, connecting her every vaginal nerve and muscle to you. You surge into her in ‘waves’, going in a little, then stopping and exploring what you have before continuing. You aren’t even one-fourth out of tongue by the time you hit her G-spot. Lane, though, isn’t complaining; her claws painfully scrape against your head in her throes of passion and her hips squeeze against your cheeks almost reflexively as you work on her, hitting every special spot with ease again and again. Her every lustful gasp and yelp is like music to your muffled ears.");

	outputText("\n\n<i>“That’s more like it,”</i> she says, her ass halfway off the bed. You push back against her, squashing your features against her crotch, and not caring as long as it pleasures your mistress. You try to look up at her eyes, but your vision is obscured by her heaving breasts and unfocused from her pulsing blood.");

	outputText("\n\nYou decide that if you can’t look at her, then you can do your best to feel her; your hands begin roaming as high as her lower torso and as low as her ankles, kneading and massaging the silky smooth skin of her lower body (and tickling along the hint of a set of abs she has), and pinching and plucking at the rockier, scaly exterior of the backs of her legs.");

	outputText("\n\n<i>“You want something to grope?”</i> you hear her ask. Your hands freeze where they are. She didn’t sound upset, but you <i>were</i> touching her without her permission. Still tongue-deep in her muff, you see some other wriggly thing approach you from the corner of your vision. <i>“Here, then. Squeeze my tail. Do it gently.”</i>");

	outputText("\n\nIt’s not the oddest request. You bring your left hand from her shin, feeling along the smooth contours of her tail’s underside, and the pebbly skin of its topside. You poke and press at the very tip of it like a button, and trail your hand across it, marveling at how thick it gets so quickly, and loving all the individual muscles you can easily feel along it. You grip it and stroke it like it were a cock, and Lane moans along like it were one too.");

	outputText("\n\nLane lets her tail flop down to rest across her leg, its tip pointed right at your face. If she wants it treated like a dick, then you can treat it like one. With an insistent grip, you yank it forward slightly, until its tip is right next to your [pc.lips].");
	if (pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(" You turn your head to the side, your [pc.tongue] still locked deep inside your mistress’s canal. You try and maneuver your face enough so that you can stick the tip of her tail inside without withdrawing too much from her, and you succeed.");
	else outputText(" You pull away from your mistress’s snatch for a moment, giving it a kiss before you depart. Lane looks down at you curiously, just in time to watch you stick her tail into your mouth, followed by another few inches.");
	outputText(" The rough texture of her skin hurts against your front teeth, and her tail doesn’t taste nearly as good or as unique as her pussy, but the delighted chirring you hear above is enough to satisfy you.");

	outputText("\n\nThe sudden inspiration causes Lane’s breath to leave her and her body to quake just slightly from her impending orgasm. She goes silent; her body begins shivering; and her hips rock forward another inch, leaving her dangling off the side of her bed.");
	if (!pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(" You withdraw the tail from your mouth, leaving a string of your saliva as the proof of your kinkiness, and return to your true duty with her pussy.");
	outputText(" Your right hand squeezes hard on however much ass it can just as she explodes into your mouth.");

	outputText("\n\nHer girlcum tastes as fine as every other part of her; it washes over your [pc.tongue] smoother than any malt you’ve ever had and straight into your waiting gullet.");
	if (pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(" Her tail thrashes along with the rest of her stimulated body, rocking against your lips and your teeth; her girlcum drenches and soaks the bit in your mouth, at least making it easier on your tongue as it does.");
	outputText(" Her knuckles go white from holding onto the bed so strongly as she humps against you several more times. The hungry walls of her cunt squeeze almost painfully on your tongue, milking it for all the cum it can’t provide and pulling incessantly on it");
	if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(", cramming more and more of it from your throat and inside of her");
	outputText(".");

	outputText("\n\nStreams of it drip from your assaulted lips; you swallow all that you can, in worship for your mistress, but the seal around her cunny wasn’t as airtight as you had thought,");
	if (!pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" especially with her tail in the corner of your mouth");
	outputText(". She has two smaller orgasms, pumping her cream into your thirst mouth each time, before she finally relaxes.");

	outputText("\n\n<i>“That was excellent, pet,”</i> she says, breathing heavily. She places a hand on your head and you feel a sense of pride for your good work. <i>“You’ve done me well. Now, where are your manners?”</i>");

	outputText("\n\nYou haven’t forgotten what she told you before you started. You pull away from her");
	if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(", your [pc.tongue] withdrawing with a loud, wet slurp");
	outputText(", and look lovingly into her eyes. <i>“Thank you so much for the opportunity to lick you, and suck you, and drink you, mistress Lane,”</i> you say sincerely. <i>“Performing for you and on you is all I could want in life.”</i>");

	outputText("\n\nHer hand rubs along your scalp affectionately, and you could swear that her genital slit nearly stops retracting her vagina from your words alone. <i>“You’re a very skilled slut, [pc.name]. We’ll be doing this again in the near future, for sure. But, I’m afraid fucking all day isn’t going to pay my bills.”</i>");

	outputText("\n\nDisappointed but understanding, you pull yourself to your feet, trying to ignore the fire in your own loins for the time being. You both get dressed, you stealing glances at her naked ass and form whenever you can.");

	outputText("\n\nWhen you’re both presentable again, you leave her room wordlessly. She returns to her desk and immediately starts playing with her codex again as she waits for another client; she doesn’t so much as give you a glance as you leave her hut.");

	lane.orgasm();
	pc.lust(30);

	processTime(30);

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function fuckedByMaleLane():void
{
	clearOutput();
	outputText("Lane approaches you, his cock in one hand and his other reaching out to grip onto your [pc.hair]. <i>“Have a taste, [pc.name],”</i> he says, jacking himself, his dick pointed right at your face.");

	outputText("\n\nYou’d be glad to. You sink to your knees in front of him and lick your [pc.lips] in anticipation, gently gripping onto his waist and kneading the hard scales there. You pucker your lips, waiting for him to stop touching himself; he takes the hint and, without much warning or preparation, he thrusts forward, sliding his thin dick into your thirst throat.");

	outputText("\n\nIts thin girth makes it easy to take for the moment, but you know that’s not going to last long. You suck and lick on the tasty, smooth, soft skin of his alien cock – although he’s ‘erect’, he feels flaccid compared to most other penises you know. You look up across his chest and into his eyes, letting them absorb you a little more, making it all the more pleasurable for you.");

	outputText("\n\nHe hums out as he saws himself in and out of your mouth. He takes sharp inhales when you get to the base of him, and exhales through the corners of his upturned lips when he pulls out. His dick tickles the back of your palate and warms the length of your tongue. It’s going to take a few minutes for it to balloon to its full girth, which you’re looking forward to. You can already feel it get thicker with each pulse.");

	outputText("\n\nYou do everything you can to get him to get harder faster: you gently suck; you lick; you kiss and tease every centimeter you can reach. Your hands keep busy pinching and groping at the fat of his thighs and the thick of his ass. You keep trying to fuck him with your eyes. It all works to your advantage: <i>“You’re a thirsty little slut, aren’t you?”</i> he says, twirling his fingers and lightly scratching at your head. <i>“Keep it up. We’re nearly ready.”</i>");

	outputText("\n\nYou obligingly keep up your pace, slathering his penis with your saliva. You can taste the occasional bead of precum from the his tip whet your gullet and then wash down your throat. By the time Lane’s had enough and pulls away, his cock is considerably thicker: it’s easily twelve centimeters thick when it leaves your lips again, a far cry from the spindly thing it was when it went in. You almost feel proud.");

	outputText("\n\n<i>“There you go,”</i> he praises warmly, <i>“you’ve done well. You’re an excellent cock fluffer.”</i> You’re a little confused as to what he wants, but it gets clearer when he lifts you by your armpits and then throws you onto the bed, face down and bent at the waist, your [pc.vagorass] exposed and winking vulnerably to him.");

	outputText("\n\nHe claps his hands down on your [pc.ass] painfully. The sound of his hands slapping you echo off the wall, followed by your pained yell. He thrusts his hips forward, his cock jamming between your thighs;");
	if (pc.hasVagina()) 
	{
		outputText(" he slides his smooth tool between your labia and kisses your [pc.clit] with his tip");
		if (pc.balls > 0) outputText(", and");
	}
	if (pc.balls > 0) outputText(" his hot length tucks itself between your [pc.balls] and massages along the taut skin of your [pc.sack]");
	if (!pc.hasVagina() && !pc.hasCock()) outputText(" it humps against your blank crotch, and Lane grunts in disappointment. He keeps at it, but it’s clear he’s not deriving as much pleasure from it as he’d like");
	outputText(".");

	outputText("\n\n<i>“I love [pc.race] asses,”</i> he says. He leans forward, pressing his chest and stomach against your upper and lower back. His tongue slips out and licks along the back of your ear, and you swoon. <i>“So much better than Daynarian asses. Ours are all hard and boney; but, with an ass like yours...”</i> He draws his cock against you once more");
	if (pc.hasVagina()) outputText(", soaking it in more of your juices");
	outputText(". <i>“I feel like I could fuck it for days. Would you like that? Would you like to spend the weekend on my dick?”</i>");

	outputText("\n\nYou smile and back yourself against him, wordlessly telling him what you think of that");
	if (pc.hasCock()) outputText(". Your [pc.cock] rubs against the fabric of his bed. You leak a little bit of your own pre; you hope your master doesn’t mind");
	outputText(". He laughs a little, and brings his hands up, rubbing softly yet possessively against your sides and your lower ribs. He keeps his claws extended the whole time, leaving a light red trail from your butt to wherever he’s going.");

	if (pc.biggestTitSize() <= 2) 
	{
		outputText("\n\nHis hands reach up and roughly maul onto your [pc.chest]. He ‘ooh’s’ at what he finds and gropes at your flat tits a couple times. <i>“Still better than our typical females. Though you should consider looking into ‘enhancement’. It’s certainly make your master happier.”</i>");
		if (pc.hasCock() && !pc.hasVagina()) outputText(" You look back to Lane, concerned. <i>“Don’t worry about what the rest of the universe thinks. Daynarians love boobs on anybody. Everybody will understand if you tell them you got them for your master.”");
	}

	if (pc.biggestTitSize() >= 3) outputText("\n\nHis hands reach up and roughly grope at your [pc.chest]. He exhales in excitement at what he finds; his tongue lolls out and licks along your bare shoulder while his hands go to town on the fat of your breasts. <i>“I don’t think I’ll ever be satisfied with a girl of my own species again. Not with a pair of tits like these.”</i> He pinches and pokes at your soft, plushy skin, leaving marks on you. His claws round about your mounds, meeting in your cleavage, and then switch boobs, crossing his arms across you.");
	if (pc.biggestTitSize() >= 18) outputText(" They barely get very far, though – your massive breasts take up far too much space for him to reach very well. But, from the way his hips jack a little harder against you, he’s perfectly okay with that.");

	outputText("\n\nHis claws click on your [pc.nipples], squeezing them tightly. <i>“And these, these are unique. I’m told you have these all your life?”</i> You shudder as he mistreats them. It makes you so much hornier, but his insensitivity makes it more painful than you’d appreciate. <i>“I don’t even know the first thing about them. You’ll have to walk me through their intricacies someday. It’ll be a learning experience for both of us, I’m sure.”</i>");
	if (pc.hasFuckableNipples()) outputText(" His claws sink into your sensitive [pc.nipples] as he fondles them, eliciting a familiar groan from you. <i>“I don’t think having an extra pair of cunts is normal, either, but who am I to say in this universe of ours?”</i>");
	else if (pc.hasNippleCocks()) outputText(" His claws scratch and grip along your [pc.nipples] as he fondles them, eliciting a familiar moan from you. <i>“Is having a pair of extra dicks a ‘thing’ with your species? Should I be jealous? Was I born the wrong species?”</i>");

	outputText("\n\nHe rocks himself against you some more. His dick is hot and, you guess, about as hard and thick as it’s going to get. Every time you feel it spear between your legs, and not into your [pc.vagOrAss], you whimper in need. <i>“You sound... needy.</i> Lane, already leaning almost totally over you, lowers his body and presses you into the bed below you. You’re pinned motionless, but Lane keeps teasing you by rubbing his entire body against yours. <i>“What do you need, [pc.name]? Tell your master. I’m in a generous mood.”</i>");

	outputText("\n\n<i>“You!”</i> you should through clenched teeth and pressed lungs. <i>“I need you, master Lane! Please, I need you inside me!”</i>");

	outputText("\n\nYou feel him rear his pelvis away from you. <i>“If that’s what you need.”</i> He reaches back with one hand and feels between you both, gripping onto his cock, and then aligns it with your [pc.vagOrAss]. He slowly begins to feed it into you, centimeter by agonizing centimeter. You’d thought his penetration would calm the fires of your lust, but it only feeds them!");

	outputText("\n\nHaving him inside you again is the most wonderful, pleasurable feeling you can imagine, but it doesn’t make you want it any less. He teases you by going slowly; you take action and thrust back, shoving more of his now gorgeously thick dick into your waiting hole. He gasps out in surprise and clicks his tongue playfully. <i>“You’re so eager! I hope you’re not thinking of taking advantage of your master’s hospitality.”</i> His voice is low and he’s trying to sound serious, but his tone is light-hearted, and he doesn’t squeeze or press you any harder. <i>“You know what they say about rabbits and turtles, or whatever.”</i>");

	outputText("\n\n<i>“Speaking of rabbits, let’s fuck like a pair,”</i> you say huskily, and back your ass up some more, squeezing some more of him into you. He only laughs and begins his own thrusting, cramming his dick into your [pc.vagOrAss], filling the room with the sound of his thick shaft plowing past your");
	if (pc.hasVagina()) outputText(" vulva and into your wet, waiting depths");
	else outputText(" [pc.asshole] and hinting at poking into your stomach.");

	outputText("\n\nYour head lowers and you relax. Your master is back inside you again – Lane wanted to fuck you, so you wanted to be fucked, and you’re getting what you wanted. You nearly don’t notice when his hands let go of your body and roughly grip onto the sheets on either side of your face. He pulls away, withdrawing from you, making you whimper at the sudden chill around your junk, and then he roughly thrusts back in.");

	outputText("\n\nThe room is filled with the squelching of your mixing juices and the slapping of his hips against yours as he fucks you like he were running a marathon. You can’t help but smile as he goes at it; your [pc.vagOrAss] spreads invitingly around his tool, sucking him in and resisting when he tries to pull away. His breath starts coming out raggedly, with shuttering exhales and long inhales; it washes down your back in a warm wave, and you absolutely love it.");

	outputText("\n\n<i>“Is this what you had in mind?”</i> Lane asks you. His voice comes out unevenly between his thrusts. <i>“Pressed into my bed, getting fucked like an animal by your master? Do you want my cum inside you, and to come back for seconds when it leaks out?”</i>");

	outputText("\n\n<i>“Yeeeeeesssssss~”</i> you moan languidly. You spread your legs wider, giving him more space to fuck you with. You wish his cock could get thicker, to split you wider, to give you <i>more</i> of him. His desires are yours, and you want nothing more than to be fucked by Lane and have him shoot his warm lizard load inside of you.");

	outputText("\n\n<i>“You’re a good bitch.”</i> He gets off of you and stands back onto his feet, never letting himself pull out. He smacks onto your [pc.ass] with both hands again, turning the [pc.skinfurScales] redder than before. With his new leverage and grip, he resumes pounding you into the fabric.");

	if (pc.hasCock())
	{
		outputText("\n\nYour [pc.cock] is as hard as you’ve ever felt it and is leaking your precum at an alarming rate, squashed between your body and the bed");
		// This was an area call- it didn't make much sense
		if (pc.biggestCockLength() >= 12) 
		{
			outputText(". Your [cock biggest] has wedged itself beautifully");
			if (pc.biggestTitSize() >= 3) outputText(" between your [pc.chest]");
			else if (pc.biggestTitSize() <= 2) outputText(" against your [pc.chest]");
			outputText(" and you feel yourself inadvertently fucking yourself while Lane fucks you. He’s so talented!");
		}
		else
		{
			outputText(". It’s trapped underneath your gut, getting rubbed raw by your skin and the fabric of the bed, but it just hurts so good! You won’t last much longer like this!");
		}
	}
	if (pc.hasVagina())
	{
		outputText("\n\nY");
		if (pc.hasCock()) outputText("et, despite how good your dick feels, it can’t possibly compare to y");
		outputText("our lucky, spoiled [pc.vagina]");
		if (pc.hasCock()) outputText(". It");
		outputText(" feels absolutely amazing with your master’s cock plowing into it; every time he pulls away leaves you teased and wanting for him again, and you’re fed and satisfied every time he thrusts back home. Your muscles ripple and squeeze in delight as his smooth dick <i>just</i> brushes against all the best spots inside you, making you squirm and slack-jawed as his each thrust claims you individually.");
	}
	if (!pc.hasVagina() && !pc.hasCock()) outputText(" You clench your ass with his every inward thrust, trying to make the sensation last as long as you can, but it’s all a vain effort. Without genitals to release with, you can’t help but feel your release build and build and build, and have nowhere to go at the end of it. It’s torturous and maddening, and you love every second of it. Only Lane can make you feel so wonderfully contradictory!");

	outputText("\n\nHis grip gets tighter, and he drags his claws over your [pc.skinfurScales] painfully as a consequence. You wince a bit, but the sound of his breath coming out faster and faster distracts you. He’s nearly at his peak! You’re eager for his seed and you back against him every time he thrusts, wanting him to shoot his load as deep as he can into your [pc.vagOrAss]. At the same time, you lament that he’s nearly done fucking you – if only you could be like this with your master at all hours of the day! You try to cherish the time you have remaining and the coming climax to it all.");

	outputText("\n\nHe bucks thrice more, then he grunts, and then you feel a magnificent warmth spread inside you, shooting");
	if (pc.hasVagina()) outputText(" deep into your waiting cunny and towards your patient womb");
	else outputText(" far into your large intestine and finding its way deeper, towards your hungry belly. You hope he’ll provide for it next time");
	outputText(". You try to hold back your own orgasm, but Lane wanted to cum inside you, so you wanted him to cum inside you,");
	if (pc.hasVagina() || pc.hasCock()) 
	{
		outputText(" and now that you have what you want, your floodgates burst open.");
		if (pc.hasCock())
		{
			outputText(" [pc.EachCock] sprays your cum all over your stomach");
			if (pc.biggestCockLength() >= 8) outputText("; across your [pc.chest]; onto your chin; and all over his bed, soaking the sheets in the proof of your eagerness for your union.");
			if (pc.hasVagina()) outputText("\n\n");
		}
		else outputText(" ");

		if (pc.hasVagina())
		{
			outputText("A");
			if (pc.hasCock()) outputText("t the same time, a");
			outputText("ll at once, your [pc.vagina] squeezes on Lane’s impressive, godlike dick in sequential waves, coaxing his cum from his sensitive base to his tip and working what you get deeper inside of you. Your [pc.girlcum] sprays out onto him, wetting him at his own crotch and tainting his bedsheets even more. With every pass your cunt makes at milking him, the knowledge that it’s your master’s dick that’s inside you provokes another, smaller orgasm, until your poor genitals exhaust themselves.");
		}
	}
	else
	{
		outputText(" but now that you have what you want... you’re just so <i>close</i> to your release, but no amount of humping the bedsheets or fucking against Lane is going to give you what you need! You bite your tongue hard enough to hurt as you try to frantically recall what an orgasm felt like before you lost your genitals. The bloom of warmth radiating from your crotch; the tension unfolding from your body; the way all your muscles writhe and then relax at the same time... you feel something akin to it as you feel Lane’s warm, heavenly cum seep deeper and deeper into you, but it’s just not enough.");
	}

	outputText("\n\nLane flops back down onto your body and tries to catch his breath. You sigh in ");
	if (!pc.hasCock() && !pc.hasVagina()) outputText("half-");
	outputText("delight; you’ll remember this day forever, and you hope you’ll have many more days to remember in the future. His body feels good against yours: warm, smooth, and tight in all the right places. His breath bats against your ear, and soon his tongue is there instead, licking you affectionately.");

	outputText("\n\n<i>“You’re such a good cumdump,”</i> he says. At first, you sort of object to the phrase, but, being a cumdump is what Lane wants, so you want to be his cumdump. <i>“I think we made a great decision, making you into what you are, don’t you think? This is so much more rewarding for us both.”</i>");

	outputText("\n\nYou nod, whispering your agreement, your thanks, and your praise. You don’t stop praising him and his ‘ability to perform’ for a solid minute and a half – you try your best to encourage him for another round, even as his cock starts flagging inside your [pc.vagOrAss]. Occasionally you feel a twitch from him, which excites you, but soon enough, he goes soft and his cock starts retreating into him once more.");

	outputText("\n\nHe hoists himself off of you and back onto his feet. You turn around, looking to his receding penis, thinking that maybe you could try to fellate him some more... but you only see the tapered tip, and soon it’s swallowed away by his slit. You frown, and he sees it. <i>“Don’t worry, [pc.name]. You’ve done such an excellent job that you’ll be back on it soon enough, I promise.”</i>");

	outputText("\n\nHe turns to one of the dressers on the side of the room, and pulls out a fresh, complete set of the same airy clothes he always wears. <i>“But for now, I’m afraid we both have work to do. I can’t make fucking my living unless I fuck everybody, and I only have one special slut in my life.”</i> He winks at you, and you practically melt on the spot. He laughs light-heartedly. <i>“Put on your clothes, [pc.name], and get back out there. You have some money to make.”</i>");

	outputText("\n\nAnd then he leaves you alone in his room. You lay there for another minute, reflecting on what he just said, about how you were special to him. You smile to yourself, but you know he’s right in that you still have things to do. With some effort, you peel away from his bed and reach for your [pc.armor], scattered across his floor.");

	outputText("\n\nAnother minute or two later, you’re presentable again, and you leave his hut, energized.");

	processTime(60);

	if (pc.hasVagina()) pc.loadInCunt(lane);
	else pc.loadInAss(lane);

	lane.orgasm();
	pc.orgasm();

	if (!pc.hasCock() && !pc.hasVagina()) pc.lust(20);

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

// From the doc:
// 		I may have gotten a little ambitious with this one
// http://i.imgur.com/JedndTn.gif
function fuckedByFemLane():void
{
	clearOutput();

	outputText("Lane roughly shoves you in your chest, knocking you off your feet and onto your ass onto her bed. Before you can rub the sore spot she had hit, she has your [pc.hair] in her hand, gripping you tight enough to pay attention. <i>“We’re going to have some fun,”</i> she says. That makes you shiver. <i>“Before we begin, I need some... encouragement. Show me how enthusiastic you are for me.”</i>");

	outputText("\n\nShe pulls you forward by your hair, until your nose presses hard against the scales of her lower belly. The glowing underneath her thicker skin is less pronounced, but so close, you can practically taste her with her scent. She tilts your head until your lips are pressed against her soft, pliable, sensitive (and more than a little tasty) Daynarian cunt. She’s clearly aroused enough, but she wants you to excite her, so that’s what you want too.");

	outputText("\n\nShe moans out once you pucker your [pc.lips] and slide them over her own. She sways and swings her hips, putting on a bit of a dance for you as you go down on her. You tentatively raise your hands to grope onto her hips, but she swats both of them away with her free hand. <i>“Just your mouth, pet. I want to feel what you’re capable of.”</i> You moan out and acquiesce.");

	outputText("\n\nIt doesn’t take much doing for her to get absolutely soaked, coating your tongue in her lubricant. She’s as horny as she’s probably going to be already – maybe you had left her a little pent up? You’ll be sure to give your mistress more attention to prevent that. Either way, the foreplay probably isn’t what she’s after: if her welcoming pussy isn’t hint enough, then the way she humps against your face and constantly run her hands through your [pc.hair] is telltale enough.");

	outputText("\n\nThe sound of her moaning out pleasurably joins the wet kisses and licks you’re giving her mound. <i>“That’s right, pet,”</i> she says as you work.");
	if (!pc.hasTongueFlag(GLOBAL.FLAG_LONG) && !pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" You dig into her as far as you can, but you know you’re [pc.tongue] isn’t quite long enough to reach her sensitive G-spot deep inside her. You compensate as much as you can by working your lips against her labia, knowing what they do for her too.");
	else if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" You know how much your mistress likes it when you stuff her cunt full of your [pc.tongue], and you’re not going to disappoint her. Your long, slippery muscle slips in with ease and then places itself directly on top of her G-spot. She laughs in delight and thrusts her hips forward, and you don’t stop laying in more and more tongue, packing her full even when your tongue starts layering on top of itself.")
	else if (pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(" Your [pc.tongue] reaches all the way to her cervix with a little bit left to spare. Every pass the tip of your tongue makes over her G-spot, she clenches hard on your head, which, with her claws, hurts quite a bit. But, she wants you to keep going, so you want to keep going, in spite of the pain.");

	outputText("\n\nHer body rocks in a wavy motion, from her ankles all the way to her neck, as she fucks your face some more. She loves what you’re doing with what you’re given, and you love doing it because she loves it. Her body starts to quiver a bit, signaling an impending orgasm, when she quickly shoves you back. <i>“You’re such a good cuntlicker, [pc.name],” she praises. You smile goofily. <i>“As good as your pretty [pc.lips] are, and as much as I could get off on them again and again and again, I want something a bit more substantial from you.”</i>");

	outputText("\n\nShe raises her webbed foot and presses it against your collarbone, where she had shoved you before, and kicks you backward, onto the bed. As soon as your back hits the softness of her quilt, she’s flopped down on top of you, pinning your body down with her own. The soft heaviness of her breasts against your [pc.chest] is the best vice you could have asked for.");

	if (pc.biggestTitSize() <= 5) 
	{
		outputText("\n\nLane gently cups your face with her hands and leans in for a kiss. You reciprocate gladly – and, despite her aggression so far, her kiss is loving, passionate, and caring; neither of you hesitate to swap spit, pressing your tongues together. You melt into her embrace, letting yourself get absorbed into her in more ways than one. Lane’s thigh slips in between your own, rubbing gently at");
		if (pc.hasCock() || pc.hasVagina())
		{
			if (pc.hasCock()) outputText(" [pc.eachCock]");
			else if (pc.hasVagina()) outputText(" [pc.eachVagina]");
			outputText(", stimulating it and making you readier than you thought you were. Lane’s gentle kissing and fervent-yet-considerate rocking against your body has caught you off-guard, and you love it.");
		}
		else
		{
			outputText(" your groin.")
		}
	}
	else
	{
		outputText("\n\nLane’s earlier aggression keeps up as she tops you on her bed. Her hands slap next to your head on either side, making you flinch; before you can right yourself, Lane’s lips are on yours, claiming and dominating you with her mouth. Your mouth is full of her swatting tongue, beating yours down into submission. Her body grinds yours into the bed; her heavy breasts, inferior to yours, squashing your better pair flat, which awkwardly bends her upper back upward but she’s insistent on bettering you. Her thigh worms in between yours, where she practically knees you in the crotch in her passion; it’s <i>definitely</i> stimulating, at least.</i>");
	}

	outputText("\n\nShe breaks away from you, panting, breathless from the intense makeout sassion.");
	if (pc.biggestTitSize() <= 5) outputText(" <i>“You’re such a beautiful creature, [pc.name].”</i> You blush at the undue praise – you didn’t even kiss <i>her,</i> she kissed <i>you</i>. <i>“I love what you’ve become and what our relationship is.”</i> Your heart nearly leaps into your throat, but she keeps avoiding the context you’re after. <i>“You’re such a good toy. And I like to treat my toys well. I think you’re going to enjoy this.”</i>");
	else outputText(" <i>“You hot big-tittied bitch,”</i> she says, her eyes drills and boring into yours. She’s talking dirty, but her tone is serious. <i>“You think you’re better off just because your tits are bigger than mine.”</i> Is she jealous of your [pc.chest]? You open your mouth to respond, but she keeps going. <i>“I’m going to fuck you into the dirt. I can’t promise it’ll be good for you. I want you to look into breast reduction when we’re done here – I can’t have my pets walking around like they’re better than me.”</i>");

	outputText("\n\nShe leans back, pressing her hips down onto yours. Her hands travel up your stomach and onto your [pc.chest],");
	if (pc.biggestTitSize() <= 5) outputText(" kneading and caressing them between her skilled, webbed fingers");
	else outputText(" harshly squeezing onto them between her unforgiving and jealous claws");
	outputText(". She toys with your [pc.nipples] with her index fingers, experimentally flicking them and watching them bounce back. <i>“These are awfully unique, too.”</i> She pinches them between her fingers, tugging them upward. You wince at the rough treatment, and she");
	if (pc.biggestTitSize() <= 5) outputText(" eases up. She hadn’t realized just how sensitive they really were");
	else outputText(" tugs harder. When you sputter in pain, she grins and relaxes your tits, only to tug even harder");
	outputText(". <i>“They must be awfully sensitive. You’ll have to walk me through their intricacies some other time.”</i>");
	if (pc.hasFuckableNipples()) outputText(" She notices that your nipples look awfully familiar, and she sticks a finger into the open tunnel of your left nipple cunt. When you make a distinctly feminine gasp, she realizes right away what they are. <i>“Huh,”</i> she says – and nothing else.");
	if (pc.hasNippleCocks()) outputText(" She grips onto your elongated, masculine nipples. She recognizes their distinct shape right away and knows exactly what she’s doing when she pinches their veins and tubes tightly. <i>“These look fun,”</i> she remarks, <i>“but having sex with your chest would be a little weird, even for an alien. Hell, we might give it a try someday... but not today.”</i>");

	if (pc.hasCock()) 
	{
		outputText("\n\nHer weight bears down on you, and your [pc.cock] is pressed flat, pointed towards your stomach with her body. It’s turned purple with how aroused it is and yet it’s veins are pinched shut by Lane’s devilish hips.");
	}
	else
	{
		outputText("\n\nShe touches her cunt down on your");
		if (pc.hasVagina()) outputText("s");
		else outputText(" empty pelvis, meeting nothing but skin");
		outputText(". The feeling of her warm sex wetly meeting your body so suddenly makes you bite your lip. She keeps her body still, not stimulating you any further.] Your hands grip onto the bedsheets; she had commanded you not to use your hands, and you desperately wait for her to rescind her order. <i>“Would you like me to fuck you, [pc.name]?”</i>");
	}

	outputText("\n\n<i>“Yes!”</i> you bark out loudly.");

	// Cock selection shit.
	var selCock:int = pc.cockThatFits(lane.vaginalCapacity(0));
	var cockTooBig:Boolean = false;

	if (selCock == -1) 
	{
		selCock = pc.biggesetCockIndex();
		cockTooBig = true;
	}

	outputText("\n\n<i>“Ooh, such passion!”</i> She slides her cunny up your body just a little bit");
	if (pc.hasCock()) outputText(", leaving a slimy trail along the shaft of your cock");
	else if (pc.hasVagina()) outputText(", the heat of her vulva radiating just enough to tease your engorged [pc.clit]");
	outputText(". <i>“You don’t waste any time getting to your point. I like that.”</i>");
	if (pc.hasCock())
	{
		if (!cockTooBig) outputText(" She slides her pussy all the way up until she’s perched just above your tip. <i>“Well then, let’s not make you wait any longer, hmm?”</i>");
		else
		{
			outputText(" She leans forward, resting your [pc.cock] between your stomach and hers. She fits it between her heavy, smooth boobs, the tip pointed");
			if (pc.cocks[selCock].cLength() <= 14) outputText(" right towards your face");
			else outputText(" well above your head");
			outputText(". <i>“This isn’t going to fit into me, [pc.name]. You should look into fixing that someday. But that doesn’t mean we can’t still have some fun.”</i>]");
		}
	}

	// PC is male/herm and will fit
	if (!cockTooBig)
	{
		outputText("\n\nShe lifts herself with her knees just enough to fit you inside her, and, with a sharp drop, she engulfs you to your base in one swing. You moan out, feeling your [pc.cock " + selCock + "] inside her familiar tunnel and you submerge yourself in the sensation of her oddly-lined walls sucking on you pleasurably, yanking you deeper and deeper into her. <i>“That’s it,”</i> she says encouragingly. <i>“You’re back where you belong, [pc.name]. Inside your beloved mistress. That’s where you should be.”</i> And you agree!");

		outputText("\n\nFrom her position, she does a minimal amount of thrusting, but she rocks back and forth on top of you, swinging your dick around inside her. Admittedly, it probably gives her more pleasure than it gives you, but you’re nonetheless not going to complain.");
		if (pc.balls > 0) outputText(" )The heat of her ass tickles the tip of your [pc.sack], making them tense up beneath her.");
		outputText(" <i>“Would you like to shoot a hot load inside your mistress, [pc.name]?”</i> She leans back, displaying her abdomen to you. Her bloodflow illuminates her lower torso neatly, practically outlining just where your hot load would be going. <i>“Do you want to feel your cum going into your Daynarian queen?”</i>");

		outputText("\n\nYou grunt your approval and thrust deeper into her, spurred on by her words. She coos out and keeps grinding her snatch onto your pelvis. <i>“That’s it, fuck me good. Prove to me that you love me.”</i> She begins kneading at her titflesh, squishing them together and enhancing her cleavage for you. Her long, thin tongue snakes out and starts licking the salt off the top of her boobs.");

		outputText("\n\nDespite you having to do most of the work for your own pleasure, it’s absolutely paying off. Whether it’s because of the base, primal act of what you’re doing, or because you’re doing it with your mistress, you feel your release building up in your loins – perhaps a little sooner than you had hoped. Your [pc.cock " + selCock + "] pierces into her with every thrust you can manage");
		if (pc.balls > 0) outputText(" and your [pc.balls] jiggle every time you slap into her");
		outputText(". You look at her belly, trying to see if you could spot the outline of yourself through the glowing of Lane’s veins.");
		if (pc.cocks[selCock].volume() >= lane.vaginalCapacity(0) * 0.75) outputText(" To your surprise, you do! Lane’s abdomen bulges out slightly every time you thrust your well-endowed cock into her. She’s moaning like a horny whore, so you know you’re not hurting her with your tool, thank goodness.");
		else outputText(" Unfortunately, you’re not quite endowed enough for something quite that kinky. Maybe she wouldn’t mind if you packed on another inch...");

		outputText("\n\nHer grin evaporates to a more focused expression ad her eyes become heavily lidded. Her hands leave her bouncing breasts and tightly grip onto the quilt you’re lying on, and she uses it to anchor herself to you and keep you from thrusting out of her. You moan pleadingly, but she doesn’t care. You’re forced to fight against her to keep up.");

		outputText("\n\nYour focus is torn between the sensations you have and the sensations you want, and it makes the sex a little wanting on your end. Lane, however, speeds up her breathing, her jaw hanging open. The flashing lights from all over her body begin to pick up their pace, practically turning her body into a strobe light. She starts whimpering like a kitten and the grip her vagina has on your [pc.cock " + selCock + "] tightens, massaging you from your base to your tip, urging out every drop of juice you have.");

		outputText("\n\nBefore you can give her what she wants, she orgasms. She presses hard onto your dick and keeps totally still; you can feel her cunt working overtime to deposit any fluids it gets into her, though you stubbornly don’t give her any. That’s hardly for lack of trying, though");
		if (pc.balls > 0) outputText(": your [pc.balls] begin to ache from the teasing and the frustrating lack of stimulation. She wants your load, and you’d be happy to give it, but she’s not giving you much to work with");
		outputText(".");
		if (pc.hasVagina()) 
		{
			outputText(" To say nothing of your lonely [pc.vagina], clenching at nothing and wishing it got the same attention your mistress’s was getting. You’re soaked");
			if (pc.balls > 0) outputText(" beneath your [pc.sack]");
			outputText(", and you doubt it’s about to get any better.");
		}

		outputText("\n\nShe rocks her hips gently, stimulating herself a little more each time. You can feel your cock getting squeezed and soaked inside her, and you’re <i>so very close</i>, but she’s just not helping you over the edge.");
		if (pc.cocks.length >= 2) outputText(" [pc.eachCock] protest against her abusive vulva, each of them just as hard, but none of them are half as stimulated as the one inside your scaly mistress.");
		outputText(" You just hope she doesn’t –");

		outputText("\n\nShe leans forward again, bringing her eyes close to yours. You wonder if you had done something wrong, and that she wasn’t letting you cum as retribution. She smiles a warm, genuine smile, and that helps ease your tension somewhat. <i>“You still haven’t cum, [pc.name],”</i> she says in a song-song-like voice. <i>“Is something the matter? Could it be... you’re not sexually interested in your mistress anymore?”</i>");

		outputText("\n\nYou shake your head, but you bite your lip. You’re as sexually attracted to Lane as the day you met her, but you can’t just up and say she’s not helping you get off. <i>“Kaithrit got your tongue?”</i> She presses her body onto yours without letting your [pc.cock " + selCock +"] slip free from her cunt. Her vaginal walls still cling to you, but not nearly as aggressively as before. <i>“The Kaithrit can have your tongue, then.");
		if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" As long as it gives it back later – no way am I letting some bitch Kaithrit hog all of that tongue to itself.");
		outputText(" For now, I’ll settle with having your eyes.”</i>");

		outputText("\n\nHer tassels flare open slowly, and your vision begins swimming with the lights of her beating blood mixing with her glassy piercings and swirling tattoos on her thin membranes. Her eyes open wide, very wide, and they begin changing their colors as well. Effortlessly, your body goes numb and relaxes, sinking into her subconscious grip willingly. Your raging hard-on doesn’t flag at all, however.");

		outputText("\n\n<i>“You’d do anything for your mistress, wouldn’t you, [pc.name]?”</i> she says sweetly. You barely have the thought in your head to answer. <i>“You love mistress Lane so very much. Of course you’d do anything for her.”</i> Of course you would. You love Lane, after all. You wouldn’t hesitate to give her anything you could. <i>“Then, would you cum for your mistress? You mistress wants you to cum inside her. Go ahead and let it all out, [pc.name]. Spill your seed into her.”</i>");

		outputText("\n\nThe release that had been evading you all this time suddenly comes rocketing through your cock");
		if (pc.hasVagina()) outputText(" and gushing out your cunt");
		outputText(".");
		if (pc.cumQ() <= 349) outputText(" You sigh as your [pc.cum] finally spills from your aching dick and into Lane’s impatient honeypot. She coos out every time she feels a fresh spurt and gently slides her hips over yours, sucking out all your cum and letting her vagina drink it all, deep inside her. By the time you’re done, there isn’t a drop left from you, and all of it has tucked neatly inside Lane’s body.");
		else if (pc.cumQ() >= 600) outputText(" Lane moans in approval as your cum sinks into her body. The teasing had left you pent up! You cum and you cum inside her, and you hear every splurge of juice shooting into her as well as you can feel it. Lane whispers encouragement as you deposit as many loads as you can, and her thirsty honeypot takes it all in. Her muscles work overtime to make sure nothing escapes, and they succeed, barely.");
		else if (pc.cumQ() >= 2500) outputText("Your first two wads of spunk pack into her easily enough, but you’re shooting so much that she’s totally stuffed by the fourth. You’re not halfway done, though, and you keep blasting your [pc.cum] into her rounded, swollen belly. No matter what her cunt tries to do to contain it, it shoots out around your girth and sprays uselessly onto the quilt beneath you. The juice leaks backward, pooling underneath your body and sticking your [pc.skinfurScales] to the fabric. Even then, it doesn’t stop until you’re resting in sizeable puddle of your own cum.");
		if (pc.balls > 0)
		{
			outputText(" The aching in your [pc.balls] drains with every jet you unleash into your willing and wanting mistress, until the discomfort in them is nothing but a distant memory.");
			if (pc.hasVagina()) outputText(" And, despite the total lack of attention, y");
		}
		else
		{
			if (pc.hasVagina()) outputText(" Y");
		}
		if (pc.hasVagina()) outputText("our [pc.vagina] clenches at nothing and spasms in delight, as though it had been filled by the perfect dick and had been given the royal treatment. You shake your hips as you feel a sort of fiery sensation reaching as far as your lower belly inside you. You’re surprised, but at the same time, your mistress told you to cum, so you came.");
	}
	else if (pc.hasCock() && cockTooBig)
	{
		// PC is male/herm and will not fit
		outputText("\n\nShe rocks her body forwards, and you feel her every smooth, delectable scale slide over the underside of [pc.oneCock]. The bit that’s trapped between your [pc.chest] and her cleavage is surrounded by warm flesh on all sides");
		if (pc.biggestTitSize() >= 3) outputText(", and it’s treated to a double-titfuck, making it the luckiest dick in the universe, according to you");
		outputText(". You feel her wet box tickle along the base of your dick as she draws herself up, and with her every motion, the skin of your penis is dragged along with her.");
		if (pc.canSelfSuck()) outputText(" You could easily lean your head forward and take yourself into your mouth if you wanted, and she could do the same, but maybe your mistress has other plans.");
		else if (pc.biggestCockLength() >= 26) outputText(" Your [pc.cockHead] is well beyond your [pc.lips], making it impossible to give yourself head from this position, but that’s not to say your mouth is <i>useless</i>. Still, you wait for your mistress’s move before you make your own.");

		outputText("\n\nShe gently rocks her body from side to side, grinding your tool between your bodies. Its veins and tubes are pinched between you, making it throb almost painfully; you can see it visibly expand with each heartbeat. Whatever you feel, it’s all exquisite and you hope it goes on forever.");

		outputText("\n\nLane’s hands go to her breasts, pushing them together around your [pc.cock]. You have so much you’d like to touch – yourself, her, her breasts, her sides, her ass");
		if (pc.balls > 0) outputText(", your balls");
		if (pc.hasVagina()) outputText(", your cunt");
		outputText("... but you keep them obediently at your sides. Lane’s eyes lock onto yours, and they narrow seductively as their colors begin to change. <i>“You’re a very good toy, [pc.name],”</i> she tells you, almost lovingly. <i>“I’ll give you a break. You can touch me however you like.”</i>");

		outputText("\n\nYour hands work faster than your mouth, and you’re groping her in different places all over as your tongue fumbles with your thanks. She laughs, and then coos as you poke, prod and massage all the right spots on her scales. You feel and rub along her back, gently trailing your fingers along her ribs, to the small of her back and the swell of her ass. You’re eager, but you try to keep composed and restrained.");

		outputText("\n\n[pc.eachCock] grow");
		if (pc.cocks.length == 1) outputText("s");
		outputText(" harder as you work her.");
		if (pc.cocks.length == 1) outputText(" It");
		else outputText(" One of them");
		outputText(" insistently keeps");
		if (pc.biggestCockLength() <= 14) outputText(" prodding your mistress in the chin");
		else outputText(" smacking your mistress in the cheek");
		outputText(", wanting to rise upright but her body keeps");
		if (pc.cocks.length == 1) outputText(" it");
		else outputText(" them");
		outputText(" cushioned in its soft, warm prison. She seems to enjoy seeing you so hard, and she doesn’t do much for your own pleasure. She does, however, keep grinding her snatch against the underside of your dick, deriving as much pleasure for herself as she can.");
		if (pc.balls > 0) outputText(" Her juices drip and trail down the rest of your length, pooling in the union of your cock and your [pc.sack]. Its ticklish and it makes them draw upward pleasurably.");
		if (pc.hasVagina())
		{
			outputText("\n\nLane keeps her tail tucked in between your legs, and you can feel the heat of her tail radiate just enough to tickle your own quivering feminine sex.");
			if (pc.balls == 0) outputText(" The juices from her own leaking cunt trail from down the rest of your length and onto your [pc.clit], mingling with your own girly secretions.");
			outputText(" You clench your thighs, idly wishing for something to penetrate you. Lane’s tail swishes lazily behind her – she does not grant your unspoken wish.");
		}

		outputText("\n\n<i>“You’re so hard, [pc.name],”</i> she comments. She makes a display of taking a few heavy breaths on you, stimulating you, but the only pleasure you’re getting from her pleasuring herself on you. <i>“Won’t you do something about it?”</i> You’re unsure how to reply, other than to keep squeezing her ass. You look at her");
		if (pc.biggestCockLength() >= 15) outputText(" around your long dick");
		outputText(" inquisitively – once your eyes meet hers, you feel a sense of calmness wash over you while the lights of her body tunnel your vision. <i>“You have needs too, [pc.name]. Living with a penis this... prodigious must be trying. I can’t imagine there are a lot of cunts out there that can take it.”</i> She pauses, then grins a sinister, toothy grin. <i>“Maybe not consensually, anyway.”</i>");

		outputText("\n\nAs you watch and listen, her body keeps moving, rubbing at all your best spots on your massive dick. It’s taken until now for a bead of your [pc.cum] to travel up your shaft and hang from your [pc.cockHead],");
		if (pc.biggestCockLength() <= 14) outputText(" splashing down onto your chin");
		else outputText(" dripping down somewhere above you and onto her quilt");
		outputText(". <i>“Pleasure yourself, [pc.name],”</i> she says, not-too-subtly. <i>“Your mistress wants to see it. Use your mouth on yourself. You must have gotten a lot of practice by now. You can be honest with your mistress.”</i>");

		outputText("\n\nYou decide to pleasure yourself, with or without Lane’s go-ahead or initiative. You crane your neck upward,");
		if (pc.biggestCockLength() <= 14) 
		{
			outputText(" and slip your [pc.cockHead] past your lips. Your own taste, somewhat familiar, coats your tastebuds in an instant, along with your leaking pre. The pleasure you get from finally having your glans stimulated with tongue as gentle, caring, and familiar as yours, inflates your vas deferens with more of your impatient precum.");
			if (pc.cumQ() >= 1000) outputText(" You’re very aware that the few drops that land in your mouth are merely the drizzle before the hurricane.");
		}
		else
		{
			outputText(" and slide your [pc.tongue] out to coat and pleasure the skin of your shaft. You feel the rigid, thick muscle under the thin layer of skin beat and bloat with your heart, and finally feeling something wet and warm pleasure your tool makes it lurch with excitement. You can see your vas deferens, nearly hidden against Lane’s body, inflate with your impatient precum, and you can hear it splurt and drip onto her bed above you.");
			if (pc.cumQ() >= 1000) outputText(" You really hope Lane isn’t going to mind the mess you make when you unload. The size of your cock isn’t the only thing ‘prodigious’ about you.");
		}

		outputText("\n\nTo your relief, you hear your mistress giggle above you. She drags her body in broader strokes against you, and her breathing starts getting a little shallower as she watches you. <i>“That’s it,”</i> she says, cheering you on softly. <i>“Let me see you work your own cock, you fucking size-queen. Let’s see how good you are with your own equipment.”</i> She rolls her hips forward, then languidly slides them back down, forcefully pushing her crotch against your thick tube. She winces and moans out <i>“yeeeeeessssss”</i> as she goes, her eyes watching your mouth’s every movement.");

		outputText("\n\nYou keep up your licking and sucking, encouraged by your mistress’s words.");
		if (pc.biggestCockLength() <= 14) outputText(" You lean forward further, stuffing as much dick into your mouth as you can. Giving yourself a blowjob is a unique, wonderful feeling combing the best of having your dick sucked and the sexy, slutty feeling of having a warm, fat dick in your mouth. It’s exacerbated, perhaps, by your mistress lying atop you and enhancing your experience.");
		else
		{
			outputText(" You cover as much of your shaft as you can with your [pc.tongue]");
			if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE) || pc.hasTongueFlag(GLOBAL.FLAG_LONG)) outputText(", which isn’t a daunting task – you can reach all the way to your base and all the way to your tip in just a pass");
			outputText(". You pucker your [pc.lips] and kiss the fat, hard bit of muscle directly in front of you repeatedly, giving yourself hickeys on your straining tool. Lane seems to love watching you pleasure yourself, and you love that she’s loving it, making every lick, kiss, and rub a new delight to all five of your senses in new and exciting ways.");
		}

		outputText("\n\n<i>“You’re a good pet,”</i> Lane says through staggered breaths. Her masturbating herself against your cock grows frantic, and her scaly boobs hang loose and low, surrounding your [pc.cock] rather than smothering it. <i>“You do exactly as you’re told”</i> With that, her body tenses and she takes a long, deep breath through her clenched teeth. You feel the same wetness from before begin to flood down the shaft of your dick and pool at your groin");
		if (pc.balls > 0) outputText(", glazing over each of your [pc.balls] and dripping off them towards the quilt beneath you");
		if (pc.hasVagina() && pc.balls == 0) outputText(", dripping down across your [pc.vagina], soaking your [pc.clit] and drenching your thighs in more than your own femcum");
		outputText(". <i>“Cum with me, [pc.name],”</i> she demands. She’s barely able to form the words. <i>“Let me see what that cock is capable of!”</i>");

		outputText("\n\nYou don’t hesitate to ‘do as your told,’ and, almost before you’re even ready, you feel your [pc.cum] surging through you, burning a trail up your massive shaft.");
		if (pc.cumQ() <= 349)
		{
			if (pc.biggestCockLength() <= 14)
			{
				outputText(" The taste of your bloated [pc.cockHead] is accompanied by your personal cream, immediately coating your tongue and puffing out your cheeks. Without hesitation, you swallow – you hope your mistress will get an even bigger kick out of it. The load in your mouth is replaced with two more, neither of them as large as the first. You make a show of swishing it around in your mouth for her before you gulp it down as well.");
			}
			else 
			{
				outputText(" Your cum shoots from your [pc.cockHead], bursting out in a few ropes over your head and onto Lane’s bed above you. If she’s disappointed at the mess you’re making, she’s not showing it. Your cock tenses between you for a moment, squeezing out your load – you spurt three times, the latter two hardly the size of the first combined. Your teeth clench as you try to keep from thrashing as you ride out the rest of your orgasm.");
			}
		}
		else if (pc.cumQ() <= 1000)
		{
			if (pc.biggestCockLength() <= 14)
			{
				outputText(" Your [pc.cockHead] puffs out, pushing against your tongue and your palate, and then erupts your load directly down your throat. You barely have the time to register the orgasm and your very sudden meal before another shot replaces the first, just as voluminous as before. You try to swallow as much as you can – you don’t want to make a mess, and judging from the look on your mistress’s face, she’s getting a real thrill off seeing you struggle with it. Eventually, you fail, and your [pc.cum] leaks from your [pc.lips] in thick rivers before your load finally comes to an end.");
			}
			else
			{
				outputText(" You feel your [pc.cock] bulge and expand between you as your [pc.cum] gushes from your loins to your tip. The can hear the squelching sound of your cream spraying from your tip, landing in bulges and ropes on the fabric of her quilt. You can barely see straight through your orgasm, but you have the consciousness to hope that your mistress doesn’t mind the mess you’re making. From the look on her face as she fucks against you, urging out more of your cream with every rock of her hips, you doubt she does.");
			}
		}
		else
		{
			if (pc.biggestCockLength() <= 14)
			{
				outputText(" Your [pc.cockHead] stresses almost painfully in your mouth, and then you’re absolutely assaulted by your own massive load of [pc.cum]. The wad that forces itself down your throat is nothing compared to the amount pooling in your cheeks, spraying out your [pc.lips], and the little hot, stinging bit that leaks out of your nose. You can barely taste it, with how much your dick is pumping into you. With your mistress pinning you down, you can’t move your cock anywhere but your face; you’d feel some discomfort from your bloating stomach and your sticky cumbath if you weren’t experiencing a full-body orgasm as the same time. Your mistress, for her part, roils her hips against your straining shaft with each pulse of cum, clearly loving watching you struggle with yourself.");
			}
			else
			{
				outputText(" Your shaft balloons sequentially with each wad of your thick [pc.cum]. When the first rockets from your [pc.cockHead] and onto your mistress’s bed above your head, you feel the second and the third surge from your groin and up your prick and burst from your straining dick with an audible, squishy pop. You can feel each surge press against your belly, and from the look on your mistress’s face, she can, too, and she loves it. But she keeps looking up at where your cum is landing; you can’t see the growing pool, but, even as she bites her lip and rides out another orgasm, you can tell she’s not looking forward to the future.");
			}
		}
	}
	else
	{
		// PC is female/sexless
		outputText("\n\nShe leans back and, with an exaggerated motion, draws her pussy forward and over");
		if (pc.hasVagina()) outputText(" yours, kissing your vulva with hers");
		else outputText(" across the blank slate of flesh that is your crotch");
		outputText(". She moans out and grips onto");
		if (pc.isBiped()) outputText(" your ankles; her claws scratch against your skin and her grip, in her passion, is tight enough to hurt a little.");
		else outputText(" the quilt; she grips onto it tight enough to rip some holes into the fabric in her passion.");

		outputText("\n\nYou both gasp out as she grinds on top of you.");
		if (!pc.hasVagina()) outputText(" You really wish you had some genitals to truly emphasize the sensations, but you’ll have to do with pleasuring your mistress for now.");
		outputText(" The heat of her body and the smoothness of her scales make the actions so much better for you. You can’t focus your eyes on any one thing, but Lane has hers focused solidly on you as she grinds her body onto yours.");

		if (pc.biggestTitSize() <= 5)
		{
			outputText("\n\nHer rocking is slow and methodical: she moves as much as she can in one swing before starting on the next, drawing as much stimulation for you both as possible. You can feel her juices drip onto you,");
			if (pc.hasVagina()) outputText(" mixing with your own");
			else outputText(" soaking your crotch and lathering it across your skin");
			outputText(". She takes deep, heavy breaths through her nose often, and soon a sly grin crosses her face.");
		}
		else
		{
			outputText("\n\nHer thrusting against you is slow, but it’s hard and drawn out every time. She presses down on you as hard as she can: she grunts out in pleasure as she stimulates her labia on your");
			if (pc.hasVagina()) outputText(" own. It sort of hurts, the way the friction drags and pulls on your poor [pc.vagina], but your mistress is having the time of her life above you");
			else outputText(" body. The way the friction between you pulls at your skin causes some irritation, but it’s nothing compared to knowing you’re doing right by Lane");
			outputText(". Her mouth opens into a large, domineering, toothy grin.");
		}

		outputText("\n\n<i>“You like that?”</i> Her words are punctuated with her using her body to claim yours. <i>“You like having your mistress own you with her pussy? You like being underneath her?”</i> You moan out, trying to use your words but they fall apart on your lips. <i>“Hmm... maybe I should invest in some Throbb. Give myself a nice, thick Daynarian dick. Then I could fuck you properly.");
		if (!pc.hasVagina()) outputText(" As properly as we can, anyway. Maybe I’ll get you some Tittyblossom while I’m at it. ");
		outputText(" Would you like that? Would you like to feel mistress Lane deep inside you, fucking you, and making you cum with her cock?</i>");

		outputText("\n\nYou still can’t manage the words, but the idea of her truly claiming you");
		if (pc.hasVagina() && pc.vaginalVirgin) outputText(" and taking the one thing you can still truly give");
		outputText(" makes you even more excited");
		if (!pc.hasVagina()) outputText(", which makes things more frustrating");
		outputText(". You lift your [pc.hips] in time with her rocking against you, wanting to feel more. She doesn’t alter her rhythm at all, but from the way she starts heaving, the idea’s a little enticing to her too.");

		outputText("\n\nAlready, Lane’s reaching her limit.");
		if (pc.isBiped()) outputText(" Her grip on your ankles tightens and she pulls harder on your body against you.");
		outputText(" Her blood is glowing and flashing at faster and faster rates, matching the way she can’t seem to catch her breath as she bucks and writhes. Her teeth clench, and she tenses.");

		outputText("\n\nYou feel a gush of feminine fluids drench you suddenly.");
		if (pc.hasVagina()) outputText(" Knowing that your mistress is coming, and that you’ve done your part, sets off your own orgasm, and you cum with her. You feel a pleasant burn reach from your [pc.vagina] into your spine and all over your body; your [pc.girlcum] jets from you, splashing with Lane’s, soaking both of you at the crotch. The combined smells and musks makes your head spin even harder, and with the way her lights flash, you’re seeing stars.");
		else
		{
			outputText(" Seeing your mistress coming reminds you of how that used to feel, and how you wish you hadn’t ever lost your genitals, but as it is, you have no way of joining Lane in her bliss. The heat and the irritation on your pelvis make your lusts burn hotter; you try to lift your hips and clench your [pc.ass] in an effort to get <i>something</i>, but there’s nothing you can do!");

			outputText("\n\nLane takes her time coming down from her orgasmic high. Her body twitches occasionally; her grip on");
			if (pc.isBiped()) outputText(" your ankles had turned vice-like in her throes, but they’re starting to ease up now that she’s calming down");
			else outputText(" her bed has turned it disheveled and uprooted the quilt from the edges of the bed. Her claws had ripped long holes in the fabric; you hope she has a spare handy");
			outputText(". Her eyes re-focus, and she looks down on you: face-scrunched, hips thrusting, breathing heavily, and searching for an orgasm that just doesn’t exist.");

			outputText("\n\n<i>“Poor [pc.name],”</i> she says earnestly. She hiccups happily every time you stimulate her labia. <i>“You’re so horny, but you’ve got nothing to release with. That must be a special kind of hell.”</i> She leans forward. Her heavy breasts land and rest on your [pc.chest], and she pins you still against her bed.");
			if (pc.biggestTitSize() <= 5) outputText(" <i>“It’s okay. Your mistress isn’t cruel. She can help.</i>");
			else outputText(" <i>“I could just leave you like this... but I can’t be that mean. I couldn’t imagine a life without being able to cum.”</i>");

			outputText("\n\nShe gently grips onto your face, forcing you to look into her eyes. They immediately start changing color, and her tassels flare open suddenly. In a flash, you’re seeing a myriad of different colors and patterns, and the familiar sensation of relaxing in Lane’s all-encompassing control soothes you.");

			outputText("\n\n<i>“You’d do anything to make your mistress happy, wouldn’t you, [pc.name]?”</i> You nod dumbly. <i>“You can’t orgasm. It’s okay. That must be so hard for you.”</i> Your lust rises and becomes almost unbearable – if Lane weren’t here for you, you’re sure you would lose your mind any second now. <i>“Your mistress wants you to calm down. Forget about your lusts for now. You don’t need to cum right now.”</i> At first, you don’t know what she’s saying, but right away, you feel a distinct different in your loins as your body starts to cool. <i>“That’s right. Your aches and needs feel soothed. Your mistress has achieved orgasm, and that’s pleasure enough for you, [pc.name].”</i>");

			outputText("\n\nShe repeats and enforces her words for another minute. Your [pc.hips] have stopped their humping against her, and the frustrations you’ve been feeling seem to evaporate into nothing. The aching your body had to overcome its ‘disability’ begins to vanish, until there’s finally nothing left, and you feel absolutely content.]");
		}
	}

	// Merge all scenes here
	outputText("\n\nYou pant beneath your mistress as she finishes up having her way with you. Laboriously, she climbs off of you, peeling away from the sweat clinging your bodies together.");
	if (pc.hasCock() && !cockTooBig) outputText(" Your [pc.cock] slips free from her cunt as she stands; it’s still hard as a rock and stands tall in the air, but it’s softening quickly enough.");
	outputText(" She wobbles as she stands, adjusting her tail again and again to help her keep balance after all the wild sex.");

	outputText("\n\n<i>“You’re an amazing toy, [pc.name],”</i> she slurs. <i>“That’ll do me for a little while yet. I think we’ve made a great decision to make you into my plaything, don’t you? I think the future’s only going to be brighter between us.”</i> You nod your agreement without getting up from your spot. Your muscles are too exhausted to lift you.");
	if (!pc.hasVagina() && !pc.hasCock()) outputText(" You feel completely, utterly satisfied, something you haven’t felt in a long, long time. You could swear you feel exactly as if you had recently climaxed, but you don’t recall cumming – which would be a challenge, considering your lack of equipment.");

	outputText("\n\nYou hear Lane shuffle around the foot of the bed, and then to one of her dressers on the side of the room. She still can’t stand straight, but she’s walking with some determination. You turn your head, and you get an eyeful of her ass, occasionally obscured by her swishing tail. She bends at the waist, giving you a clear view of her genital slit, already swallowing her happy, satisfied cunny away from your view. Despite your exhaustion, you wonder if you can’t entice her for another round.");

	outputText("\n\nShe turns back to you");
	if (pc.hasCock()) outputText(" and sees your flagging erection, slowly fighting to stay erect and go another time");
	else if (pc.hasVagina()) outputText(" and sees you idly playing with your [pc.vagina], gently rubbing at your [pc.clit] as you stare at her");
	outputText(". She knows the look on your face. <i>“Already? Do you love your mistress just that much?”</i> You don’t reply, and you’re too unfocused at the moment to realize what messages you’re sending her. <i>“Don’t worry, pet. We have all the time in the world to go as many times as we like.”</i>");

	outputText("\n\nShe turns back to her dresser and pulls out an exact set of her light, thin, airy clothing, fresh and clean as could be. <i>“But,”</i> she says as she casually dresses herself - taking her time with her shirt, for your benefit - <i>“I’m afraid sucking and fucking all day doesn’t pay for my bills. We both have some work to do, [pc.name]. Take your time getting dressed, but just remember that you have some money to make.”</i>");

	outputText("\n\nOnce she slips on her pants, she leaves the room without another word, leaving you to stew a bit in your afterglow. She’s right, though – you’re not going to get anything done just lying there. You’re sure your mistress would appreciate you getting a move on.");

	outputText("\n\nLazily, you slip off her bed and collect your clothing. When you’re dressed and halfway presentable again, you leave her room. You see Lane sitting at her desk, nonchalantly flipping through some tabs on her codex. She doesn’t even spare you a look as you pass her by and step out into the desert planet Venar once more.");
	
	processTime(60);

	if (pc.hasCock() && !cockTooBig) lane.loadInCunt(pc);
	if (pc.hasCock() && cockTooBig) pc.loadInMouth(pc);

	pc.orgasm();
	lane.orgasm();

	// Reduce lust to 0
	// Place PC one square outside of Lane’s Plane
	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function laneFullyHypnotisesYouDumbshit();void
{
	flags["LANE_FULLY_HYPNOTISED"] = 1;
	clearOutput();
	
	// Lane fully hypnotizes the PC. Tier 5 aggression, basically. Start here after the first [=Next=] button once the PC pays for a normal hypnosis.

	outputText("Lane spreads {his} legs apart, already making {him}self comfortable before your hypnotized, immobile, impressionable, compliant self... {he} doesn’t say anything as {he} stares at you, rubbing {him}self through the fabric of {his} pants and undergarment, arousing {him}self as {he} imagines the oh-so-delectable things {he} could make {his} absolute favorite customer do...");

	outputText("\n\n{He} frowns to himself, and {his} eyes wander for a moment. {He} begins to fight with {him}self silently, trying to decide if {he}’s gone too far already and if {he} should just give you what it is you paid for... but that’s a short lived battle, and {his} eyes lock on yours once more, steeled with dangerous, predatory resolve." + lane.mf(" The nub of his penis slowly but determinately erecting underneath his clothing is plainly visible, and he paws at it with one hand.", "Moisture begins to dampen the center of her undergarment as she palms at herself idly, and her musk joins the incense of the candles in your nose."));

	outputText("\n\n<i>“[pc.name]”,</i> {he} says, but of course, you don’t answer. <i>“You can no longer stand it. Lane is everything you ever wanted in life. You can’t bear the thought of leaving {his} hut today without fucking {him}. " + lane.mf("You want his dick in your mouth; the taste of his cock on your tongue and the feel of his cum in your throat is the greatest pleasure in your life. You want his dick in your ass; knowing that Lane is inside you, owning you, and dominating you, will forever be your wildest, most desirable indulgence.", "You want her cunt in your mouth; her cum is finer than any wine, sweeter than any honey, and smoother than any malt. You want her to dominate you; being underneath her as she asserts herself is where you belong, and nothing is more relieving, more thrilling, or more pleasurable than being where you belong.") + " You will surrender yourself, mentally, physically, and emotionally to Lane, and you will not object to whatever {he} desires. {His} wishes, {his} kinks, and {his} desires are now yours.”</i>");

	outputText("\n\n{He} spends far longer reinforcing {his} new commands on you than {he} ever has on anything before, and you absorb every word and every command {he} tells you. You’re in the room for the better part of an hour as {he} reprograms you into being {his} new sex slave, and you, helpless and enraptured as you are, are defenseless against {his} unrelenting onslaught of suggestions.");

	outputText("\n\nSuddenly, your eyes, and your mind, clear completely. You blink, the familiar dizziness and ringing ears welcoming you back to the conscious world. You shake your head, trying to re-familiarize yourself with the waking world, and when you open your eyes, the first thing you see is Lane, sitting across from you, {his} elbows on {his} deck and {his} chin in {his} hands. <i>“How do you feel?”</i> {he} asks you innocently.");

	outputText("\n\nYour eyes focus solely on {him}, and... something comes over you. Your breathing quickens, your heart races, and your head becomes light, likely from all the blood rushing from it to your loins. A sort of dissatisfaction washes over you, and you crave something, something from Lane. You see hundreds of images in your mind in quick succession – some of them are panicky, trying to get you to get up and run from {him}, but everything else sees you on your knees, pleasuring Lane with your mouth, or on a bed," + lane.mf(" legs in the air", " on your back") + " as {he} pounds you – fucks you - <i>claims</i> you and <i>owns</i> you for {him}self. Your imagination soars blissfully with the idea of giving yourself to {him} and {his} pleasure, of letting {him} control your wants and your actions and your life.");
	if (pc.hasCock()) outputText(" [pc.EachCock] is raging hard in your pants, already nearly at full mast, more than eager for the pleasures it knows Lane would bestow upon you for your obedience.");
	else if (pc.vagina()) outputText(" [pc.EachVagina] throbs, oozing your girlcum into the fabric of your [pc.armor] and further influencing your mind into following through with your perverted fantasies.");

	outputText("\n\nYour body makes your decision before your mind does, and you leap from the chair, practically vaulting over the open end of Lane’s desk to place yourself at {his} feet. {He} turns in {his} chair, smiling wickedly, and opens {his} legs, letting you nestle yourself between them. You begin to rub your [pc.face] against the fabric of {his} pants, your cheeks against {his} thighs and your nose ever so close to {his} crotch – {his} musk wafts from {him}, filling your nose and your mind with more perverted images. " + lane.mf(" His bulge is very well defined and pronounced, and thoughts of his wonderful, delicious cock filling your mouth make you salivate.", " The scent of her moist, hungry cunt is overpowering, and you see her juices beginning to seep through her fabrics. Thoughts of her using it to dominate you make you ache for her even more."));

	outputText("\n\n<i>“And just what are you doing, [pc.name]?”</i> {he} asks you, somewhat condescendingly, though {he} makes no movement to stop you from your nuzzling and massaging. Your [pc.tongue] snakes from your [pc.lips] and flicks at {his} clothed crotch, but {he} swats at your head, not enough to hurt, but enough to get the message that you may not act unless {he} allows you.");

	outputText("\n\n<i>“Please!”</i> you beg {him} shamelessly, lowering your head. <i>“I want you, Lane! I... I won’t leave until you fuck me! I’ll do anything; I’ll do whatever you ask! Just... just let me have you!”</i>");

	outputText("\n\n<i>“Anything?”</i> {he} asks you, and you confirm three times. Lane is <i>so close</i>, but {he} won’t let you close that last little distance that’ll make you {his}. {He}’s very clearly aroused and enjoying your begging and pleading, but {he} just won’t let you! <i>“I want you to tell me that you’re mine forever, [pc.name].”</i>");

	outputText("\n\n<i>“I’m yours! I’m yours until the day I die!”</i>");

	outputText("\n\n{He} hums to himself. <i>“Starting tomorrow, I want you to wire me five hundred credits each and every day that you are mine, [pc.name].”</i> You look up at {him}, surprised, mouth agape – your mind is racing with ways you could possibly afford that. <i>“That should be chump change for the heir");
	if (pc.mf("m", "f") == "f") outputText("ess");
	outputText(" of Steele Tech, I think.”</i>");

	outputText("\n\nFrantic, you begin to explain that you haven’t actually inherited the business from your father yet. {He} listens to you ramble, but when the message is made clear, {he} tells you to stop. <i>“If you can’t afford it, just wire me what you have. I’ll trust you. You wouldn’t ever lie to me, would you, [pc.name]?”</i> You shake your head, vehemently telling {him} that you would never dream of it.");

	outputText("\n\n<i>“There’s one last thing. One last thing, and then I’ll give you,”</i> {he} says, using {his} hands to frame {his} crotch, <i>“what you want.”</i> You don’t dare move or speak, listening rapturously for whatever else {he} has in mind for you. <i>“From now on, I want you to call me your " + lane.mf("master", "mistress") + ". You will no longer address me as Lane, or as " + lane.mf("mister", "missus") + " anything. I own you now, [pc.name], and I demand respect from my pets.”</i>");

	outputText("\n\nYou beg and plead with your " + lane.mf("master", "mistress") + ", asking them to give you what you need, to douse the fire in your loins, to physically claim you as {his} and {his} alone for the rest of your life. Wordlessly, {he} grabs you by the collar of your [pc.armor], lifting you up. You feel some anxiety, pulled from {him} as roughly as you are, but your fear turns to curiosity as {he} leads you behind the curtain splitting the room in half once more. Instead of turning towards the hypnosis room, {he} turns to {his} left, and shows you through the second door.");

	outputText("\n\nIt leads to what looks to be Lane’s bedroom. It’s a modest place, all told: there are two dressers leaning against both the left and right walls, and a small nightstand sitting in the corner with a large lamp on top of it. Pressed against the far wall is a queen-sized bed with a thick, fluffy, plain white quilt atop of it. Rather than windows on the walls, there’s a large skylight above the bed with a thick pane of glass set in it. Everything is kept quite clean and tidy, but the room is very plain and without much personality.");

	outputText("\n\nLane turns and, with {his} other hand, grasps you by the [pc.hips] and roughly spins you towards his bed, tossing you onto it. You land on your back, and just as you regain your bearings, you see Lane standing at your feet, effortlessly ripping off {his} airy shirt and tearing through {his} pants. Using {his} claws, {he} rips through the tougher fabric of {his} undergarment, " + lane.mf(" and you finally lay eyes on the twenty-four centimeter long Daynarian cock. It’s only six centimeters thick, but, before your very eyes, with every throb, it grows thicker and thicker. He has no testicles, which you sort of expected, but makes you sigh disappointedly either way – they would have been fun to play with.", " and you finally see the Daynarian treasure you’ve waited your whole life for. Her cunt is the most erotic thing you’ve ever seen: it’s surrounded by a tough genital slit that, with every throb of her heart, opens wider to reveal Lane’s concave labia, teasing themselves open for you. She does not have a clitoris, which you didn’t expect."));

	outputText("\n\nStill lying prostrate on {his} bed, you begin to strip off your own clothing, until you’re as naked as {he} is. Lane looks down at you, " + lane.mf(" both hands stroking his engorging cock,", " one hand teasing her sopping wet cunt while her other plays with her nipple-less boob,") + " smirking at you, seeing how ready and willing and wanting you are for {him} on {his} bed.");

	outputText("\n\n{He} doesn’t waste any more time.");

	//[=Next=]
	clearMenu();
	addButton(0, "Next", )

}

// The doc had a comment that claimed this scene was for the following configuration:
// 		Lane is Male, PC is Male or Genderless.
// However, the scene made a reference to the PCs cervix. So, yeah.
function firstTimeLaneMPCM():void
{
	clearOutput();

	outputText("Lane crawls forward, paying no heed to");
	if (pc.hasCock()) outputText(" [pc.eachCock]");
	else outputText(" your body or needs");
	outputText(" as he slithers forward, his body rubbing against yours in a sensual yet predatory way. The feel of his glowing skin against yours is electric, and you shut your eyes in pleasure. You reach up with your hands to stroke along his skin. <i>“Hands to yourself,”</i> he commands you, and you comply, whimpering like a spoiled child without his candy.");

	outputText("\n\nLane’s hands clamp down hard on your skull, and you’re nudged hard in the [pc.face] as Lane’s unique, undeniable scent assails your nostrils. You open your eyes to see yourself eye level with his quickly engorging and expanding cock; its base rubs against your upper lips while its tip reaches up between your eyes and out of your vision, and it just continues to grow. The skin of his dick is very thick; you can’t see any vein or blemish along its smooth surface. The skin is a dull, fleshy pink, but its hue changes slightly from pinkish to a more greyish on Lane’s excited heartbeats.");

	outputText("\n\nLane humps himself against your face, rutting his thin (but thickening) dick all the way from his base to your bottom [pc.lip] to the bridge of your nose, and from his tip to the bridge of your nose to well into your [pc.hair]. He rocks your head for you with his strong grip on your skull, making sure that he’s always in control. You whine, snaking your tongue out to press it against his dick as it slides across your face. He sighs in relaxation when your wandering tongue presses over his shaft, and he grunts in jubilation when you lick along his base, rutting faster against you.");

	outputText("\n\nBefore your very eyes, his shaft continues to bloat and expand. It doesn’t get much longer, but when he first started, it was only as thick as your finger; with every hump he makes against your face, marking his scent on you, its girth keeps getting wider and wider, and you don’t see it stopping anytime soon.");

	outputText("\n\nLane grips onto his smooth Daynarian dick by its base, and he whacks it against your face several times; the tip slaps into the curve of your cheekbones, splashing a bit of his clear precum over your vision and into your [pc.hair]. He teases by beating his meat against your face, delighting your vision, warming your face and enticing your waiting, thirsty mouth. <i>“Open your mouth,”</i> he commands you, and you’re all too happy to, knowing what’s coming next, but the simple act of doing what Lane commands you to gives you such an electric thrill as well.");

	outputText("\n\nHe shifts back and traces along your open [pc.lips]. You can feel it leave behind a trail of his juices, wetting your lips for you, until he’s made a full circle. He descends, slowly at first, running his length across [pc.tongue], and you moan at finally, <i>finally,</i> getting what you’ve wanted since you first saw him. Your lips close without his consent, but from the way he continues to sink into you and the way he moans when the flaps of his genital slit meet your face, he doesn’t mind. You suckle on him, cherishing the juices he gives you and swallowing them thankfully; you’re eager to get more.");

	outputText("\n\nHis length delights [pc.eachTongue] and his taste sets your mouth positively aflame. He pulls back, driving his tool over as much of your mouth as you can, renewing your taste. He pauses, enjoying but unused to his position over you. He thrusts again, and again, and soon, once he’s comfortable with his domineering position, he’s outright fucking your face, and not only do you let him, you love it. Unable to touch him – much as you want to grope and squeeze at his ass, and stroke at his tail, and grip his ankles for support – your hands instead go to your");
	if (pc.cocks.length == 1)
	{
		outputText(" [pc.cock], stroking along it in time with Lane’s thrusting");
		if (pc.balls > 0) outputText(" and fondling your [pc.sack] in tandem");
		outputText(".");
	}
	else if (pc.cocks.length > 1)
	{
		outputText(" [pc.eachCock], pumping them alternately with Lane’s hungry thrusting.");
		if (pc.cocks.length >= 3) outputText(" Unfortunately, you only have two hands; the rest of you bounces along with the ride, hard as a rock and leaking your fluids in the vain hope for some attention that never comes.");
	}
	else outputText(" [pc.ass], kneading and squeezing the cheeks in a desperate attempt to pleasure yourself. It helps, but only somewhat.");

	outputText("\n\nLane is a little more forceful than you’d have expected: he hammers roughly into your face, slamming and bruising your poor [pc.lips] with his crotch. His hands toy roughly with your [pc.hair], which hurts, but it’s a sexy kind of hurt, because Lane is doing it. His tip drains itself directly into your throat, and it touches and tickles your uvula occasionally, threatening to make you heave. You’re sure that he’s aware of that, though, and whatever he wants, you want. You relax and continue to pleasure yourself");
	if (!pc.hasCock()) outputText(" as best as you can");
	outputText(" as he uses your mouth and your eyes are treated to as spectacular a light show as you could have asked for.");

	outputText("\n\nHis dick has been inflating this whole time, to your delight; what was the width of a pair of fingers is now wide enough to fill every part of your mouth with his delicious cock. Sucking on him and pressing your lips together against him just <i>feels</i> good, and your taste buds delight in the constant, copious cream he’s spraying into you.");

	outputText("\n\nOne particularly rough thrust makes you croak just a little, though, and he looks down at you. <i>“I must not have told you,”</i> he grunts out. He doesn’t slow his thrusting down at all, but he’s beginning to pant a little. <i>“Daynarian cocks aren’t like your usual cocks. We’re not satisfied with just the tip.”</i> He thrusts again and keeps himself buried in your mouth, and he rubs his crotch, pressed firmly against your face, back and forth across your skin. <i>“All our nerve endings are in the base.”</i> Grind; scrape. <i>“It’s so we want our dick as deep as we can get, to better plant our seed.”</i>");

	outputText("\n\nSuddenly, Lane is overcome with inspiration. He pulls his cock from your throat, much to your trepidation. You look up at it with a wanting gaze; dripping with your spit and leaking its own fluid, it looks so much longer and thicker than when it first went back in, and your imagination races with how much bigger it would get if he just put it back in your mouth where it belonged. <i>“Turn over,”</i> he tells you; your eyes light up and your [pc.ass] clenches together in glee.");

	outputText("\n\nYou do as he commands quickly and easily, and you raise your lower end up at him, hoping to feel your master inside you, claiming you by claiming your most private, personal spot. He laughs at your enthusiasm, but he obviously shares it: he swats down on your [pc.hips] hard, and he presses his own forward, dragging his hot, hard dick up through the cleavage of your ass");
	if (pc.balls > 0) outputText(". As he presses forward, the base of his cock just kisses the bottom of your [pc.balls], causing them to lurch and tense, nearly ready to shoot their load, if only they had just a little more stimulation...");
	outputText(". You brace your upper body with your arms, and though you regret not being able to masturbate, you’re sure the pleasure your master will give you will be more than enough to bring you over.");

	outputText("\n\nHis cock teases and ply’s against your butthole, digging in but feinting out at the last second, just before penetration. Your clench your teeth together as you wait for him to finally do what you were <i>born</i> for and make you his, but he just doesn’t do it. <i>“Please, master Lane!”</i> you gasp out pitifully, backing your ass onto him and squishing his cock between your cheeks, hoping the extra incentive will entice him.");

	outputText("\n\nNot much for conversation, he obliges wordlessly and drives his tip into your asshole. Your wait to exhale is over, and you sigh as you’re split open the way only he can. You feel such a sense of <i>rightness</i> as the thick, wet skin of his special Daynarian prick pushes past your sphincter: the deeper he goes, the weaker you feel – no, that’s not right. The more you give to Lane, the stronger he becomes, and you feel a very divine, and a little perverse, pleasure at helping Lane assert himself over you. ");
	pc.buttChange();

	outputText("\n\nLane presses forward until his body claps against yours, and your arms give out from underneath you, lowering your [pc.chest] into the quilt of his bed and raising your [pc.ass] for him to better conquer. Lane sighs too, feeling his dick buried all the way to the base by your hungry, demanding asshole, which clenches and squeezes around him for his benefit. The sensation begins to wear for him, and he’s quick to begin thrusting once again.");

	outputText("\n\nEvery slam of his into you is hungry and wanton, eager to bury himself until the sensitive nerves in his base are delighted at the warmth and slickness of your asshole. You begin to bliss out, yourself; every outward thrust leaves you teased and unsatisfied, and every inward thrust fills you and comforts you in ways you had never felt before.");

	outputText("\n\nHis thrusts begin to even out at a steady pace, slower than you know he’s capable of. He lingers every time he buries himself inside you, and every thrust is hard, strong, demanding, aggressive, almost angry; you love every single one and how they tickle you in different ways every time. Lane snarls like the feral lizard he evolved from; his claws dig and scrape against your [pc.hips] – you don’t care if they’ll leave marks or scars or if he makes you bleed, because then you’ll have something to remember the day he finally helped you realize your true station in life.");

	outputText("\n\nLane’s breath starts coming out in ragged, heaving strokes, and the lights coming from him begin to pulse more erratically. He’s thrusting faster, and you know he’s very close;");
	if (pc.hasCock())
	{
		outputText(" you reach down with one hand and start stroking your [pc.cock] in excitement");
		if (pc.cocks.length == 2) outputText(" while your [pc.cock 2] bounces shamelessly against your stroking knuckles");
		else if (pc.cocks.length >= 3) outputText(" while [pc.eachCock] flops and slaps against your stroking knuckles and heaving belly");
		outputText(".");
	}
	else outputText(" you reach back with one hand and knead and pull at one of your asscheeks, desperate to bring Lane to climax by masturbating him through your glutes.");
	outputText(" <i>“Come for me, master,”</i> you say to him, your own voice hoarse and needy. <i>“Take me!”</i>");

	outputText("\n\nHe’s more than happy to oblige, and with a long, shuddering grunt, he finally unloads his holy seed deep inside you. You feel his cock lurch and expand inside you as he leans forward, covering your back with his front. Warmth begins to spread inside you; a different warmth flows all throughout your body as you feel a sort of spiritual release at being the one Lane chose to bless you with his gift.");

	outputText("\n\nYour spiritual release is followed by a very physical one:");
	if (pc.cocks.length >= 1)
	{
		if (pc.cumQ() <= 349)
		{
			outputText(" your own [pc.cock] bulges in your pumping fist and lurches forward, spraying your [pc.cum] forward and onto his bed. Your orgasm pales in comparison to Lane’s, much like most of your other qualities; you last only several spurts before you’ve decorated Lane’s quilt as much as you can. But that doesn’t mean you stop cumming – though you’re dry, the feel of Lane continuing to burst inside you drives you to more and more orgasms, and you thank him for each and every one");
			if (pc.balls > 0) outputText(", even as your [pc.balls] begin to sting somewhat from the strain");
		}
		else if (pc.cumQ() <= 1200)
		{
			outputText(" your own [pc.cock] expands in your beating fist and you orgasm hard, joining your master Lane in his glory. Your [pc.cum] flows steadily and freely from you, and you match Lane burst for burst: with every pulse you feel reach deeper inside you, you shoot another heavy load onto his quilt. You shout your praise to him with each and every lewd pulse; your hand is covered in your semen and some bursts each reach high enough to splatter onto your [pc.chest]. Your orgasm ends with Lane, almost perfectly on-sync, almost like some sort of true-love adult fairy tale");
		}
		else
		{
			outputText(" your fingers are pushed apart by your rapidly expanding [pc.cock] as you blast your [pc.cum] all over master Lane’s quilt. As great and incredible your perfect master is, there’s just no way he can keep up with your production: he grunts and paints your insides with every thrust, but your heady stream doesn’t ever stop for him – it only gets thicker sometimes. You feel him begin to peter out, but you just keep going until your cream begins pooling around your knees and spilling over the sides of his bed");
			if (pc.balls > 0) outputText(". Your heavy, happy [pc.balls] tense and bounce with your incredible orgasm, and by the time you’re finally done, you feel a certain lightness to them that you haven’t felt in a while");
			if (pc.cumType == GLOBAL.FLUID_TYPE_HONEY) outputText(". The wonderful scent of fresh, thick honey rises to your nostrils, drowning out the heavy smells of your lovemaking");
		}
		outputText(".");
	}
	if (pc.cocks.length == 2)
	{
		outputText(" Your [pc.cock 2] thrusts and bounce in time with the one in your hand, spraying even more of your [pc.cum] all over Lane’s bed and underneath your body, adding to the glorious mess your master made you do.");
	}
	else if (pc.cocks.length > 2)
	{
		outputText(" [pc.EachCock] thrusts and bounce in time with the one in your hand, spraying even more of your [pc.cum] all over Lane’s bed and underneath your body, adding to the glorious mess your master made you do.");
	}
	if (!pc.hasCock())
	{
		outputText(" although you have no outlet, you feel a quivering, wonderful feeling emanating from your [pc.ass], reminding you of what an orgasm felt like before you lost your genitals. Lane, your beautiful master, has fucked you so well and thoroughly that he can bring you to orgasm even when you have nothing to cum with!");
		if (pc.balls > 0) outputText(" The endorphins even relax your [pc.balls], causing a delightful numbness to spread from them, making you forget about their frustrating fullness, if only for now.");
	}

	outputText("\n\nThe flashing lights of Lane’s body begin to wane as he calms down. You’re so happy that you’re seeing stars; you can’t believe how finalizing, how enlightening, it really felt to be taken so thoroughly by your rightful master. The sound of his satisfying panting and the feel of his tested and toned body flopping onto yours are both the most wonderful things you could hope to experience.");

	outputText("\n\n<i>“You’ve done well, [pc.name],”</i> he tells you. His words bring a flutter to your heart");
	if (pc.hasCock()) outputText(" and a lurch to your loins");
	outputText(". You’re so thrilled that you’ve pleased him! <i>“I think I’ve made the right decision in choosing you to be my cumdump.”</i> You assure him that it’s a station in life that you’ll never take for granted.");

	outputText("\n\nYou both spend some time on his bed, recuperating and basking in each other (you more than him, however, but that’s okay with you). You feel him go soft inside you until his delightful Daynarian cock eventually slips from your [pc.asshole]. You wiggle your ass on him, trying to entice him for more, but you frown when you realize the fun’s over for now. You’re nonetheless pleased with yourself and the knowledge that you’ll always carry a part of him in you from now on.");

	outputText("\n\nAll told, an hour passes between when you started and when Lane finally gets up off of you. He doesn’t seem to care about");
	if (pc.cumQ() <= 1000)
	{
		outputText(" the cum you’ve shot onto his quilt");
	}
	else
	{
		outputText(" the veritable lake of cum you’ve submerged his room in");
	}
	outputText(". He makes his way to the dresser against the far wall, and he redresses himself in a spare set of white, airy clothing. When he’s done, he looks just like the day you met him. <i>“Here’s the deal, [pc.name],”</i> he says. You listen to his words raptly. <i>“You’re going to wire me five hundred credits every twenty-four solar hours. If you can’t afford it, just send me what you have.”</i> You nod in understanding; you had agreed to this before. <i>“If you want to be hypnotized again, I’ll charge you the regular fee for the regular service. But you’re... going to pay me a tax. The ‘Body Tax’. I’ll be taking a little extra from you physically.”</i> You feel a fire beginning to stoke in your pelvis, and you tell him that you’re looking forward to it.");

	outputText("\n\n<i>“That’s a good pet,”</i> he tells you. <i>“Now, get dressed. As much as I’d like to fuck you every hour of the day, it doesn’t pay the bills. Go out there and make me my money.”</i> He then leaves you alone in his room, without so much as a glance. But you like that quality about Lane – a sort of hard, unforgiving solidarity of a man who takes what he wants. Thinking of him as a vicious sexual conqueror makes you hot all over again.");

	outputText("\n\nStill, you do what you’re told. In just minutes, your [pc.armor] is back on, and you leave his bedroom. Lane is sitting at his desk as though nothing had happened; you give him a sultry grin that he does not return, before you leave his little hut and return to the caves of Venar.");

	// Lust reduced to 0, time progresses by 1 hour, place PC one square outside Lane’s Plane
	processTime(60);

	player.loadInAss(lane);

	lane.orgasm();
	pc.orgasm();

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function firstTimeLaneMPCFH():void
{
	clearOutput();

	outputText("Lane is quick to flop his body atop yours and roughly grip onto your [pc.fullChest]. You wince at the way his claws dig into your skin, but the feeling of him pressing himself against you is far more pleasurable than any pain he might inflict. You squeeze your legs together");
	if (pc.hasCock()) outputText(", enjoying the way [pc.eachCock] grows and inflates against his warm, smooth, lower-belly scales. You get a warm spike of pleasure with every movement you both make against each other.");
	else outputText(" and you raise your [pc.hips], humping your [pc.cunt] against his warm, smooth lower-belly scales. It’s a difficult angle to get, but with every push you get against your [pc.clit], your eyes cross and your mouth gets a little drier.");

	outputText("\n\nLane mauls at your [pc.fullChest], squeezing and pulling at your flesh. He growls at you predatorily, bearing his dripping teeth and showing his flapping tongue in his elongated mouth. As much as you want him, you don’t want him to bite you... he lunges forward, startling you, and you brace yourself for the pain (sexy as it would be, coming from Lane), but what you feel instead is the hungry licking and sucking on your [pc.nipples].");

	outputText("\n\nYou heave your chest into his maw, enjoying the new wet sensation on your chest and loving the delectable sounds of his tongue slurping on your [pc.skin]. He humps his waist against you the whole time, grinding his expanding dick between against your thigh. You moan out as you trail your hands down his scaly, rough back, your fingers bumping over each ridge and crevice exquisitely until your reach the base of his tail. Your deftly wrap your fingers around it, tugging at massaging and tickling at it, groping what little ass muscle he has, for his pleasure.");

	outputText("\n\nAs you do that, Lane’s appetite for your breasts is voracious: his tongue is quick and deft, swishing over your sensitive mounds, across your [pc.nipples], and through the cleavage between them as you transitions to your other boob and repeating the process. The sound of Lane hungrily sucking and licking at you like a beast makes you all the hornier.");
	if (pc.biggestTitSize() <= 1) outputText(" As you feel his long tongue mark your chest, you moan in both pleasure and disappointment; it feels great – beautiful, even, the way he samples you – but you can’t help but feel a little self-conscious about your cup size. From the way he’s going at it, though, maybe he’s a fan of tiny titties...");
	else if (pc.biggestTitSize() <= 7) outputText(" You thrust your [pc.chest] higher, eager to feed more of them to him, to feel his mouth wrap around your two proud puppies, to feel his teeth nip at your skin excitedly and to feel his breath wash between them... you’re just as absorbed into Lane as he is into you. You flex your arms against them, squeezing them together, thrusting your [pc.nipple] further along his tongue.");
	else if (pc.biggestTitSize() <= 18) outputText(" You love the way Lane sinks his face into your chest as he presses forward. He makes you feel so wanted, so sexy; he gently but demandingly nips at the flesh of your [pc.chest], groping at it aggressively with his face. It takes him some time to cover you in his saliva as he slobbers over them, but you’re more than happy to lay there and let him have his way with you. From the way his cock slides against your thigh as his humps grow more insistent, he’s certainly enjoying himself.");
	else
	{
		outputText(" Lane positively disappears between your [pc.chest], sinking into them as he licks and sucks and kisses and nips. You sigh, enjoying the way he determinately enjoys every little bit you give him; his brown lizard skin disappears in the valley of your boobs, but you can feel everything he does to you. You’re going to have hickeys in places you didn’t realize you had, and you’re looking forward to it. Lane’s hips are positively pumping against you in his excitement; maybe he’s a fan of");
		if (silly) outputText(" tig ole’ bitties?");
		else outputText(" boobs as boisterous as yours?");
		outputText(" Maybe he’ll enjoy it if you make them bigger, too...");
	}
	if (pc.hasFuckableNipples())
	{
		outputText("\n\nYou leap in pleasure each time Lane’s tongue passes over your [pc.nipples], and you moan and whimper for him to continue without actually telling him. Lane doesn’t stop or even slow his exploring of your body, but he’s quick to get the hint every time his tongue tastes the different tastes and textures of your extraordinary nipples. You become wetter along your [pc.chest] than you are between your legs, and not just because of his saliva.");
	}
	else if (pc.hasNippleCocks())
	{
		outputText("\n\nYour [pc.nipples] extend from your chest until they’re at their full, rock-hard length, standing proud atop your mounds. Lane is clearly aware of them, and he takes his time coating them with his spit like he does the rest of you, but he’s otherwise much more interested in the rest of your breast flesh.");
	}
	else if (pc.isLactating())
	{
		outputText("\n\nYou sigh as his administrations cause your [pc.milk] to flow from the tips of your [pc.nipples]. Whenever he gropes at a particularly sensitive spot, a splurt of it shoots out a few centimeters and then dribbles down your supple [pc.skinfurScales]. When he first tastes it, he pauses, unfamiliar with the taste or the sensation. He reaches up and squeezes one of your tits, and is surprised when some more begins to flow from you. He otherwise pays it no mind, though – he cleans wherever your milk lands, but he doesn’t seek it out.");
	}
	if (pc.breastRows.length == 1)
	{
		outputText("\n\nHis four-fingered hands aren’t idle. They stroke along your skin; across waist and your [pc.hips], under your [pc.chest] and over your ribs. They squeeze at you, stress-testing their new property. They clench at your [pc.ass] and grope along your thighs. The way he tickles and massages you make you feel so good and loved – and they reassure you that Lane feels the same way.");
	}
	else if (pc.breastRows.length >= 2)
	{
		outputText("\n\nHis hands busily grope and feel along your [fullChest], and wherever his mouth doesn’t reach, his webbed hands are more than ready to pick up the slack. You coo, loving the way he doesn’t neglect any part of you. His excitement begins to escalate further as his face travels to your others breasts, judging from the way his humping becomes more insistent – he must be a real fan of boobs, big or small.");
	}
	if (pc.hasCock())
	{
		outputText("\n\n[pc.EachCock] stands between you insistently, absolutely pouring your pre down your shaft and pooling at the base of your stomach");
		if (pc.balls > 0) outputText(" and where your base meets your [pc.sack]");
		outputText(". Lane’s smooth belly scales rub sensually against you, and you love the electric feeling of it, but he grunts in displeasure at the way it pokes at him while he’s busy with your [pc.chest]. Disappointed but understanding that Lane’s wants are yours, you shift your hips so [pc.eachCock] flop");
		if (pc.cocks.length == 1) outputText("s");
		outputText(" to the side and rubs against his hip rather than his stomach.");
	}

	outputText("\n\nHis licking eventually trails upward, across your neck and up to your jaw. He body begins to cover you as he finds his way up, pressing against you possessively, and you moan in appreciation. His tongue begins to lap up your chin and across your [pc.lips], and you open them, knowing what he wants. His kiss is very dominant and almost affectionless: the raw sexuality of the way his tongue presses and pins yours while he bears down on you, forcing you deeper into the mattress, makes you so melt. The way he controls you so effectively makes you shudder in ecstasy.");

	outputText("\n\nJust as the tip of his tongue begins caressing your palate, he withdraws, much to your chagrin. Instead, he sits up and onto his knees, towering his body over yours. His tassels are flared wide open, and his pulse is quick and excited, but unfocused; the lights of his piercings and the swirls of his tattoos sink you into him, just as, from the way he adjusts his pelvis and begins aligning his with yours, he will soon be sinking into you.");

	outputText("\n\nHe sits on his knees, rubbing his pink, smooth, tapered Daynarian cock against your waiting mound. He grinds it against your [pc.clit]");
	if (pc.balls > 0) outputText(" and up the crease between your [pc.balls]");
	outputText(" like he had against your thigh; with each thrust, an electric, exciting jolt goes through your body, but it’s not enough to satisfy you. He moans out every time the base of his dick brushes against your vulva, and he lets his thick base rest there for a moment before he backs up and teases you again. It’s frustrating and teasing, but you love every bit of it.");

	outputText("\n\nEventually, he tires of that, and he grips onto his shaft as he pulls back. Your mouth waters in anticipation: the moment you were born for is just a thrust away! You grip onto his quilts, bracing yourself for the moment he buries himself in you and takes you the way only a real man like him could. The point of his dick traces the lips of your [pc.vagina], testing the waters, before he finally pushes in.");

	outputText("\n\nEvery centimeter he goes into you is divine.");
	if (pc.hasCock()) outputText(" [pc.EachCock] stands tall and almost painfully hard between you, wishing for some action, but he outright ignores your masculine half.");
	outputText(" His hands trail to your [pc.hips], and he squeezes them roughly – you feel his claws pinch against your skin as he gropes you, and you almost hope it leaves a mark, if only so you’ll have proof of your consummation later. He roils his hips forward, and you go cross-eyed: every push against your walls lights another firework in your senses. You look down,");
	if (pc.biggestTitSize() <= 19)
	{
		if (pc.biggestTitSize() >= 8) outputText(" straining to see over your sizeable bust,");
		outputText(" to your pelvis as he pushes in. His skin is glowing so brightly and frequently, you’re curious to see if you could see the light of his cock through your waist. Unfortunately, that’s not the case – that would have been so kinky!");
	}
	else outputText(" trying to see over your titanic tits, but they’re way too huge so see over. You try to wrap your hands around them and pull them apart, but it’s no use. You sigh. You were curious if the glow of Lane’s blood was strong enough to see through your skin, now that he’s inside you. That would have been so kinky to see!");
	outputText(" The thought sends you that much closer to cumming, but you resolve to hold back. You want to come with your master.");

	outputText("\n\nHe exhales once he’s buried as deep inside you as he can. You writhe beneath him: he’s the <i>perfect</i> length for you, tickling and caressing your most sensitive spots without overloading or overbearing you. He backs up, making you feel cold for a moment, and he thrusts back in, harder. Is it just you, or is he getting thicker? God, you hope so!");
	pc.cuntChange();

	outputText("\n\nYou can do nothing but gasp and squirm beneath him as he works you, fucking his dick into your [pc.vagina] again and again, and each thrust sends you to worlds you haven’t explored yet. He’s particularly harsh on his inward thrusts, then he pauses as his base kisses your sensitive cunny, then he’s quick to pull out and repeat. You feel so weak – but in a good way. Your grip loosens on the quilts in your pleasure. You bring both your hands to your [pc.chest],");
	if (pc.biggestTitSize() >= 3) outputText(" massaging them and pressing them together for master Lane’s benefit");
	else if (pc.biggestTitSize() <= 2) outputText(" pinching at your [pc.nipples] in an effort to bring you closer to orgasm");
	outputText(".");

	outputText("\n\nAs much as you love Lane and the way he’s drilling you, he’s not the most gentle of lovers. One particularly powerful thrust makes you wince, but it’s a sexy kind of wince, because Lane made you do it. It doesn’t go unnoticed, and his eyes lock to yours. <i>“I must not have mentioned,”</i> Lane says, his voice ragged with his breath. You strain to hear him over your heartbeat and the sound of his hips slamming into yours. <i>“Daynarian dicks aren’t like your typical tool. Most of our nerve endings are in the base.”</i> The tempo of his thrusting doesn’t change, but they get stronger, and he begins to pant. <i>“We’re not satisfied with just the tip. It’s another evolutionary advantage: it’s so we want to go as deep as we can to plant our seed.”</i>");

	outputText("\n\nYou try to focus on what he’s saying, but it’s hard when every other sense demands your attention. He said something about his dick, and wanting to go deep. That’s good enough for you! <i>“Go deeper, master!”</i> you encourage him, lifting your [pc.hips] with every inward thrust, no matter how painful it may feel. <i>“I want you to come in me! Fill me! Make me yours! I want to feel your cum in me when I leave!”</i>");

	outputText("\n\nYour dirty talk seems to have an effect on him, and his thrusting finally increases in speed, as does the pulsing of his lights. His cock is so hard inside you – you’re <i>positive</i> it was actually getting thicker, too. His breathing starts coming out in more rapid bursts, and you brace yourself for the explosion that’ll remake you as Lane’s property, now and forever.");
	if (pc.hasCock()) outputText(" [pc.EachCock] is so hard between you two that it hardly sways at all under Lane’s force. With every push, a little bit more precum splurts from you, some getting on you, some getting on Lane, and he doesn’t seem to mind.");

	outputText("\n\nHis shudder is the only warning you get before he hilts into you as far as he can. His pulse quickens for just a moment, and you feel a beautiful, cleansing warmth wash your insides. You try to stifle a shout of ecstasy, but you can’t help letting the worlds know of your joy when you finally let go, letting your [pc.vagina] cum with your master. Your release has a sort of enlightening, clarifying quality to it: now that your master has finally come inside you after you’ve spent your life pining for it, you feel you can leave this life without regrets. You’d happily give up hunting for your father’s fortune if it meant being with Lane forever. ");

	outputText("\n\nYou tighten, your muscles milking every centimeter of Lane’s length, eagerly swallowing more of his cum into you. Every blast of his cum into you shakes the earth once more, and you’re seeing more stars and swirls than the ones on Lane’s body. You feel the rest of your strength leave your body as you’re wracked again and again with orgasms.");
	if (pc.hasCock())
	{
		if (pc.cumQ() <= 500)
		{
			outputText(" [pc.EachCock] erupts powerfully, spraying your [pc.cum] some distance into the air between you two. It rains down in time with Lane’s thrusts, splashing onto your stomach and [pc.chest], drenching you with your own juices, spreading your own liquid warmth around your skin to compliment the warmth blossoming inside you. Some of it splashes onto Lane, reaching as high as his own chest, but, in his own single-minded orgasmic ecstasy, he doesn’t care at all. Which is all the sexier to you.");
		}
		else
		{
			outputText(" Your cum rockets from [pc.eachCock] with a force unlike anything you’ve felt before. Your [pc.cum] shoots several feet into the air in long, thick strands, and it showers down on you in thick splashes and clumps. It soaks your [pc.chest], your stomach, and your [pc.hips], leaking between the creases of Lane’s claws. It reaches high enough to land on Lane’s elongated face, with drops of it resting on the bridge of his nose, while other strands hit him on his lower jaw and his upper chest. It looks so hot, the way you’re coating him the way he’s taking you – and, to your further excitement, you see his long tongue snake out to clean his nose for a split second. Knowing your jizz is on his tongue makes you cum again.");
		}
	}

	outputText("\n\nEventually, his orgasm tapers to nothing inside you. You groan out load, wishing he had just a little bit more to give, to douse the last few embers inside you, although you actually doubt you’ll ever be satisfied. He collapses forward");
	if (pc.hasCock()) outputText(", crushing your softening cock");
	if (pc.cocks.length > 1) outputText("s");
	outputText(" between you both and flopping into the puddles of [pc.cum] you’ve covered yourself in");
	outputText(", his hands leaving your aching [pc.hips] and slapping onto the quilt near your shoulders. He looms over you, panting and snarling like a beast, and you can’t help but adore him even more from the domineering, sexy angle you’re seeing him in.");

	outputText("\n\nHe withdraws from your [pc.vagina], making you whimper. He crawls his body forward until his hips are against your face: his cock is hanging limp just before your [pc.lips], and you see it beginning to shrink as his genital slit begins working on slurping it back inside him. Taking that as a challenge, you wrap your mouth around it, to clean it of both your juices and, maybe, get him going for another round. His cock tastes better than you had ever imagined – maybe because you can taste both of you on him, mixing into a sort of divine cocktail of... completion. Accomplishment.");

	outputText("\n\n<i>“That was great, [pc.name],”</i> he tells you, and he gropes at your left boob affectionately as you clean him. Your heart jumps in your chest at his congratulation, and you moan your thanks around his cock. <i>“I think I’ve made the right decision in making you my personal whore.”</i> Knowing that you’re his from now on starts making you wetter");
	if (pc.hasCock()) outputText(" and harder");
	outputText(", and you’re already ready for another go.");

	outputText("\n\nAs you clean Lane’s groin with your mouth, a concern comes to mind. You ask Lane if there’s any chance of you becoming pregnant with his kids. You admit that you’re not very well versed with Daynarian biology. Of course, you’d be glad to bear his offspring if he only wished. He hums to himself as he thinks – he clearly hadn’t considered that either. <i>“I’ve never heard of a Daynarian cross-breeding with your species before,”</i> he admits. <i>“But we should be careful just in case. Find some birth control medicine as soon as you can.”</i> You nod in understanding, bobbing Lane’s cock in your mouth as you do.");

	outputText("\n\nUnfortunately, your mouth loses the battle with Lane’s genital slit, and his cock disappears inside his body. You persistently lap at his slit like a bitch until he pulls himself away from you");
	if (pc.hasCock()) outputText(". The sexy sound of your cum peeling between your skin and his rings through the air");
	outputText(". You lay on his bed, wanting more, as he makes his way to one of his dressers. From it, he pulls out another set of clothing: an undergarment; a set of translucent, pants; and a thin shirt. When he’s dressed, he looks exactly as the day you had met him.");

	outputText("\n\n<i>“Here’s the deal, [pc.name],”</i> he says. You listen to his words raptly. <i>“You’re going to wire me five hundred credits every twenty-four solar hours. If you can’t afford it, just send me what you have.”</i> You nod in understanding; you had agreed to this before. <i>“If you want to be hypnotized again, I’ll charge you the regular fee for the regular service. But you’re... going to pay me a tax. The ‘Body Tax’. I’ll be taking a little extra from you physically.”</i> You feel a fire beginning to stoke in your pelvis, and you tell him that you’re looking forward to it.");

	outputText("\n\n<i>“That’s a good pet,”</i> he tells you. <i>“Now, get dressed. As much as I’d like to fuck you every hour of the day, it doesn’t pay the bills. Go out there and make me my money.”</i> He then leaves you alone in his room, without so much as a glance. But you like that quality about Lane – a sort of hard, unforgiving solidarity of a man who takes what he wants. Thinking of him as a vicious sexual conqueror makes you hot all over again.");

	outputText("\n\nStill, you do what you’re told. In just minutes, your [pc.armor] is back on, and you leave his bedroom. Lane is sitting at his desk as though nothing had happened; you give him a sultry grin that he does not return, before you leave his little hut and return to the caves of Venar.");

	// Lust reduced to 0, time progresses by 1 hour, place PC one square outside Lane’s Plane
	processTime(60);

	pc.loadInCunt(lane);

	pc.orgasm();
	lane.orgasm();

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function firstTimeLaneFPCMH():void
{
	clearOutput();

	outputText("Lane leaps onto the bed, immediately straddling your stomach. She lowers her body and kisses her snatch against your lower ribs, and she immediately shivers in desire. You nervously lift your hands, knowing you’re about to caress your goddess, but just as you feel the electric thrill of your hands on her hips, she slaps them away. <i>“I am in charge,”</i> she tells you, her tassels flared open. You moan in submission, watching the swirls and the flashing lights, physically unfulfilled but enticed. She’ll be good to you.");

	if (pc.biggestTitSize() <= 5)
	{
		outputText("\n\nLane smirks down at you and slaps at your tits. You grunt in some pain, but then she becomes gentler, groping and massaging at them with soothing hands. The smoothness of the scales on her palms feel divine against your [pc.chest]. She hums to herself in amusement as she slides her hands all across the flesh of your breasts. She palms at your [pc.nipples]");
		if (pc.isLactating())
		{
			outputText(", soaking them with your [pc.milk] and rubbing your cream into your skin");
		}
		outputText(", and you squirm beneath her. She leans forward, her mouth deliciously close to them, and her tongue snakes out – to lick her lips and leave you teased. Her abdomen slides across your stomach, leaving a trail of her excitement in its wake.");
	}
	else
	{
		outputText("\n\nLane clicks her tongue as she looks down at you, and then lunges forward, gripping onto your [pc.chest] tightly. You yelp out in surprise as you feel the sharpness of her claws digging into your flesh. She pulls, squeezes, stretches, and abuses your titflesh; the softness of her palms contrasts her aggressiveness. She pinches and pulls at your [pc.nipples]");
		if (pc.isLactating())
		{
			outputText(", causing your [pc.milk] to squirt into the air between you, soaking up to your neck and around her webbed fingers");
		}
		outputText(", heedless to your comfort. She leans forward, her mouth dangerously close to your [pc.chest], her lips open and snarling her teeth at you. Her abdomen slides down your stomach, and despite her aggression, she leaves behind a trail of her own excitement on you. She’s so rough – maybe she’s jealous of your assets?");
	}

	outputText("\n\nLane sits back up and swings her right leg up and over your head, followed by her left over your stomach and torso, until she’s straddling you reverse-cowgirl. She slides her hips backward, her puffy cunt sliding across your skin,");
	if (pc.biggestTitSize() <= 2) outputText(" over your [pc.chest]");
	else outputText(" between your [pc.chest]");
	outputText(", atop your neck, until you’re face-to-waist, lips-to-lips with her genitals. She hums to herself as she lowers her upper body, pressing her own tits onto your lower stomach, her");
	if (pc.biggestTitSize() <= 5) outputText(" soft hands trailing down your thighs sensually");
	else outputText(" harsh claws marking roads down your thighs, not enough to bleed but just enough to hurt");
	outputText(". <i>“Pleasure your mistress. Let her know you want her.”</i> [pc.EachCock] is standing proud and tall in front of her, but clearly that’s not proof enough. Not that you’re complaining.");

	outputText("\n\nShe lowers her hips onto your face, smothering you between her luscious, scaly thighs. The glow of her blood isn’t especially visible through the thickness of her glutes, even thin as they are, but the few pulses you make out sends a pleasant chill up your spin. Your lips connect with her cunt; at first, you’re dazed at the thickness of her scent and the fact that you’ll finally be accomplishing what you’ve been <i>made</i> to do, but it’s a fleeting emotion. Your [pc.tongue] snakes out, tasting her eagerly, and you’re not disappointed: she tastes finer than any wine you’ve ever had. You open wider, eager to cover more of her with your mouth, to taste as much of her as you possibly can.");

	if (!pc.hasTongueFlag(GLOBAL.FLAG_LONG) && !pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE))
	{
		outputText("\n\nShe coos at your eager ministrations on her pussy, and she rewards you by letting more of her weight press against your face. You kiss and lick at everything you can, loving her taste and textures: her inner vaginal muscles feel carved and curved, guiding you deeper into her. The muscles contract, and their design gently yet insistently pulls you deeper into her. [pc.EachCock] strains in the air, waiting impatiently to feel what it’s like.");
	}
	else if (pc.hasTongueFlag(GLOBAL.FLAG_LONG) && !pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE))
	{
		outputText("\n\nShe laughs in restrained excitement as your [pc.tongue] pushes into her with ease. You taste all manner of flavours inside her, most of them bitter but all of them as amazing as you had fantasized. Your muscle wriggles and collides against hers, feeling and exploring her crevasses and peculiarities: the muscles of her inner vaginal walls seem designed to pull intrusions deeper into her, and every time you hit a particularly sensitive zone, she shudders her back and rubs her pussy against your lips a little harder. [pc.EachCock] throbs in excitement, hoping to make your mistress shudder as well as your [pc.tongue] can.");
	}
	else if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE))
	{
		outputText("\n\nHer breath leaves her lungs in a hurry as your enormous [pc.tongue] easily reaches her most delicate, private depths, with quite a bit of tongue to spare. Your every movement inside her is met with short, excited gasps and an insistent, needy grind of her cunt against your lips and her weight crushing you into the mattress. Her girlcum flows and coats your every tastebud, and drools from her cunny and onto your chin and your neck, and you love every taste and every sensation, knowing you’ve pleased your mistress so well. [pc.EachCock] is hard as can be, their fighting spirit and refusal to be shown up by your [pc.tongue], talented as it might be, evident in the precum pooling across your base.");
	}

	outputText("\n\nYour hands grip tightly onto the quilt, fighting their every reflex to reach up and grab onto Lane’s ass. She’s always watching them, teasing you about them: every time you consider disobeying and grabbing a fistful of scaly ass, she chastises you playfully. <i>“No haaaands,”</i> she says in a sing-song tone, and you sigh in defeat.");

	outputText("\n\nEven so close to your sex");
	if (pc.hasCock() && pc.hasVagina()) outputText("es");
	outputText(", Lane does nothing to return your service. Her soft, careful fingers examine [pc.oneCock], mapping the veins and tickling the skin, but she never grips you or pumps you. You can feel her breath wash over [pc.eachCock], but that’s all she does with her mouth.");
	if (pc.balls > 0) outputText(" She cups and rolls your [pc.balls] between her fingers delicately, knowing how full and sensitive they are for her, but she doesn’t please them or massage them.");
	if (pc.hasCock() && pc.hasVagina()) outputText(" Her claws gently tease and rake against your [pc.vagina], making you jump and squirm under her, but she doesn’t penetrate you with them.");
	if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" Every touch and caress she makes is accentuated by a leap of her own whenever your massive tongue hits something particularly pleasurable, but she’s good at keeping her composure.");
	outputText(" It’s all very frustrating, but you continue your worship without question: what she wants, you want, and if she wants to tease you, you want her to tease you.");

	outputText("\n\nShe suffocates you with her quim for another minute, both of you loving every second of it, before she climbs up and off of you. She swings her legs over you again, and again she’s straddling you, facing you. <i>“Good " + pc.mf("boy", "girl") + ", very good,”</i> she praises. You perk your ears at her praise and you feel your heart leap with joy. She leans forward, closing the gap between your faces. <i>“So good. You let your mistress know you love her. You deserve a reward.”</i> She clamps onto your arms with her hands, pinning them to the bed, as she draws her body backward. Her ass collides with your aching [pc.cock], which lurches in anticipation.");

	outputText("\n\n<i>“But before I do,”</i> she says, grinding her body against your dick, hot-dogging you with what little meat on her ass she has, <i>“I’m going to give you an anatomy lesson.”</i> You look deep into her eyes, sinking into her subconscious grip, watching her irises change color and her blood pulse around her face. You wait rapturously for her knowledge, though you bite your lower [pc.lip], trying to resist thrusting into her.");

	outputText("\n\n<i>“A Daynar’s cunt is very sensitive at the lips,”</i> she moans, grinding her snatch against your pole, slicking it with her juice and your spit, <i>“but the real prize is much deeper. Just before the womb. It’s so we want our men to go as deep as they can, to get their cum as deep as possible.”</i>");
	if (pc.biggestCockVolume() <= 32) outputText(" You gulp in embarrassment, knowing how... lacking you are when it comes to male assets. Her expression is mostly neutral. <i>“It’s not the size that matters,”</i> she tells you, nuzzling your [pc.face] with her face to calm you down, but her tone is rather demanding. <i>“But I hope you know how to use it.”</i>");
	else if (pc.biggestCockVolume() <= 92) outputText(" She smiles down at you as she grinds herself on your meat. You smile back, happy that she’s happy, and you’re more than up to the challenge. <i>“I’m sure you’ll do great,”</i> she tells you, leaning in to nuzzle at your [pc.face], but then she whispers, <i>“because you wouldn’t want to leave your mistress wanting.”</i> You steel your resolve: you’re going to fuck Lane senseless, come hell or high water!");
	else if (pc.biggestCockVolume() <= 199) outputText(" She licks her lips and her eyes narrow deviously as she cranes her back to hump the entirety of your shaft, from [pc.cockHead] to base. <i>“If I’m honest,”</i> she says as she lowers her torso, her heavy boobs resting on your [pc.chest]. She presses her cheek against yours. <i>“You’re probably the biggest I’ve had. I’m looking forward to it.”</i> A sense of pride wells up in your chest. You’ve never been more ready to do your life’s duty as you have been after hearing her say that.");

	var selCock:int = pc.cockThatFits(lane.vaginalCapacity());

	// Too big
	if (pc.biggestCockVolume() >= lane.vaginalCapacity())
	{
		outputText("\n\nShe leans her hips back, drawing her snatch from the base of your [pc.cock] to its tip. She chews at her lip and narrows her eyes as she gauges you, judges you – despite your immensity, you feel inadequate because from the look on her face, you’re making your mistress reconsider. <i>“To be frank,”</i> she begins – never a good start to any conversation. <i>“You’re... massive. I don’t think you’ll fit.”</i>");

		if (selCock != -1)
		{
			outputText(" She wraps her tail around [pc.eachCock] as she continues to hump against you, searching for a substitute to match your enormous dick.");
			if (pc.cocks.length > 2) outputText(" Eventually, s");
			else outputText(" S");
			outputText("he finds your [pc.cock " + selCock + "], and strokes it for a moment while she hums. <i>“Luckily, you’ve got options. I’ve always admired versatility.”</i> You sigh in relief: you’ll still get to achieve your life’s goal by the end of the day.");
		}
		else
		{
			outputText("\n\nLane wraps her tail around your [pc.cock] and presses it against her cunt, and she begins to hump against you in earnest. It’s clear that she’s not too interested in even trying to stuff you inside her, and you moan out in dismay; you had <i>one job</i> in life, and you had to go and ruin it by getting carried away with male enhancement. Lane doesn’t look especially thrilled either, but she’s making due, and the feminine gasps of pleasure she makes as she fucks herself against your meat is about all you’re going to get.");

			outputText("\n\nShe arches her back in her effort to rub more of herself against you. You can feel her pussy lube the wall of your [pc.cock], her juice dripping and pooling at your base, and then she slides it all the way down until her hips connect with yours. She’s humping and fucking as though she were bouncing on a real dick, but there’s obviously a lot more work and a lot less payoff to it.");

			outputText("\n\nYour [pc.cock] towers and arches over her back, dripping your [pc.cum] onto her shoulders. From the way her eyes glance to her sides, she notices, but she doesn’t try to move out of the way. Instead, she lifts her hands off your arms and places them next to your ribs. <i>“Grab my tits,”</i> she commands you, her breath ragged. <i>“Might as well try and make the most of this.”</i>");

			outputText("\n\nYou babble your thanks to you as you release your white-knuckle grip on her sheets and reach for her breasts. Their smoothness is unreal: the scales on her front are worn, soft, and warm. You’re almost tempted to say it’s smoother than human skin. Her boobs, while obviously fake, feel as every bit the real deal as any other set you’ve felt – the wonders of modern cosmetic surgery. Your fingers press into her skin, which easily meld around them, resisting firmly without being solid. She sighs at your plying, and she thrusts them out for you to better feel at them.");

			outputText("\n\nYou feel Lane’s tail squeeze harder at your shaft, constricting it, while it snakes and coils its way down, towards your crotch. ");
			if (pc.balls == 0)
			{
				outputText("The tip of her tail tickles and searches along your base for anything to play with, but all it strokes at is empty skin.");
				if (!pc.hasVagina()) outputText(" It reaches deeper, caressing at your perineum, hoping there’s something else to play with, but finds nothing. Her grip on your [pc.cock] tightens the farther she reaches, until she’s wriggling at your [pc.asshole]. You tense, caught between not wanting her to put a tighter grip on your prick and wanting her to bless you with another pleasure, but ultimately, she withdraws. She winds up resuming masturbating your length with her tail. She sighs – you could swear she’s almost as disappointed as you are.");
			}
			else
			{
				outputText("The tip of her tail finds your [pc.sack] and begins sliding between your [pc.balls], frigging itself in the crevice between them. The underside of her tail is just as soft as the scales of her belly, and despite her frantic humping against your shaft, her tail is smooth and sensual in their rubbing and tickling against your jewels.\n\n");
			}
			if (pc.hasVagina())
			{
				outputText("Her tail continues to slide ever downward, until it finds your [pc.vagina], alone and neglected in the activities. She gently slides her tail between your uvula, teasing your tunnel by dipping her very tip just beyond your lips but no farther. You yelp in pleasure whenever he smooth scales draw over your [pc.clit], and you feel another surge through both your sexes. Lane looks down at you, almost contemptuous that you’re experiencing more pleasure than her; you return her look with absolute devotion and adoration that she would go through the effort, despite your ‘greed’.");
			}

			outputText("\n\nEventually, your hard work begins to pay off. Lane becomes more frantic and less focused; her humping becomes more forceful, pressing her body against your [pc.cock] while her tail tightens its grip, keeping it from swaying. She begins to gasp as her body rocks against you. You thrust your hips upward in time to her humping; your hands stop having any sense to their groping and default to simply rubbing the butts of their palms against her skin. She tenses and lets out a quiet wail, and you feel a hot liquid start coating the skin of your [pc.cock].");

			outputText("\n\nYour orgasm is right on the coattails of hers, and with another few humps, you join her in bliss.");
			if (pc.cumQ() <= 150) outputText(" Your quantity is quite lacking, compared to the excess of your [pc.cock]. Your [pc.cum] spits from your [pc.cockHead], pumping out once, twice... and that’s it. It drips in strands from your urethra, sliding down the skin of your shaft, and it drops onto Lane’s scaly back, which she barely notices in her own throes of ecstasy. Despite your volume, the pleasure you experience at finally achieving orgasm with your beloved mistress is beyond words – even though you finish your orgasm before she does, and she started before you did.");
			else if (pc.cumQ() <= 500) outputText(" You feel your [pc.cum] launch up your cock and towards your looming [pc.cockHead]. Lane’s constricting tail pinches your tube and restricts the flow somewhat, but your quantity cannot be denied: it fires from your urethra with some force, shooting into the air above you both. Some of it hits the ceiling; the rest rains down on Lane’s back, coating her in your proof of your love for her. Lane stops her shivering before you do, but she doesn’t stop seeing stars until the last of your jizz is squeezed from you and drips a trail down your shaft. Your [pc.cock] gurgles a little from the cum her tail managed to keep back.");
			else outputText(" Lane’s constricting tail tries to constrain the onslaught of cum rocketing up your shaft, but all she manages to do is increase the pressure as it rockets out of your tip. Your [pc.cum] explodes from you, launching into the air and smashing against the ceiling above you. Its arc goes above both of you, landing on the floor between the bed and the wall. It goes everywhere, but most importantly, it completely soaks Lane: her scaly back is totally covered with your jizz, and then some. Strands of it trace down her arms to her fingers and pool at the base of her tail. Your orgasm, and your pent-up blasts of your seed, continue well after Lane’s has ended, and you paint the room white the entire time.");

			outputText("\n\nLane collapses on top of you, enjoying the warmth between your bodies in the afterglow. Despite your inability to perform, you’re somewhat eased that you’ve pleased your mistress.");
			if (pc.cumQ() > 150)
			{
				outputText(" She reaches up towards her back, feeling along it for the cum you’ve splattered all over her");
				if (pc.cumQ() > 500) outputText(". She doesn’t have to reach very far – she’s covered in pools and strands of it, and her every movement has it splash off her body in sheets");
				outputText(" She coats her fingers in it and brings it to her face, then she looks you in the eye – your [pc.cock] lurches at the idea that she might lick her fingers clean. But, instead, she wipes them off on your [pc.chest].");
			}
		}
	}

	// Will fit
	if (selCock != -1)
	{
		outputText("\n\nLane raises her lower body, trailing a path along your [pc.cock " + selCock + "] as she prepares to penetrate herself on you.");
		if (pc.cocks[selCock].volume() <= 32) outputText(" She snickers at you");
		else outputText(" She bites her lower lip");
		outputText(" as she does, and, when she finally reaches the tip of your penis, she rears back and engulfs you in one swift motion.");
		var cvState:Boolean = player.cockVirgin;
		pc.cockChange();

		outputText("\n\nYou both moan out in satisfaction – there’s no doubt she wanted it too, but you doubt she wanted it as badly as you did. Lane has finally allowed you inside her, and it’s everything you had dreamed it would be. Her muscles feel very peculiar: they don’t squeeze like");
		if (cvState) outputText(" you imagined most other cunts would");
		else outputText(" most other cunts you’ve fucked had");
		outputText(", but they ripple in a wave-like motion, from her entrance to her womb, in an effort to massage the jizz out of you. Like everything else about Lane, it’s absolutely divine");
		if (pc.cocks[selCock].volume() <= 32) outputText(", and you find yourself wishing you had more manhood with which to feel it");
		outputText(".");

		outputText("\n\nLane begins fucking you with a bit more earnest, lifting her hips and pressing them back down onto yours.");
		if (pc.cocks[selCock].volume() <= 32) outputText(" She giggles with every press against you she makes");
		else if (pc.cocks[selCock].volume() <= 92) outputText(" She moans out every time she pressed down and your [pc.cock " + selCock +"] teases her more sensitive spots");
		else outputText(" She gasps in surprise and pleasure with every hump, loving the way your [pc.cock " + selCock +"] fits her just perfectly");
		outputText(", and you writhe with her, meeting her every hump with one of your own, wanting to go deeper and feel more of her amazing alien pussy.");

		outputText("\n\n<i>“You’re a good " + pc.mf("boy", "girl") + " [pc.name],”</i> she tells you");
		if (pc.cocks[selCock].volume() > 32) outputText(", her breath catching in her mouth with every thrust against you");
		outputText(". <i>“So obedient.”</i> With her position and the way she’s bearing down on your torso, she has all the leverage: your every lift is miniscule compared to the distance and power Lane can utilize. Generously, she relinquishes it – she sits up, removing her hands from your arms, and stretches her own above and behind her neck. <i>“Go ahead and play with my tits, [pc.name]. Let me know you appreciate them.");
		if (pc.cocks[selCock].volume() <= 32) outputText("”</i> She grinds her pussy down on your [pc.hips], trying to fit as much of you as she can into her. <i>“Lord knows I’ll be needing as much as I can get out of you.");
		outputText("”</i>");

		outputText("\n\nBabbling a thanks, you let go of your white-knuckle grip on the sheets and, eager but mindful of her comfort, you reach up and maul at Lane’s generous bust while you restart your thrusting into her with renewed vigor. Their texture is unlike any other sets of boobs you’ve held before – arguably even smoother than a human’s skin. While they’re obviously fake, they look and feel as every bit real as an all-natural pair. She lets out a deep breath as your fingers press and mold her skin, and she thrusts her chest forward, letting you get a better grip on them.");

		outputText("\n\nLane continues to bounce on your lap, reveling in the sensations of your hands on her tits, your [pc.cock " + selCock +"] in her honeypot, and you being under her thrall, obeying and enjoying her every command.");
		if (pc.balls > 0) outputText(" Your [pc.sack] bounds up with every thrust you make, slapping lightly onto Lane’s pert, warm ass, and you love the way her scales caress them.");
		outputText(" Lane’s long, dexterous tail snakes down between you, sliding");
		if (pc.balls > 0) outputText(" between the crease of your [pc.balls]");
		else outputText(" over your perineum");
		outputText(", in search of something to entertain it;");
		if (!pc.hasVagina()) outputText(" despite its groping and feeling, it finds nothing, and you can hear Lane click her tongue in disappointment.");
		else outputText(" it finds the vulva of your [pc.oneVagina] and, without hesitation, begins sliding between your lips relentlessly, rubbing over your [pc.clit] and pressing its silky-smooth scales against you, but Lane doesn’t penetrate you, which frustrates you into fucking her harder.");
		outputText(" With its surplus length, her tail continues onward, wrapping the rest of itself around the fat of your thigh, for equal parts stability and sensuality.");

		outputText("\n\nLane pants as she ruts against you, slapping her hips on top of yours and claiming you in the most physical way she can, and you love every second of it. The pulses of light under her skin grow in frequency and intensity, along with her gasps of pleasure. Her hands drop from behind her head and slam onto your chest");
		if (pc.biggestTitSize() <= 5) outputText(", harmlessly palming at your [pc.chest]");
		else outputText(", squeezing at the flesh of your [pc.chest] and biting her claws into you");
		outputText(". Her bouncing picks up the pace until she’s fucking you hard enough to cause your pelvis to bruise, but you’re okay with that.");

		outputText("\n\nHer voice rises in her throat through pursed lips. You move your hands from her pillowy tits to her thighs, gripping onto the scratchy scales. Her tail tightens on your thigh");
		if (pc.hasVagina()) outputText(" and continues to glide the soft underside of its scales against your [pc.vagina]");
		outputText(" in her coming ecstasy: her fucking is becoming more forceful and less focused. She leans down, her face close to yours, her body pressed on you tight; her cunt grips and sucks on your [pc.cock " + selCock +"] hungrily, coaxing your [pc.cum] from you, and as an incentive, she wails out loud and orgasms on you, dressing your dick in her warm girlcum.");

		outputText("\n\nPart because of your own stimulation, and part seeing your wonderful mistress come to orgasm because of you, you cum yourself, finally.");
		if (pc.cumQ() < 350) outputText(" You thrust in as deep as you can, feeling your cum jet its way up your shaft and coat Lane’s insides. You feel each individual, warm shot seep from you and into her, all while her vagina works in waves to drink it deeper inside herself. Lane sighs in satisfaction as you seed her and humps against you a few more times to lure as much out of you as she can.");
		else if (pc.cumQ() < 1000) outputText(" Your dick inflates with your seed and punches forth with some force, immediately painting Lane’s muscles white as her vagina works to suck it into her abdomen. Lane doesn’t expect the volume of your load, but from the way she laughs in delight, she more than enjoys the feel of her thirsty cunt quenching its hefty thirst. She humps against you twice more, but, after a few seconds pass and your orgasm doesn’t ebb, she goes slack and relaxes, figuring she doesn’t need to work for any more.");
		else outputText(" Your prodigious load of [pc.cum] detonates inside Lane like a stick of dynamite. She has some difficulty registering the absurd volume of cum your pumping into her; even in her own orgasm, her cunt can’t keep up with your cock, and despite her genitals’ every effort, your seed spills back out from between you two. With every pulse of your seed that splatters out from her, you deposit a new wave inside her, making sure you never leave her wanting for your cum. You’ve lost count of how many ropes of jizz you cum into her before she pulls from you in defeat, releasing your [pc.cock " + selCock +"] to the cold air to rain the rest of your load onto the small of her back.");

		if (pc.hasVagina())
		{
			outputText("\n\nThe way Lane’s tail tightens and grinds against you and your feminine bits in her throes of passion is a little uncomfortable, but that doesn’t stop the torrent that gushes from your [pc.vagina] in time with its lucky brother");
			if (pc.cocks.length >= 2) outputText("s");
			outputText(". Your feminine orgasm isn’t nearly as intense as your masculine one, but it’s nonetheless enough to make you go just a little cross-eyed.");
		}

		outputText("\n\nLane rests her body on top of yours for a moment. Her every heavy, satiated gasp comes as music to your ears.");
		if (pc.cumQ() >= 1000)
		{
			outputText(" The seed that didn’t make it inside Lane drips from where her tail meets her back, then onto you");
			if (pc.balls > 0) outputText("r [pc.sack]");
			outputText(" and from there onto the comforter you’re both laying on.");
		}
		outputText(" The afterglow of your rutting comes to you a little less literally than it does to Lane; her glowing begins to slow and soften as the minutes tick by and she collects herself. Your cock eventually softens");
		if (pc.cumQ() < 1000) outputText(" and slides from Lane’s warm confines");
		outputText(", hanging limp in the comparatively cool air of the hut.");
	}

	// Merge
	outputText("\n\n<i>“You’ve done well, [pc.name],”</i> Lane praises, stroking your [pc.hair] affectionately. <i>“");
	if (pc.biggestCockVolume() <= 32) outputText("Especially with the tools you’ve been given. ");
	outputText("I think making you my personal cum pump was a good idea after all.”</i> You sincerely thank her for her praise, and your hand trails down her body once more, gripping at her scaly ass as well as you can from your angle.");

	outputText("\n\nAfter you’ve copped a good feel, Lane pulls herself off of you. <i>“I’m gonna have to wash up,”</i> she sighs, looking across her body. She hasn’t sweat a drop, naturally, but you’ve more than made up for her particular lack of bodily fluids, and the stink of your love making clings to her scales like glue. You lean on one side, watching her as she goes to one of her dressers, and from it, she pulls out a perfectly identical set of white, airy clothing, like she was wearing before.");

	outputText("\n\n<i>“Here’s the deal, [pc.name].”</i> You sit up and listen to her words rapturously. <i>“From now on, after every twenty-four Terran hours, you will wire me five hundred credits. If you can’t afford it, just wire me what you have. I’ll believe you.”</i> You nod in understanding – you had discussed this with her before. <i>“If you want to get hypnotized, I’ll charge you the regular fee. But, from now on, you’ll have to... pay me a tax. The ‘Give Lane Your Body’ tax. I’ll be taking a little extra from you, physically.”</i> Your [pc.cock] begins to inflate once more as you fantasize it: your very body, belonging to Lane’s every sexy whim.");
	if (pc.biggestCockVolume() <= 32) outputText(" <i>“Hopefully you’ll be... better equipped for when the time comes.”</i>");
	if (pc.biggestCockVolume() > lane.vaginalCapacity() * 0.75) outputText(" <i>“You may want to... look into ‘male reduction’ in the meantime. There can be too much of a good thing, you know.”</i>");

	outputText("\n\nOut of turn, you ask her if there’s any chance of Lane getting pregnant. You admit that you feel you’re a little young to have kids yourself, but if Lane wants any, you’re all for it. <i>“I’ve never heard of a Daynar cross-breeding with a species like yours,”</i> she says, humming in thought, <i>“but there’s no risk of it anyway. JoyCo’s been good to us Daynarians.”</i> You don’t press the subject further. If Lane ever wants kids, you’re sure she’ll tell you.");

	outputText("\n\n<i>“You’re a good pet,”</i> Lane tells you, <i>“but I’m afraid fucking you doesn’t pay my bills. That’s not the sort of business I run, unfortunately. Get dressed, and get out there and make me some money.”</i> And then she just leaves you alone in her room, her clothes still in her arms. That was a little cold, the way she talked to you like a tool, but that’s just one of the many things you like about Lane – she’s focused on what she wants, and when she doesn’t want money for her business, she wants you. Thinking of her as a sort of predator, sexual or otherwise, makes your [pc.cock] stiffen all the more.");

	outputText("\n\nYou take a few more minutes to yourself to calm your newly rising erection. When you’re ready, you move to put your [pc.armor] back on, and when you’re presentable again, you leave her room. Lane is nowhere to be found – the ‘busy’ sign is still on her desk, untouched. You have no idea where she goes to bathe.");

	outputText("\n\nWith nothing (and nobody) else to do in the hut, you leave for the caves of Venar, with a new objective in your life.");

	// Lust reduced to 0 time progresses by 1 hour, place PC one square outside Lane’s Plane
	processTime(60);

	lane.loadInCunt(pc);

	pc.orgasm();
	lane.orgasm();

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function firstTimeLaneFPCFGenderless():void
{
	clearOutput();

	outputText("Lane crawls onto the bed, stalking her way across it and up your body. She moves slowly, dragging her heavy breasts and smooth front scales across your skin in a delicious, electric way that sends alights your senses. Her soft hands map the way for her as she crawls over you and drapes her body over yours; she feels along the fat of your legs and the thick of your [pc.hips], across your belly and over your [pc.chest] until she’s completely on top of you, face-to-face, her snout just centimeters from your [pc.face].");

	outputText("\n\n");
	if (pc.biggestTitSize() <= 5)
	{
		outputText("Her hands gently palm at the heaving flesh of your [pc.chest] as she squirms and grinds her sexy body on yours. You moan out, your eyes locked onto hers the whole time, watching their irises change colors to match the pulsing lights under her skin.");
		if (pc.isLactating()) outputText(" Your [pc.milk] squirts from your [pc.nipples] at her gentle ministrations, soaking her webbed fingers as she squeezes your tits, getting them both nice and soaked in your fluids.");
		outputText(" You gasp in pleasure as she fondles you, and then she strikes, closing the gap between you and assaulting your mouth with hers. You absolutely melt as she directs her tongue over and around yours, making itself at home in your mouth.");
	}
	else
	{
		outputText("Her hands roughly grip onto the supple, generous flesh of your [pc.chest] as she begins to forcefully grind her body on top of yours. You gasp out in both pain and pleasure as she handles you, your eyes locked onto hers, unable to look away from them as they rapidly change colors, off-tempo from the lights under her skin.");
		if (pc.isLactating()) outputText(" Your [pc.milk] shoots from your [pc.nipples] in harsh bursts as Lane roughly grips and plies at your skin, launching a solid foot into the air before raining back down on your titflesh and on Lane’s webbed fingers.");
		outputText(" You moan out again, and Lane takes advantage of your weakness: she launches forward, closing the gap between your faces, and she assaults your vulnerable mouth with hers. Your tongue is dominated by hers as she wrestles it, and before long she has you cowed with her aggressive kiss.");
	}

	outputText("\n\nLane straddles your left thigh, and she’s then fucking herself on you, deliberately keeping her own leg away from your [pc.vagina] to keep you teased. She removes her left hand from your tit and moves it up to your head,");
	if (pc.biggestTitSize() <= 5) outputText(" caressing your cheek lightly");
	else outputText(" clamping onto your scalp roughly");
	outputText(") as she kisses you and rocks against you. You move to warp your own arms and legs over her body, to reciprocate some of her affection, but she slaps at your wrists and kicks at your knees. <i>“I’m in charge”</i> she tells you in a sing-song tone, and then goes right back to dominating your body and your mouth.");

	outputText("\n\nYour breath leaves your nose in heavy gasps from the stimulation you’re receiving, but it’s not nearly going to be enough to make you orgasm, and Lane knows it. Finally, she has her fill of you, and she pulls away for a moment, to catch her own breath for a bit. She looks down at you predatorily, a toothy wry grin on her scaly face; she can see in the reflection of your eyes how into her you are, and the sight of you, underneath her, panting and squirming for a release only she can provide, makes her chuckle.");

	outputText("\n\nYet, she’s not satisfied either. She begins climbing her way forward, only slightly, and presents her own chest to your face. She straddles your waist and continues to rub her now wet cunt across your lower stomach while she sandwiches your face between her scaly boobs.");
	if (pc.biggestTitSize() <= 5) outputText(" She coos out in delight once you, without instruction, begin kissing and licking at her ‘skin’, pleasuring her and appreciating her superior rack as she clearly wants you to. The smoothness and the warmth of her body are positively divine on your face; you wouldn’t mind coming home to this for the rest of your life. The scent of her scales and the light of her blood accompany the taste of her on your tongue, and you find a nirvana you’d never thought you’d encounter before now.");
	else outputText(" She grunts once and uses her hands to squeeze your face between her firm, scaly breasts as much as she can. Your air is cut off and your cheeks are pressed into your face; you can’t manage to open your mouth and worship her body as you’d like to with the way she’s controlling you. She massages her tits, inferior to your own, on your skull; you wish that she’d be just a little less rough with you, so that you’d be able to appreciate her body a little better, but if it’s her wish to be dominant, controlling, and a little abusive, then it’s your wish as well.");

	outputText("\n\nEventually, she tires of smothering you with her boobs as well, and continues her journey up your body. Your vision is assaulted by the silky smooth skin of her front sliding over your [pc.face] and the lights of her blood pulsating in front of you. You stick out your [pc.tongue], letting it draw over her scales as she crawls over you, and she rewards you for it with a soft coo.");

	outputText("\n\nShe eventually places her knees on either side of your head, and, before you, is the treasure you’ve always dreamed of: her glistening alien sex, puffy with arousal, dripping in excitement for you. You lick your lips; you’ve never been more ready for her than you are now.");

	outputText("\n\nBefore she indulges you, she turns her body around so that she’s straddling you reverse-cowgirl. <i>“I’m going to tell you a little something about Daynar anatomy,”</i> she says, rocking her hips from left to right with every other word she says, taunting you with her sex. <i>“A Daynarian’s cunt is very sensitive at the lips.”</i> She drags it across the tip of your nose, and she shudders, anticipating it as much as you are. <i>“It’s so we want our men to keep thrusting. An incentive for fucking. But the real prize is much deeper; just before the womb.”</i>");

	outputText("\n\nA drop of her girl cum drips onto your nose, sliding down it and across your cheek. <i>“That’s where we’re most sensitive. It’s so we want our Daynarian cocks as deep as they can go, so there’s a better chance of getting knocked up.”</i> She shivers, and then finally lowers herself on your face, pressing her against you, and letting you fulfil your purpose in life. <i>“I’m sure you’ll do a fine job, [pc.name]. You won’t disappoint me.”</i>");

	outputText("\n\nThe finality of finding yourself where you want to be – between Lane’s luscious, smooth, thick thighs, your lips against her vulva, the taste of her just an easy lick away – leaves you a little light headed. You feel as though you’ve waited so long to have everything you’ve wanted, and it’s right there. You almost forget to appreciate it.");

	outputText("\n\nYou want to grip onto Lane’s legs for stability, but you remember her earlier instruction, and you force yourself to keep still.");
	if (!pc.hasTongueFlag(GLOBAL.FLAG_LONG) && !pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" You drag the fat of your [pc.tongue] once languidly across her gash, making her shiver in delight and press more of her weight onto you. You respond by pressing your lips to hers tightly, doing your best to not leave any part of her wanting, while you dig as deeply into her as you can. You adore her every taste, scent, and texture – her inner muscles are peculiarly streamlined, designed to pull you deeper into her, and you’re absolutely willing to let them. She coos and laughs in delight at your work, sloppy as it is, but your obvious excitement makes up for it.");
	else if (pc.hasTongueFlag(GLOBAL.FLAG_LONG) && !pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" She hunches forward, hiccupping once, caught off guard by the length of your [pc.tongue]. You slide deeply into her with ease, tickling her more sensitive spots, making her wriggle and coo and reward you by giving you more of her. Every smell in your nose is complimented with every taste on your tongue, and everything is so undeniably Lane. Every thrust you make with your long tongue is met with a contraction in her vagina, with her peculiar muscles rippling inward, trying to pull you deeper into her. You take that as an invitation.");
	else if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE))
	{
		outputText(" Lane doubles over in surprise and immediately starts moaning like a pornstar when your massive [pc.tongue] penetrates her and then some, with more than a little bit to spare. She grinds her vulva onto your face, trying to cram as much of your tongue into her as she can, but you doubt she grasps just how deep you can reach. Her pussy is spasms in delight; her inner walls are peculiarly designed, and with each rippling sensation, her muscles draw more and more of you into her. You gladly acquiesce, and soon her entire vent is crammed with your tongue as it layers into itself again and again, yet with her every pulse she seems determined to have more.");
		// [if {tongues = 2}[pg]Your {tongue2} pleases your mistress’s vulva, licking along its twin around where it meets Lane. {It/they} reaches up, teasing at where her clit would be, and it lazily reaches out, tracing along her genital slit[if {tongue2 is at least ‘long’} and licking along her inner thighs], tasting every delectable, unique taste it can.][if {tongues >= 3}[pg][pc.eachTongue] slithers from your maw, lathering up your mistress’s crotch with their attention, and introducing your world to a myriad of unique and utterly Lane tastes. Lane’s legs twitch with every touch [pc.eachTongue] makes against her genital slit, her inner thighs, around to her ass and up to her bottommost belly, but she laughs in pleasured delight with every one.]");

		outputText("\n\nShe leans forward as you fuck her sex with your mouth. She spreads her legs reflexively, giving you more room to breathe. She keeps her hands on your [pc.chest] to help with her balance, and as you eat her, she returns some of the favor.");
		if (pc.hasFuckableNipples()) outputText(" Her palms land directly on your [pc.nipples], making you gasp out in pleasure as your... alternative orifices receive some unexpected stimulation. Lane seems completely oblivious, lost in her own pleasure, but with every hump she makes on your head, her hands crudely massage your [pc.nipples] some more, and you shiver in bliss each time.\n\n");
		else if (pc.hasNippleCocks()) outputText(" Her webbed fingers brush crudely against the shafts of your hard, erect [pc.nipples], causing them to bob and sway in the heated air between you, longing for some attention. Even in her passionate rutting against you, she thinks to give jack them several times, making sure you know that every part of you is always on her mind. Your chest heaves with the stimulation, but, teasingly, she lets them both go, leaving you whimpering for more.\n\n");
		if (pc.biggestTitSize() <= 5) outputText(" Every time your [pc.tongue] lashes into her, she responds by pulling and squeezing at your [pc.chest], rhythmic with your own actions. She’s inconsistent – sometimes she presses down too hard, sometimes she squeezes too strongly – but her effort is nonetheless there and you love her all the more for her consideration.");
		else outputText(" Your every ministration with your [pc.tongue] is met by a rough squeeze or a heavy press on your [pc.chest], and a thrust of her cunny harder onto your face. Her claws dig into your skin, scratching you painfully, but you know it’s only because she can’t control herself with what you’re doing to her, and you consider it a compliment. You almost hope she leave scars, as proof of your skill and her admiration.");
		if (pc.isLactating())
		{
			outputText("\n\nHer");
			if (pc.biggestTitSize() <= 5) outputText(" massaging");
			else outputText(" groping");
			outputText(" eventually teases the [pc.milk] out of your [pc.chest], spraying softly from your nipples and washing onto Lane’s scaly hands and wrists. Your torso becomes cool with the liquid washing down your body, and Lane’s grip becomes slippery on your tits, forcing her to readjust on your body every time, forcing you to spray more of your milk into the air. It’s an awkward but nonetheless pleasurable cycle, especially as it helps relieve the stress in your boobs.");
		}

		outputText("\n\nYou feel your chest beginning to burn slightly as Lane rides you and refuses to let you go to breathe. The muscles in her cunt ripple again and again, and with each pass, it draws your [pc.tongue] ever deeper into her snatch. She’s quickly running out of space to cram you into, and you’re not even halfway out of tongue to give her. <i>“No way am I giving this up,”</i> you hear her say, and she bears down on you harder, squashing you into her bed and flooding your mouth with more of her cunt.");

		outputText("\n\n<i>“But I am not an unfair mistress,”</i> she declares to you, and you feel her shift her weight forward, so that she’s lying atop you properly without removing her quim from your patient mouth. <i>“Keep pleasuring your mistress, [pc.name],”</i> she instructs, and without warning, you feel her press her own mouth to your crotch,");
		if (pc.hasVagina()) outputText(" digging herself daintily into your [pc.vagina], not nearly as enthusiastic as you – acting as though it’s more of a service than a pleasure");
		else outputText(" licking along the [pc.skinfurScales] of your void pelvis, not really with any goal or purpose");
		outputText(" while her hands wrap around your [pc.hips] and roughly grip onto your [pc.ass] for support.");

		outputText("\n\nYou redouble your efforts, stimulated by the pleasure and attention your mistress is giving you. Your tongue is so long that you don’t need to crane your head at all to slather it all over her gash and taste her every inch, but you do so anyway, pressing your lips against her genital slit, putting them back where they belong.");

		outputText("\n\nLane’s ministrations on you feel lazy and unguided, but it’s the thought that counts, and the feel of her warm scales sliding fully over your body are pleasurable enough. Your tongue slides from your mouth constantly; the inches queue up at her twat as she flexes and writhes above you in an effort to cram more into her. With every flex of her cunt, you get in a little bit more, but it’s becoming more and more difficult. She, however, is perfectly content to keep trying.");

		outputText("\n\nYou sixty-nine for only a minute or two before Lane pulls her mouth from your");
		if (pc.hasVagina()) outputText(" [pc.vagina]");
		else outputText(" crotch");
		outputText(". <i>“[pc.name] – ah!”</i> she stutters, just as you slide in another few centimeters. <i>“Exactly how much tongue do you – uh... – do you have?”</i> Her voice accents with every rock of her hips on your face.");

		outputText("\n\n<i>“Ahm nuh sthur, mithpreth,”<i> you try and answer. You don’t attempt to withdraw your tongue from the cozy, tasty new home it’s in, though you’re sure she’d get a real kick out of it.");

		outputText("\n\n<i>“Let’s find out.”</i> She shifts her body forward slightly, pulling her lips away from your own, and presses her abdomen down on your [pc.chest]. <i>“Lick as much as you can. Try not to pull out. I might just reward you if you don’t.”</i>");

		outputText("\n\nYou obey her suggestion, and you reach deep within yourself to withdraw as much [pc.tongue] as you can. The feel of your tongue continuously sliding over your teeth, and the way you can taste so many things at once, is still new and alien to you. You marvel at yourself as it just keeps extending, piling out of your mouth in a hurry, and you’re totally in control of how it bends and coils.");

		outputText("\n\nYou set your tongue to work: what isn’t crammed inside your mistress does its damndest to please her outside. The flat of your appendage coils, licks, and slides along the fat of her ass, reaching down to the thick of her thighs, and up to caress the underside of her tail.");
		//[if {tongues >= 2}. There is no part of Lane’s pert ass that escapes [pc.eachTongue] in their adventure to map out her lower body; the taste of her scales is bitter and tart, but it tastes like Lane]. 
		outputText(" The fat of your tongue coils up slides into the crack of her ass, hot-dogging itself in what little cleavage her scaly derriere provides; she tenses in ecstatic pleasure with every rub and grind. You’re not averse to layering your tongue higher until it massages against her rosebud – whatever to pleasure Lane, and from the way she yips in surprise and fucks her hips backward, she finds it very pleasurable.");

		outputText("\n\n<i>“That’s it!”</i> she encourages you, <i>“Lick me everywhere! That’s it, [pc.name]! Let’s see what you got!”</i> You gladly submit and continue to dole out your alien [pc.tongue], wrapping it around her pelvis, all without withdrawing the fifth-or-so bit of tongue still wriggling and plying in her pussy. You coil your obscene length all around her tail, reaching the tip of it and winding all the way back down before you finally start to come to your limit.");
		//[if {tongues >= 2}. Your other tongue[if {tongues >= 3}s] slither[if {tongues = 2}s it’s ][if {tongues >= 3} their] way up Lane’s quivering, outstretched body, tasting along her belly and licking and pressing along the underside of her boobs. She doesn’t tell you to stop – on the contrary, it seems to excite her further].

		outputText("\n\nLane can’t hold her breath for more than a second, with the tricks and feats you’re performing on her. She’s totally forgotten about pleasing you in return, and in truth, so have you, though your arousal still burns persistently. Every time your [pc.tongue] squeezes and slacks around her tail, it draws up and through her asscrack");
		//[if {tongues >= 2} and the other[if {tongues >= 3}s] whip[if {tongues = 2}s] up her body, feeling out her ribs under her skin and playing with her heavy boobs, a whole body’s length away]
		outputText(", pleasuring Lane in the most exotic way she could have imagined.");

		outputText("\n\nShe stutters out words, but none of them are in context; between the breathy laughs as you wrap her in your tongue and the extreme length still squishing inside the walls of her cunt, she’s too off in her own world to make sense of anything. You both fall into a rhythm of delicious rocking, contracting, tasting, and binding, her body only inches from your face yet completely tied up in your own tongue, and it’s not too long until her orgasm rocks her like an earthquake.");

		outputText("\n\nEverything about Lane gets tense and spontaneously stops moving. She yelps out once again, much louder and longer than before, and you feel her pussy tighten around you, and her ass squish the length stuffed between her cheeks. Among the hurricane of tastes on your tongue");
		// [if {tongues >= 2}s]
		outputText(", you taste another; a hot liquid, coating the tip of your [pc.tongue] and pooling around the pile still locked deep inside her, dripping between the cracks and creases, delighting every bud it hits, but not a single drop manages to escape her.");

		outputText("\n\nAfter her one yell, came silence, followed by a single, low groan as her muscles quaked and threatened to give out on her. Her grumbling turns into a long, drawn-out <i> “–yyyyyyyyyes!”</i> Overcome with ‘inspiration,’ she rocks her hips back until she’s sitting squat on your face once more, and then she falls forward, her face on your groin, giving you");
		if (pc.hasVagina()) outputText("r [pc.vagina]");
		outputText(" a long, lascivious lick.");

		outputText("\n\nThe feel of her own tongue on you");
		if (pc.hasVagina()) outputText("r own puffy sex");
		outputText(" reminds you of your own needs in a flash, and the sensations you get from both ends light your very short fuse. With just one more generous, lingering lick from your beloved mistress,");
		if (pc.hasVagina())
		{
			outputText(" you cum like a geyser. You reflexively lift your [pc.hips] off the bedsheet and thrust yourself into her mouth, funneling your [pc.girlcum] onto her tongue without regard for her commands or her desires.");
			if (pc.girlCumType == GLOBAL.FLUID_TYPE_HONEY) outputText(" As Lane registers the taste, the volume, and the viscosity, she ‘mmm’s out in delight and labors over you a moment longer, lapping up your honey willingly.");
			outputText(" You feel the tension melt from your body, starting at your lower spine and spreading to your digits, and you sigh around your heavy, outstretched tongue.");
		}
		else
		{
			outputText(" and, despite your lack of utilities, you feel a type of slow, relenting release – where your body burned, a relaxing cool overtakes you, until it douses the frustration you had been building up since you had lost your gender. You couldn’t adore your mistress any more than you could at that moment – even without a pussy to cum with, she nonetheless brought you to climax, and with such ease!");
		}

		outputText("\n\nShe bucks against your tongue");
		// [if {tongues >= 2}s] 
		outputText(" several more times, drawing out her long orgasm and getting a handful of smaller ones, before her whole body finally goes limp on top of you. It takes some effort and time to disentangle your massive tongue from her body – uncoiling it from her tail, sliding it out of the valley of her ass, and unplugging the stuff crammed into her honeypot, while rolling the massive appendage back into your mouth and down your throat where it belongs. She takes a sharp breath every time you hit a particularly sensitive spot again, and when you withdraw from her cunt, the cum she had built up inside her comes gushing from her, spilling onto your [pc.chest] and pooling around your ribs.");
	}

	// Continue here if tongue is not ‘super long’
	if (!pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE))
	{
		outputText("\n\nYou’re forced to take deep breaths through your nose, the way Lane’s riding you, and as much as you enjoy being beneath your mistress and fulfilling your life’s duty, your breath sputters in relief as she climbs off of you, having something else in mind. <i>“You’re doing so well, [pc.name],”</i> she coos, looking down her chest and belly at you, smiling warmly. Your heart burns with the rest of your chest in delight as she compliments you. <i>“You have a great tongue. But I have something else in mind.”</i>");

		outputText("\n\nYou look on in curiosity as she climbs down your body once again, towards your");
		if (pc.hasVagina()) outputText(" neglected [pc.vagina], which burns with need and arousal but hasn’t had any chance to be a part of the action yet");
		else outputText(" blank crotch, which is frustratingly hot with arousal but has no outlet to vent with");
		outputText(". Moving like a predator stalking prey in the wild, she slithers forward and turns her body until she’s facing you once more, her cunt just hair’s breadth from");
		if (!pc.hasVagina()) outputText(" where");
		outputText(" yours");
		if (!pc.hasVagina()) outputText(" would be");
		outputText(".");

		outputText("\n\n");
		if (pc.isNaga()) outputText("She straddles your open waist");
		else outputText(" She hooks her right hand underneath your left leg and hoists it above her shoulder, pressing you into the bamboo position beneath her, and straddles your waist");
		outputText(". Her pussy is just above yours, pressed against the bone of your pelvis, her body heat <i>just</i> stimulating your clitoris. You pant, her taste still on your tongue, as you watch her rapturously, waiting for her to fuck you the way only a");
		if (pc.hasVagina()) outputText("nother");
		outputText(" woman could. The lights emanating from her body provide some relief, but your lust can’t be ignored.");

		outputText("\n\n<i>“This will make you mine forever,”</i> she tells you, not as a warning but as a statement, and you welcome the finality. She grinds her way backward, pressing her pussy against your");
		if (pc.hasVagina()) outputText(" [pc.vagina]");
		else outputText(" crotch");
		outputText(", and with that simple motion, your body is rocked with fire and lightning, knowing that your beautiful mistress has finally claimed you in the most physical way a woman can.");

		outputText("\n\n");
		if (!pc.isNaga()) outputText("Lane’s hand slaps down onto your exposed [pc.ass] cheek as s");
		else outputText("S");
		outputText("he begins fucking you in earnest. She’s not gentle as she moves and presses her pussy against your");
		if (pc.hasVagina()) outputText("s");
		else outputText(" crotch");
		outputText(", sliding her vulva over");
		if (pc.hasVagina()) outputText(" and between yours");
		else outputText(" your flat skin");
		outputText(", kissing your lips with hers. Her passion comes out as force; her hands grip onto your skin tightly for leverage as she claims you.");

		outputText("\n\nYou grip onto the bedsheets as best as you can for your own support, but your hands feel weak. Your body goes stiff as Lane viciously scissors you. You look up at her as she pants down at you with every rock of her tight body against yours – the way she grins and breathes and moves just looks so <i>right</i> to you, especially where you are. Her cunt feels electrifying on you, and you’ve never felt quite as alive as you are now, fulfilling your life’s dream of being fucked by Lane. The sweat starts building up on your body, rolling off in rivulets, but Lane’s body remains clean and clear through the whole ordeal.");

		outputText("\n\n<i>“That’s gooooood~”</i> Lane moans out, her voice rocked and stuttered with her every movement against you. You agree, without as many words. You feel the comforter of the bed scrunch up around your back as she forces your body across it while she fucks you, pounding you into her mattress with the whole weight of her body. Your whole body feels like it’s on fire");
		if (!pc.isNaga()) outputText(" – you’ve lost the feeling in your left leg, but you hardly care.");

		if (pc.hasVagina())
		{
			outputText("\n\nYou didn’t realize just how aroused you were until Lane started giving your [pc.vagina] what it wanted. As happy and thrilled as you were to service her, she hadn’t returned the favor at all until now. You’re seeing stars and swirls, and not just in Lane’s tassels; your hands itch to grip onto her thighs, to feel her as much as you can, but you’re a good girl, and you won’t disobey.");
		}
		else
		{
			outputText("\n\nYou loved servicing Lane, and you love that she’s generous enough to attempt to return the favor, but all it does is make your arousal all the more frustrating. Your damnable lack of features builds your lust up to intolerable levels, and her every pitch against you is like a velvet prison: there’s no escaping the torturous pleasure Lane is giving you.");
		}
		if (pc.tailType != 0)
		{
			outputText(" Your [pc.tail] lashes underneath you both, sprawled out and hanging off the side of the bed. Lane wraps her own tail around it twice for stability, and squeezes hard.");
			if (pc.hasTailCunt())
			{
				outputText(" Your [pc.tailCunt] pulses with your excited heart, puffy with need and without something to please it.");
				if (!pc.hasVagina()) outputText(" You grunt in despair that your only outlet of relief isn’t getting any attention at all.");
				outputText(" Another squeeze from Lane’s strong tail rushes your blood to the vulva of your [pc.tailCunt], making it sting, and you bite your lips in an effort to keep from yelping.");
			}
			else if (pc.hasTailCock())
			{
				outputText(" Your [pc.tailCock] is painfully hard, the tip of it purple and swollen, leaking your [pc.cum] onto the floor beneath you, itself begging to be a part of the action somehow.");
				if (!pc.hasVagina()) outputText(" You moan in displeasure as your only outlet of release is completely ignored.");
				outputText(" Another strong squeeze from Lane’s tail inflates the head of your [pc.tailCock] even more, making it sting and even cutting off the flow of your precum.");
			}
		}

		outputText("\n\nLane’s breathing grows heavier and her motions become unfocused but intense, and you know she’s close. Her pleasured moans turn to quiet barks the more she moves until she can’t take any more: she leans back and thrusts her chest out, and you feel a warm liquid begin mingling with your own lustful juices, running down your [pc.vagina] and pooling underneath your");
		if (!pc.isNaga()) outputText(" [pc.ass]");
		else outputText(" body");
		outputText(". She stops her rocking against you selfishly while she climaxes,");
		if (pc.hasVagina())
		{
			outputText(" but luckily for you, your own is hot on her heels, and the feeling and the sight of having your mistress on top of you, pleasing herself with you, and releasing on you, pushes you over the edge. Your eyes practically roll into your head while your pussy convulses with Lane’s, letting your [pc.girlcum] flow from your box and mix and mingle with hers.");
			if (pc.isSquirter()) outputText(" You orgasm with such intensity that it shoots from your happy [pc.vagina], smashing into Lane’s and reaching as high as her lower stomach with some force.");
			outputText(" You cum twice more, so elated are you that you’ve finally cum with your mistress.");
		}
		else
		{
			outputText(" much to your pain and chagrin, but seeing Lane, in all her power and beauty, climaxing on top of you and flooding your crotch with her girl cum, unlocks something within you, and you remember, for a moment, what it was like to climax before you had lost your genitals. You spasm and climax a little awkwardly, but the release is nonetheless present, and you sigh in delight – your wonderful mistress had made you orgasm despite your features!");
		}

		outputText("\n\nShe doesn’t stop her fucking against you, but each buck is far less pronounced, and she’s mostly just riding out the aftermath of her orgasm. You’re more than content to join her, thrusting your [pc.hips] up to meet each press she makes against you. Minutes pass before you both calm down; you catch your breath and wipe the sweat from your brow, while the constant pulsing from Lane’s body begins to slow and regulate.");
	}

	// Merge
	outputText("\n\nYou lie on the bed, stewing in a mixture of your juices, embracing the literal afterglow of the heavy");
	if (pc.hasVagina()) outputText(" lesbian");
	outputText(" sex with your mistress. Among the lights and swirls of her body, you see stars and lines, and your lazy eyes focus on a single point on the ceiling above you as you come down.");

	outputText("\n\nLane, however, is much quicker on the draw. Once she catches her breath, she pulls herself off of you, leaving you on her bed. <i>“That was something else, [pc.name],”</i> she says softly, lowering her face close to yours. You habitually focus on her eyes, and you grin like a child with a toy when she changes their color for you like magic.");

	outputText("\n\nShe strokes along your [pc.hair] affectionately. <i>“You’re gonna need a shower,”</i> she remarks. <i>“You smell like a horny Daynar. You wouldn’t make it ten meters out in the deserts of Venar with this stench on you. Unless you don’t mind the stink of your mistress on you all the time.”</i> You’re tempted to tell her that you wouldn’t, but you’re actually not certain if that’s what she’s hinting you do.");

	outputText("\n\n<i>“You did very well, [pc.name],”</i> she praises as she turns away, towards one of her dressers on the far wall. From its drawers, she pulls out a fresh set of her airy, light clothing, precisely identical to her previous outfit. Once the crease of her ass vanishes beneath her thick undergarment, you resign that you’re not going to get any more out of her right now. <i>“I think I’ve made a good decision on making you my personal sex toy, don’t you?”</i> You agree with her wholeheartedly; you’ve never been so sincere before. You’d do anything if it meant being with Lane and providing her pleasure.");

	outputText("\n\n<i>“Here’s what’s going to happen.”</i> You roll over and sit up, peeling yourself from her bedsheets as you listen to her rapturously. <i>“From now on, after every twenty-four Terran hours, you will wire me five hundred credits. If you can’t afford it, just send me what you can. I’ll believe you. You wouldn’t lie to me.”</i> You nod your head – your earlier discussion still fresh in your memory. <i>“If you want to get hypnotized again, I’ll charge you the regular fee, but from now on, you’re... I’m going to tax you for it. It’s called the ‘Give Lane Your Body Tax.’ You’ll be giving something a little extra back to me for my service.”</i> You lick your [pc.lips]");
	if (pc.hasVagina()) outputText(" and your [pc.vagina] gets a little moist all over again");
	outputText(" at the very thought of it.");
	if (pc.hasTongueFlag(GLOBAL.FLAG_PREHENSILE)) outputText(" <i>“Whatever you took to make your tongue so long and talented, [pc.name]... I wouldn’t mind if you took a little more.”</i>");

	outputText("\n\n<i>“Now then.”</i> When she’s finished, she stands before you, fully dressed and looking almost no different from when you had walked into her hut just an hour ago. <i>“As cute as you are, and as much as I wouldn’t mind going again, I’m afraid fucking my new property doesn’t pay the bills. Get out there and make me some money.”</i> And, without another word, she leaves the room, leaving you naked and soaked in a variety of juices. That was a little harsh, the way she talked to you like you were a tool in her toolbox, but in a way, that sort of attitude is what makes Lane so attractive to you – the way she’s focused on what she wants, like a predator, and when she’s done with it, she leaves it for her next target.");

	outputText("\n\nYou peel yourself from her bed and gather your belongings. Once your fully dressed once more, you leave her room, walking your way back through her ‘office.’ She’s found something to entertain her in her codex, and she barely even looks at you as you leave.");

	// Lust reduced to 0, time progresses by 1 hour, place PC one square outside Lane’s Plane
	processTime(60);

	pc.orgasm();
	lane.orgasm();

	clearMenu();
	addButton(0, "Next", move, ERROR);
}

function lanesAppearance():void
{
	clearOutput();

	if (lane.mf("m", "f") == "m")
	{
		outputText("You sit across from Lane, on the opposite side of his table. He has a warm, disarming smile on his Daynarian face.");

		outputText("\n\nHe is just shy of 182cm tall, which, as you understand, is slightly above-average for Daynarians. He is covered in a layer of fine, brown scales, each of them meticulously groomed, going from the top of his head, to the tips of his shoulders, to, presumably, the base of his tail. The front of her body is very light brown skin, undeniably different from the scales going across her back: soft and smooth to the touch. He looks at you with calm, brown eyes – but sometimes, when you’re not looking right at them, he changes their colour, just to mess with your head. He is slouched forward, his elbows on his table, resting his broad jaw on the back of his four-‘fingered’ hands. Each of them is webbed between the joints of his fingers.");

		outputText("\n\nHis form is slender and not especially masculine, but his chest is just a little thicker around the ribs; one of the few hints of the gender dimorphism of his species. His arms are a little thick around where the biceps: it looks like Lane works out a little on his off-time. Adorned across his torso is a light, thin, airy shirt, clinging dutifully to his form but is designed to be removed in an instant. The material is practically see-through, although his chest and belly are completely featureless, lacking a belly-button and pecs and even nipples. Though you don’t see him stand too often, you know his pants are woven of the same material: light and breezy. They do not hide the pitch-white underwear covering what the rest of his clothes do not. Although you have to beg the question why he might want pants that are designed to be removed in a hurry....");

		outputText("\n\nAttaching his shoulders to his neck are a pair of membranes on either side of his head. The Daynarians call them ‘tassels’, if you remember correctly. Lane’s tassels are currently closed and pressed against the skin of his neck, but they can flare open whenever he wants them to. His tassels are adorned with inks of all colours and intensities, painting swirls and patterns on his skin, and clinging to the tassels are all manner of piercings, each glinting in the light of his little hut.");

		outputText("\n\nThe most mesmerizing thing about Lane is a rather unique feature that only the Daynarians have: their blood is naturally luminescent. All throughout Lane’s body, you can see his blood course: it’s easiest to see in his wrists and in his tassels, but it’s visible all over his body, from the thick of his chest to the thin of his cheeks. The luminescent blood lights a warm red with every beat of his heart, and on every rest, different veins map out a different route on his body with a calm, pale blue. The blood flowing through his tassels compliment his tattoos and his piercings exquisitely: you could just sit there and watch the glowing patterns for hours....");

		if (flags["LANE_MALE_SEXED"] != undefined) outputText("\n\n“You remember Lane’s equipment rather clearly. Between the crease of his legs is a genital slit roughly 7cm long, concealing a smooth, tapered Daynarian tool that’s 24cm in length when fully aroused. When you first get it to flop out of his slit, it’s only 6cm across, but the longer you go and the hornier he gets, it inflates to a girth twice that size. His dick has a pointed tip and has almost no distinguishing features: the typical Daynarian penis has thick skin that hides the veins, although the excited pulsing of his blood is still barely visible. You also know that, unlike most species, he’s the most sensitive at the base rather than the tip.”");
	}
	else
	{
		outputText("You sit across from Lane, on the opposite side of her table. She has a warm, disarming smile on her Daynarian face.");

		outputText("\n\nShe is just shy of 179cm tall, which, as you understand, is slightly above-average for Daynarians. She is covered in a layer of fine, brown scales, each of them meticulously groomed, going from the top of her head, to the tips of her shoulders, to, presumably, the base of her tail. The front of her body is very light brown skin, undeniably different from the scales going across her back: soft and smooth to the touch. She looks at you with calm, brown eyes – but sometimes, when you’re not looking right at them, she changes their colour, just to mess with your head. She is slouched forward, her elbows on her table, resting her long, angular jaw on the back of her four-‘fingered’ hands. Each of them is webbed between the joints of her fingers.");

		outputText("\n\nHer form is slender and not especially feminine, but her hips are just a little wider; one of the few hints of the gender dimorphism of her species. Adorned across her torso is a light, thin, airy shirt, clinging dutifully to her form but is designed to be removed in an instant. The material is practically see-through, and is cut to give Lane rather generous cleavage down her DD-cupped breasts – you understand that female Daynarians don’t usually have breasts at all, and having the means to purchase them is considered a status symbol among the species. Besides that, however, she has no nipples at all, although the fabric of her cloth would have done nothing to hide them. Her stomach, besides having no belly-button, is really rather toned, and you see a faint hint of a respectable four-pack of abs: it looks as though Lane likes to work out a little on her off time. Though you don’t see her stand too often, you know her pants are woven of the same material as her shirt: light and breezy. They do not hide the pitch-white underwear covering what the rest of her clothes do not. Although you have to beg the question why she might want pants that are designed to be removed in a hurry....");

		outputText("\n\nAttaching her shoulders to her neck are a pair of membranes on either side of her head. The Daynarians call them ‘tassels’, if you remember correctly. Lane’s tassels are currently closed and pressed against the skin of her neck, but they can flare open whenever she wants them to. Her tassels are adorned with inks of all colours and intensities, painting swirls and patterns on her skin, and clinging to the tassels are all manner of piercings, each glinting in the light of her little hut.");

		outputText("\n\nThe most mesmerizing thing about Lane is a rather unique feature that only the Daynarians have: their blood is naturally luminescent. All throughout Lane’s body, you can see her blood course: it’s easiest to see in her wrists and in her tassels, but it’s visible all over her body, from the thick of her breasts to the thin of her cheeks. The luminescent blood lights a warm red with every beat of her heart, and on every rest, different veins map out a different route on her body with a calm, pale blue. The blood flowing through her tassels compliment her tattoos and her piercings exquisitely: you could just sit there and watch the glowing patterns for hours....");

		if (flags["LANE_FEMALE_SEXED"] != undefined)
		{
			outputText("\n\n“You remember Lane’s honeypot rather clearly. Between the crease of her legs is a genital slit roughly 7cm long, concealing a hungry, wet vagina, with streamlined muscles adorning a narrow tunnel, designed to pull you deeper into her. She has no clitoris, unlike most other species you’ve encountered. The lips of her cunny are among the most sensitive part of her genitals, although the real prize, for her, is reaching as deep inside with whatever you can as possible. Her genital slit is not actually a part of her genitals, and is stubborn to move when she’s not in the mood, but are spongy and pliable when she is.”");
		}
	}

	addDisabledButton(5, "Appearance");
}