/datum/species/golem
	// Animated beings of stone. They have increased defenses, and do not need to breathe. They're also slow as fuuuck. no need eat
	name = "Golem"
	id = "iron golem"
	species_traits = list(NOBLOOD,MUTCOLORS,NO_UNDERWEAR, NO_DNA_COPY, NOTRANSSTING, NOHUSK)
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER,TRAIT_NOGUNS)
	inherent_biotypes = MOB_INORGANIC|MOB_HUMANOID
	mutant_organs = list(/obj/item/organ/adamantine_resonator)
	speedmod = 2
	armor = 55
	siemens_coeff = 0
	punchdamagelow = 5
	punchdamagehigh = 14
	punchstunchance = 0.4 //40% chance to stun
	no_equip = list(ITEM_SLOT_MASK, ITEM_SLOT_OCLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_ICLOTHING, ITEM_SLOT_SUITSTORE)
	nojumpsuit = 1
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC
	possible_genders = list(MALE, PLURAL, FEMALE)
	damage_overlay_type = ""
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/golem
	// To prevent golem subtypes from overwhelming the odds when random species
	// changes, only the Random Golem type can be chosen
	limbs_id = "golem"
	fixed_mut_color = "#aaaaaa"
	swimming_component = /datum/component/swimming/golem
	var/info_text = "As an <span class='danger'>Iron Golem</span>, you don't have any special traits."
	var/random_eligible = TRUE //If false, the golem subtype can't be made through golem mutation toxin

	var/prefix = "Iron"
	var/list/special_names = list("Tarkus")
	var/human_surname_chance = 3
	var/special_name_chance = 5
	var/owner //dobby is a free golem
	/// From the moment that they become a servant golem, how much time must pass before they can do it again? Given on ghost & death. Nullable.
	var/ghost_cooldown = 15 MINUTES // Iron golem is the base.

/datum/species/golem/random_name(gender,unique,lastname)
	var/golem_surname = pick(GLOB.golem_names)
	// 3% chance that our golem has a human surname, because
	// cultural contamination
	if(prob(human_surname_chance))
		golem_surname = pick(GLOB.last_names)
	else if(special_names && special_names.len && prob(special_name_chance))
		golem_surname = pick(special_names)

	var/golem_name = "[prefix] [golem_surname]"
	return golem_name

/datum/species/golem/create_pref_unique_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = "gem",
		SPECIES_PERK_NAME = "Lithoid",
		SPECIES_PERK_DESC = "Lithoids are creatures made out of elements instead of \
			blood and flesh. Because of this, they're generally stronger, slower, \
			and mostly immune to environmental dangers and dangers to their health, \
			such as viruses and dismemberment.",
	))

	return to_add

/datum/species/golem/spec_death(gibbed, mob/living/carbon/human/H)
	if(owner && H.ckey && H.ckey[1] != "@") // Servant golem with an non-adminghosted ckey.
		GLOB.servant_golem_users[H.ckey] = world.time + (ghost_cooldown ? ghost_cooldown : 0)
	..()

/datum/species/golem/random
	name = "Random Golem"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN
	var/static/list/random_golem_types

/datum/species/golem/random/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(!random_golem_types)
		random_golem_types = subtypesof(/datum/species/golem) - type
		for(var/V in random_golem_types)
			var/datum/species/golem/G = V
			if(!initial(G.random_eligible))
				random_golem_types -= G
	var/datum/species/golem/golem_type = pick(random_golem_types)
	var/mob/living/carbon/human/H = C
	H.set_species(golem_type)
	to_chat(H, "[initial(golem_type.info_text)]")

/datum/species/golem/adamantine
	name = "Adamantine Golem"
	id = "adamantine golem"
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/golem/adamantine
	mutant_organs = list(/obj/item/organ/adamantine_resonator, /obj/item/organ/vocal_cords/adamantine)
	fixed_mut_color = "#44eedd"
	info_text = "As an <span class='danger'>Adamantine Golem</span>, you possess special vocal cords allowing you to \"resonate\" messages to all golems. Your unique mineral makeup makes you immune to most types of magic."
	prefix = "Adamantine"
	special_names = null
	ghost_cooldown = 18 MINUTES

/datum/species/golem/adamantine/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	ADD_TRAIT(C, TRAIT_ANTIMAGIC, SPECIES_TRAIT)

/datum/species/golem/adamantine/on_species_loss(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_ANTIMAGIC, SPECIES_TRAIT)
	..()

//The suicide bombers of golemkind
/datum/species/golem/plasma
	name = "Plasma Golem"
	id = "plasma golem"
	fixed_mut_color = "#aa33dd"
	meat = /obj/item/stack/ore/plasma
	//Can burn and takes damage from heat
	inherent_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER) //no RESISTHEAT, NOFIRE
	info_text = "As a <span class='danger'>Plasma Golem</span>, you burn easily. Be careful, if you get hot enough while burning, you'll blow up!"
	heatmod = 0 //fine until they blow up
	prefix = "Plasma"
	special_names = list("Flood","Fire","Bar","Man")
	var/boom_warning = FALSE
	var/datum/action/innate/ignite/ignite
	ghost_cooldown = 10 MINUTES // Their gimmick is to explode. Exploding (and dying) is an important part of the species.

/datum/species/golem/plasma/spec_life(mob/living/carbon/human/H)
	if(H.bodytemperature > 750)
		if(!boom_warning && H.on_fire)
			to_chat(H, span_userdanger("You feel like you could blow up at any moment!"))
			boom_warning = TRUE
	else
		if(boom_warning)
			to_chat(H, span_notice("You feel more stable."))
			boom_warning = FALSE

	if(H.bodytemperature > 850 && H.on_fire && prob(25))
		explosion(get_turf(H),1,2,4,flame_range = 5)
		if(H)
			H.gib()
	if(H.fire_stacks < 2) //flammable
		H.adjust_fire_stacks(1)
	..()

/datum/species/golem/plasma/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(ishuman(C))
		ignite = new
		ignite.Grant(C)

/datum/species/golem/plasma/on_species_loss(mob/living/carbon/C)
	if(ignite)
		ignite.Remove(C)
	..()

/datum/action/innate/ignite
	name = "Ignite"
	desc = "Set yourself aflame, bringing yourself closer to exploding!"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "sacredflame"

/datum/action/innate/ignite/Activate()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.fire_stacks)
			to_chat(owner, span_notice("You ignite yourself!"))
		else
			to_chat(owner, span_warning("You try to ignite yourself, but fail!"))
		H.ignite_mob() //firestacks are already there passively

//Harder to hurt
/datum/species/golem/diamond
	name = "Diamond Golem"
	id = "diamond golem"
	limbs_id = "cr_golem"
	fixed_mut_color = "#00ffff"
	armor = 70 //up from 55
	meat = /obj/item/stack/ore/diamond
	info_text = "As a <span class='danger'>Diamond Golem</span>, you are more resistant than the average golem."
	prefix = "Diamond"
	special_names = list("Back","Grill")
	ghost_cooldown = 25 MINUTES // Objectively better than iron golems.

//Faster but softer and less armoured
/datum/species/golem/gold
	name = "Gold Golem"
	id = "gold golem"
	fixed_mut_color = "#cccc00"
	speedmod = 1
	armor = 25 //down from 55
	meat = /obj/item/stack/ore/gold
	info_text = "As a <span class='danger'>Gold Golem</span>, you are faster but less resistant than the average golem."
	prefix = "Golden"
	special_names = list("Boy")
	ghost_cooldown = 15 MINUTES // Trade armor for speed. Should be fine to be equal as iron.

//Heavier, thus higher chance of stunning when punching
/datum/species/golem/silver
	name = "Silver Golem"
	id = "silver golem"
	fixed_mut_color = "#dddddd"
	punchstunchance = 0.6 //60% chance, from 40%
	meat = /obj/item/stack/ore/silver
	info_text = "As a <span class='danger'>Silver Golem</span>, your attacks have a higher chance of stunning. Being made of silver, your body is immune to most types of magic."
	prefix = "Silver"
	special_names = list("Surfer", "Chariot", "Lining")
	ghost_cooldown = 20 MINUTES // Objectively better than iron golems.

/datum/species/golem/silver/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	ADD_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)

/datum/species/golem/silver/on_species_loss(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)
	..()

//Harder to stun, deals more damage, massively slowpokes, but gravproof and obstructive. Basically, The Wall.
/datum/species/golem/plasteel
	name = "Plasteel Golem"
	id = "plasteel golem"
	fixed_mut_color = "#bbbbbb"
	stunmod = 0.4
	punchdamagelow = 12
	punchdamagehigh = 21
	speedmod = 4 //pretty fucking slow
	meat = /obj/item/stack/ore/iron
	info_text = "As a <span class='danger'>Plasteel Golem</span>, you are slower, but harder to stun, and hit very hard when punching. You also magnetically attach to surfaces and so don't float without gravity and cannot have positions swapped with other beings."
	attack_verbs = list("smash")
	attack_effect = ATTACK_EFFECT_SMASH
	attack_sound = 'sound/effects/meteorimpact.ogg' //hits pretty hard
	prefix = "Plasteel"
	special_names = null
	ghost_cooldown = 30 MINUTES // Massively melee damage, stun reduction, and gravity immunity for permanent walking speed. Not quite as hard to create as plasteel is easier to obtain.

/datum/species/golem/plasteel/negates_gravity(mob/living/carbon/human/H)
	return TRUE

/datum/species/golem/plasteel/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	ADD_TRAIT(C, TRAIT_NOMOBSWAP, SPECIES_TRAIT) //THE WALL THE WALL THE WALL

/datum/species/golem/plasteel/on_species_loss(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_NOMOBSWAP, SPECIES_TRAIT) //NOTHING ON ERF CAN MAKE IT FALL
	..()

//Immune to ash storms
/datum/species/golem/titanium
	name = "Titanium Golem"
	id = "titanium golem"
	fixed_mut_color = "#ffffff"
	meat = /obj/item/stack/ore/titanium
	info_text = "As a <span class='danger'>Titanium Golem</span>, you are immune to ash storms, and slightly more resistant to burn damage."
	burnmod = 0.9
	prefix = "Titanium"
	special_names = list("Dioxide")
	ghost_cooldown = 18 MINUTES // Objectively slightly better than iron golems.

/datum/species/golem/titanium/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.weather_immunities |= WEATHER_ASH

/datum/species/golem/titanium/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.weather_immunities &= ~WEATHER_ASH

//Immune to ash storms and lava
/datum/species/golem/plastitanium
	name = "Plastitanium Golem"
	id = "plastitanium golem"
	fixed_mut_color = "#888888"
	meat = /obj/item/stack/ore/titanium
	info_text = "As a <span class='danger'>Plastitanium Golem</span>, you are immune to both ash storms and lava, and slightly more resistant to burn damage."
	burnmod = 0.8
	prefix = "Plastitanium"
	special_names = null
	ghost_cooldown = 20 MINUTES  // Objectively slightly better than titanium golems.

/datum/species/golem/plastitanium/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.weather_immunities |= WEATHER_LAVA
	C.weather_immunities |= WEATHER_ASH

/datum/species/golem/plastitanium/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.weather_immunities &= ~WEATHER_ASH
	C.weather_immunities &= ~WEATHER_LAVA

//Fast and regenerates... but can only speak like an abductor
/datum/species/golem/alloy
	name = "Alien Alloy Golem"
	id = "alloy golem"
	fixed_mut_color = "#333333"
	meat = /obj/item/stack/sheet/mineral/abductor
	mutanttongue = /obj/item/organ/tongue/abductor
	speedmod = 1 //faster
	info_text = "As an <span class='danger'>Alloy Golem</span>, you are made of advanced alien materials: you are faster and regenerate over time. You are, however, only able to be heard by other alloy golems."
	prefix = "Alien"
	special_names = list("Outsider", "Technology", "Watcher", "Stranger") //ominous and unknown
	ghost_cooldown = 30 MINUTES // Terribly good if you can capitalize on disengaging/not dying.

//Regenerates because self-repairing super-advanced alien tech
/datum/species/golem/alloy/spec_life(mob/living/carbon/human/H)
	if(H.stat == DEAD)
		return
	H.heal_overall_damage(2,2, 0, BODYPART_ORGANIC)
	H.adjustToxLoss(-2)
	H.adjustOxyLoss(-2)

//Since this will usually be created from a collaboration between podpeople and free golems, wood golems are a mix between the two races
/datum/species/golem/wood
	name = "Wood Golem"
	id = "wood golem"
	fixed_mut_color = "#9E704B"
	meat = /obj/item/stack/sheet/mineral/wood
	//Can burn and take damage from heat
	inherent_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	armor = 30
	burnmod = 1.25
	heatmod = 1.5
	info_text = "As a <span class='danger'>Wooden Golem</span>, you have plant-like traits: you take damage from extreme temperatures, can be set on fire, and have lower armor than a normal golem. You regenerate when in the light and wither in the darkness."
	prefix = "Wooden"
	special_names = list("Bark", "Willow", "Catalpa", "Woody", "Oak", "Sap", "Twig", "Branch", "Maple", "Birch", "Elm", "Basswood", "Cottonwood", "Larch", "Aspen", "Ash", "Beech", "Buckeye", "Cedar", "Chestnut", "Cypress", "Fir", "Hawthorn", "Hazel", "Hickory", "Ironwood", "Juniper", "Leaf", "Mangrove", "Palm", "Pawpaw", "Pine", "Poplar", "Redwood", "Redbud", "Sassafras", "Spruce", "Sumac", "Trunk", "Walnut", "Yew")
	human_surname_chance = 0
	special_name_chance = 100
	species_language_holder = /datum/language_holder/pod
	ghost_cooldown = 15 MINUTES // Can't tell if this is worse or better than iron golems.

/datum/species/golem/wood/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.faction |= "plants"
	C.faction |= "vines"

/datum/species/golem/wood/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.faction -= "plants"
	C.faction -= "vines"

/datum/species/golem/wood/spec_life(mob/living/carbon/human/H)
	if(H.stat == DEAD)
		return
	var/light_amount = 0 //how much light there is in the place, affects receiving nutrition and healing
	if(isturf(H.loc)) //else, there's considered to be no light
		var/turf/T = H.loc
		light_amount = min(1,T.get_lumcount()) - 0.5
		H.adjust_nutrition(light_amount * 10)
		if(H.nutrition > NUTRITION_LEVEL_ALMOST_FULL)
			H.set_nutrition(NUTRITION_LEVEL_ALMOST_FULL)
		if(light_amount > LIGHTING_TILE_IS_DARK) //if there's enough light, heal
			H.heal_overall_damage(1,1,0, BODYPART_ORGANIC)
			H.adjustToxLoss(-1)
			H.adjustOxyLoss(-1)

	if(H.nutrition < NUTRITION_LEVEL_STARVING + 50)
		H.take_overall_damage(2,0)

/datum/species/golem/wood/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(chem.type == /datum/reagent/toxin/plantbgone)
		H.adjustToxLoss(3)
		H.reagents.remove_reagent(chem.type, chem.metabolization_rate)
		return TRUE
	return ..()

/datum/species/golem/wood/holy //slightly upgraded wood golem, for the plant sect
	id = "holy wood golem"
	speedmod = 1 //wood golems aren't very good, so the holy ones are slightly faster so that you don't put in a bunch of hardwork to downgrade yourself
	changesource_flags = MIRROR_BADMIN
	random_eligible = FALSE
	ghost_cooldown = null // Adminbus only.

// Radioactive puncher. Punches deal burn instead of brute.
/datum/species/golem/uranium
	name = "Uranium Golem"
	id = "uranium golem"
	fixed_mut_color = "#77ff00"
	meat = /obj/item/stack/ore/uranium
	info_text = "As an <span class='danger'>Uranium Golem</span>, your very touch burns and irradiates organic lifeforms."
	attack_verbs = list("burn")
	attack_sound = 'sound/weapons/sear.ogg'
	attack_type = BURN
	prefix = "Uranium"
	special_names = list("Oxide", "Rod", "Meltdown", "235")
	ghost_cooldown = 20 MINUTES // Damage type is harder to deal with and the risk of getting husking is there too. Radiation is only a problem if you get hit 10+ times.
	COOLDOWN_DECLARE(radiation_emission_cooldown)

/datum/species/golem/uranium/proc/radiation_emission(mob/living/carbon/human/H)
	if(!COOLDOWN_FINISHED(src, radiation_emission_cooldown))
		return
	else
		radiation_pulse(H, 50)
		COOLDOWN_START(src, radiation_emission_cooldown, 2 SECONDS)

/datum/species/golem/uranium/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	var/obj/item/bodypart/affecting = target.get_bodypart(ran_zone(user.zone_selected))
	var/radiation_block = target.run_armor_check(affecting, RAD)
	///standard damage roll for use in determining how much you irradiate per punch
	var/attacker_irradiate_value = rand(user.dna.species.punchdamagelow, user.dna.species.punchdamagehigh)
	target.apply_effect(attacker_irradiate_value*5, EFFECT_IRRADIATE, radiation_block)

/datum/species/golem/uranium/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style, modifiers)
	..()
	if(COOLDOWN_FINISHED(src, radiation_emission_cooldown) && M != H &&  M.combat_mode)
		radiation_emission(H)

/datum/species/golem/uranium/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	..()
	if(COOLDOWN_FINISHED(src, radiation_emission_cooldown) && user != H)
		radiation_emission(H)

/datum/species/golem/uranium/on_hit(obj/projectile/P, mob/living/carbon/human/H)
	..()
	if(COOLDOWN_FINISHED(src, radiation_emission_cooldown))
		radiation_emission(H)

//Immune to physical bullets and resistant to brute, but very vulnerable to burn damage. Dusts on death.
/datum/species/golem/sand
	name = "Sand Golem"
	id = "sand golem"
	fixed_mut_color = "#ffdc8f"
	meat = /obj/item/stack/ore/glass //this is sand
	armor = 0
	burnmod = 3 //melts easily
	brutemod = 0.25
	info_text = "As a <span class='danger'>Sand Golem</span>, you are immune to physical bullets and take very little brute damage, but are extremely vulnerable to burn damage and energy weapons. You will also turn to sand when dying, preventing any form of recovery."
	attack_sound = 'sound/effects/shovel_dig.ogg'
	prefix = "Sand"
	special_names = list("Castle", "Bag", "Dune", "Worm", "Storm")
	ghost_cooldown = 8 MINUTES // Dies first to burns and cannot be revived. Warrants a lower cooldown for that.

/datum/species/golem/sand/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	H.visible_message(span_danger("[H] turns into a pile of sand!"))
	for(var/obj/item/W in H)
		H.dropItemToGround(W)
	for(var/i=1, i <= rand(3,5), i++)
		new /obj/item/stack/ore/glass(get_turf(H))
	qdel(H)

/datum/species/golem/sand/bullet_act(obj/projectile/P, mob/living/carbon/human/H)
	if(!(P.original == H && P.firer == H))
		if(P.armor_flag == BULLET || P.armor_flag == BOMB)
			playsound(H, 'sound/effects/shovel_dig.ogg', 70, 1)
			H.visible_message(span_danger("The [P.name] sinks harmlessly in [H]'s sandy body!"), \
			span_userdanger("The [P.name] sinks harmlessly in [H]'s sandy body!"))
			return BULLET_ACT_BLOCK
	return BULLET_ACT_HIT

//Reflects lasers and resistant to burn damage, but very vulnerable to brute damage. Shatters on death.
/datum/species/golem/glass
	name = "Glass Golem"
	id = "glass golem"
	limbs_id = "cr_golem"
	fixed_mut_color = "#5a96b4aa" //transparent body
	meat = /obj/item/shard
	armor = 0
	brutemod = 3 //very fragile
	burnmod = 0.25
	info_text = "As a <span class='danger'>Glass Golem</span>, you reflect lasers and energy weapons, and are very resistant to burn damage. However, you are extremely vulnerable to brute damage. On death, you'll shatter beyond any hope of recovery."
	attack_sound = 'sound/effects/glassbr2.ogg'
	prefix = "Glass"
	special_names = list("Lens", "Prism", "Fiber", "Bead")
	ghost_cooldown = 8 MINUTES // The opposite verison of sand golems.

/datum/species/golem/glass/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	playsound(H, "shatter", 70, 1)
	H.visible_message(span_danger("[H] shatters!"))
	for(var/obj/item/W in H)
		H.dropItemToGround(W)
	for(var/i=1, i <= rand(3,5), i++)
		new /obj/item/shard(get_turf(H))
	qdel(H)

/datum/species/golem/glass/bullet_act(obj/projectile/P, mob/living/carbon/human/H)
	if(!(P.original == H && P.firer == H)) //self-shots don't reflect
		if(P.armor_flag == LASER || P.armor_flag == ENERGY)
			H.visible_message(span_danger("The [P.name] gets reflected by [H]'s glass skin!"), \
			span_userdanger("The [P.name] gets reflected by [H]'s glass skin!"))
			if(P.starting)
				var/new_x = P.starting.x + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
				var/new_y = P.starting.y + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
				// redirect the projectile
				P.firer = H
				P.preparePixelProjectile(locate(clamp(new_x, 1, world.maxx), clamp(new_y, 1, world.maxy), H.z), H)
			return BULLET_ACT_FORCE_PIERCE
	return ..()

//Teleports when hit or when it wants to
/datum/species/golem/bluespace
	name = "Bluespace Golem"
	id = "bluespace golem"
	limbs_id = "cr_golem"
	fixed_mut_color = "#3333ff"
	meat = /obj/item/stack/ore/bluespace_crystal
	info_text = "As a <span class='danger'>Bluespace Golem</span>, you are spatially unstable: You will teleport when hit, and you can teleport manually at a long distance."
	attack_verbs = list("bluespace punch")
	attack_sound = 'sound/effects/phasein.ogg'
	prefix = "Bluespace"
	special_names = list("Crystal", "Polycrystal")

	var/datum/action/innate/unstable_teleport/unstable_teleport
	var/teleport_cooldown = 100
	var/last_teleport = 0
	ghost_cooldown = 18 MINUTES

/datum/species/golem/bluespace/proc/reactive_teleport(mob/living/carbon/human/H)
	H.visible_message(span_warning("[H] teleports!"), span_danger("You destabilize and teleport!"))
	new /obj/effect/particle_effect/sparks(get_turf(H))
	playsound(get_turf(H), "sparks", 50, 1)
	do_teleport(H, get_turf(H), 6, asoundin = 'sound/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
	last_teleport = world.time

/datum/species/golem/bluespace/spec_hitby(atom/movable/AM, mob/living/carbon/human/H)
	..()
	var/obj/item/I
	if(istype(AM, /obj/item))
		I = AM
		if(I.thrownby == H) //No throwing stuff at yourself to trigger the teleport
			return 0
		else
			reactive_teleport(H)

/datum/species/golem/bluespace/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style, modifiers)
	..()
	if(world.time > last_teleport + teleport_cooldown && M != H &&  M.combat_mode)
		reactive_teleport(H)

/datum/species/golem/bluespace/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	..()
	if(world.time > last_teleport + teleport_cooldown && user != H)
		reactive_teleport(H)

/datum/species/golem/bluespace/on_hit(obj/projectile/P, mob/living/carbon/human/H)
	..()
	if(world.time > last_teleport + teleport_cooldown)
		reactive_teleport(H)

/datum/species/golem/bluespace/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(ishuman(C))
		unstable_teleport = new
		unstable_teleport.Grant(C)
		last_teleport = world.time

/datum/species/golem/bluespace/on_species_loss(mob/living/carbon/C)
	if(unstable_teleport)
		unstable_teleport.Remove(C)
	..()

/datum/action/innate/unstable_teleport
	name = "Unstable Teleport"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "jaunt"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	var/cooldown = 15 SECONDS
	var/last_teleport = 0

/datum/action/innate/unstable_teleport/IsAvailable(feedback = FALSE)
	if(..())
		if(world.time > last_teleport + cooldown)
			return 1
		return 0

/datum/action/innate/unstable_teleport/Activate()
	var/mob/living/carbon/human/H = owner
	H.visible_message(span_warning("[H] starts vibrating!"), span_danger("You start charging your bluespace core..."))
	playsound(get_turf(H), 'sound/weapons/flash.ogg', 25, 1)
	addtimer(CALLBACK(src, PROC_REF(teleport), H), 15)

/datum/action/innate/unstable_teleport/proc/teleport(mob/living/carbon/human/H)
	H.visible_message(span_warning("[H] disappears in a shower of sparks!"), span_danger("You teleport!"))
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(10, 0, src)
	spark_system.attach(H)
	spark_system.start()
	do_teleport(H, get_turf(H), 12, asoundin = 'sound/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
	last_teleport = world.time
	build_all_button_icons() //action icon looks unavailable
	sleep(cooldown + 0.5 SECONDS)
	build_all_button_icons() //action icon looks available again

//honk
/datum/species/golem/bananium
	name = "Bananium Golem"
	id = "bananium golem"
	fixed_mut_color = "#ffff00"
	say_mod = "honks"
	punchdamagelow = 0
	punchdamagehigh = 1
	punchstunchance = 0 //Harmless and can't stun
	meat = /obj/item/stack/ore/bananium
	info_text = "As a <span class='danger'>Bananium Golem</span>, you are made for pranking. Your body emits natural honks, and you can barely even hurt people when punching them. Your skin also bleeds banana peels when damaged."
	attack_verbs = list("honk")
	attack_sound = 'sound/items/airhorn2.ogg'
	prefix = "Bananium"
	special_names = null
	ghost_cooldown = 2 MINUTES // This is for pranking, not for combat.

	var/last_honk = 0
	var/honkooldown = 0
	var/last_banana = 0
	var/banana_cooldown = 100
	var/active = null

/datum/species/golem/bananium/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	last_banana = world.time
	last_honk = world.time
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/datum/species/golem/bananium/on_species_loss(mob/living/carbon/C)
	. = ..()
	UnregisterSignal(C, COMSIG_MOB_SAY)

/datum/species/golem/bananium/random_name(gender,unique,lastname)
	var/clown_name = pick(GLOB.clown_names)
	var/golem_name = "[uppertext(clown_name)]"
	return golem_name

/datum/species/golem/bananium/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style, modifiers)
	..()
	if(world.time > last_banana + banana_cooldown && M != H &&  M.combat_mode)
		new/obj/item/grown/bananapeel/specialpeel(get_turf(H))
		last_banana = world.time

/datum/species/golem/bananium/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	..()
	if(world.time > last_banana + banana_cooldown && user != H)
		new/obj/item/grown/bananapeel/specialpeel(get_turf(H))
		last_banana = world.time

/datum/species/golem/bananium/on_hit(obj/projectile/P, mob/living/carbon/human/H)
	..()
	if(world.time > last_banana + banana_cooldown)
		new/obj/item/grown/bananapeel/specialpeel(get_turf(H))
		last_banana = world.time

/datum/species/golem/bananium/spec_hitby(atom/movable/AM, mob/living/carbon/human/H)
	..()
	var/obj/item/I
	if(istype(AM, /obj/item))
		I = AM
		if(I.thrownby == H) //No throwing stuff at yourself to make bananas
			return 0
		else
			new/obj/item/grown/bananapeel/specialpeel(get_turf(H))
			last_banana = world.time

/datum/species/golem/bananium/spec_life(mob/living/carbon/human/H)
	if(!active)
		if(world.time > last_honk + honkooldown)
			active = 1
			playsound(get_turf(H), 'sound/items/bikehorn.ogg', 50, 1)
			last_honk = world.time
			honkooldown = rand(20, 80)
			active = null
	..()

/datum/species/golem/bananium/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	playsound(get_turf(H), 'sound/misc/sadtrombone.ogg', 70, 0)

/datum/species/golem/bananium/proc/handle_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_CLOWN

/datum/species/golem/runic
	name = "Runic Golem"
	id = "runic golem"
	limbs_id = "cultgolem"
	possible_genders = list(PLURAL)
	info_text = "As a <span class='danger'>Runic Golem</span>, you possess eldritch powers granted by the Elder Goddess Nar'sie."
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK) //no mutcolors
	prefix = "Runic"
	special_names = null
	ghost_cooldown = 20 MINUTES // Objectively better than iron golem (except holy water, but who uses that?) Can be easily obtainable in non-bloodcult rounds.

	/// A ref to our jaunt spell that we get on species gain.
	var/datum/action/cooldown/spell/jaunt/ethereal_jaunt/shift/golem/jaunt
	/// A ref to our gaze spell that we get on species gain.
	var/datum/action/cooldown/spell/pointed/abyssal_gaze/abyssal_gaze
	/// A ref to our dominate spell that we get on species gain.
	var/datum/action/cooldown/spell/pointed/dominate/dominate

/datum/species/golem/runic/random_name(gender,unique,lastname)
	var/edgy_first_name = pick("Razor","Blood","Dark","Evil","Cold","Pale","Black","Silent","Chaos","Deadly","Coldsteel")
	var/edgy_last_name = pick("Edge","Night","Death","Razor","Blade","Steel","Calamity","Twilight","Shadow","Nightmare") //dammit Razor Razor
	var/golem_name = "[edgy_first_name] [edgy_last_name]"
	return golem_name

/datum/species/golem/runic/on_species_gain(mob/living/carbon/grant_to, datum/species/old_species)
	. = ..()
	grant_to.faction |= "cult"
	// Create our species specific spells here.
	// Note we link them to the mob, not the mind,
	// so they're not moved around on mindswaps
	jaunt = new(grant_to)
	jaunt.StartCooldown()
	jaunt.Grant(grant_to)

	abyssal_gaze = new(grant_to)
	abyssal_gaze.StartCooldown()
	abyssal_gaze.Grant(grant_to)

	dominate = new(grant_to)
	dominate.StartCooldown()
	dominate.Grant(grant_to)

/datum/species/golem/runic/on_species_loss(mob/living/carbon/remove_from)
	. = ..()
	remove_from.faction -= "cult"
	// Aaand cleanup our species specific spells.
	// No free rides.
	QDEL_NULL(jaunt)
	QDEL_NULL(abyssal_gaze)
	QDEL_NULL(dominate)
	return ..()

/datum/species/golem/runic/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(istype(chem, /datum/reagent/water/holywater))
		H.adjustFireLoss(4)
		H.reagents.remove_reagent(chem.type, chem.metabolization_rate)
		return TRUE

	if(chem.type == /datum/reagent/fuel/unholywater)
		H.adjustBruteLoss(-4)
		H.adjustFireLoss(-4)
		H.reagents.remove_reagent(chem.type, chem.metabolization_rate)
		return TRUE
	return ..()


/datum/species/golem/clockwork
	name = "Clockwork Golem"
	id = "clockwork golem"
	say_mod = "clicks"
	limbs_id = "clockgolem"
	info_text = "<span class='bold alloy'>As a </span><span class='bold brass'>Clockwork Golem</span><span class='bold alloy'>, you are faster than other types of golems. On death, you will break down into scrap.</span>"
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK)
	armor = 20 //Reinforced, but much less so to allow for fast movement
	attack_verbs = list("smash")
	attack_effect = ATTACK_EFFECT_SMASH
	attack_sound = 'sound/magic/clockwork/anima_fragment_attack.ogg'
	possible_genders = list(PLURAL)
	speedmod = 0
	changesource_flags = MIRROR_BADMIN | WABBAJACK
	damage_overlay_type = "synth"
	prefix = "Clockwork"
	special_names = list("Remnant", "Relic", "Scrap", "Vestige") //RIP Ratvar
	species_language_holder = /datum/language_holder/clockwork
	ghost_cooldown = 20 MINUTES // Trade some armor for human levels of speed. Only obtainable from adminbus or clockwork.
	var/has_corpse

/datum/species/golem/clockwork/on_species_gain(mob/living/carbon/human/H)
	. = ..()
	H.faction |= "ratvar"
	RegisterSignal(H, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/datum/species/golem/clockwork/on_species_loss(mob/living/carbon/human/H)
	if(!is_servant_of_ratvar(H))
		H.faction -= "ratvar"
	UnregisterSignal(H, COMSIG_MOB_SAY)
	. = ..()

/datum/species/golem/clockwork/proc/handle_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_ROBOT //beep

/datum/species/golem/clockwork/spec_death(gibbed, mob/living/carbon/human/H)
	gibbed = !has_corpse ? FALSE : gibbed
	. = ..()
	if(!has_corpse)
		var/turf/T = get_turf(H)
		H.visible_message(span_warning("[H]'s exoskeleton shatters, collapsing into a heap of scrap!"))
		playsound(H, 'sound/magic/clockwork/anima_fragment_death.ogg', 62, TRUE)
		for(var/i in 1 to rand(3, 5))
			new/obj/item/clockwork/alloy_shards/small(T)
		new/obj/item/clockwork/alloy_shards/clockgolem_remains(T)
		qdel(H)

/datum/species/golem/clockwork/no_scrap //These golems are created through the herald's beacon and leave normal corpses on death.
	id = "clockwork golem servant"
	armor = 15 //Balance reasons make this armor weak
	no_equip = list()
	nojumpsuit = FALSE
	has_corpse = TRUE
	random_eligible = FALSE
	info_text = "<span class='bold alloy'>As a </span><span class='bold brass'>Clockwork Golem Servant</span><span class='bold alloy'>, you are faster than other types of golems.</span>" //warcult golems leave a corpse
	ghost_cooldown = null // Only from adminbus.

/datum/species/golem/cloth
	name = "Cloth Golem"
	id = "cloth golem"
	limbs_id = "clothgolem"
	possible_genders = list(PLURAL)
	info_text = "As a <span class='danger'>Cloth Golem</span>, you are able to reform yourself after death, provided your remains aren't burned or destroyed. You are, of course, very flammable. \
	Being made of cloth, your body is magic resistant and faster than that of other golems, but weaker and less resilient."
	species_traits = list(NOBLOOD,NO_UNDERWEAR, NOHUSK) //no mutcolors, and can burn
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_NOBREATH,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOGUNS,TRAIT_NOHUNGER)
	inherent_biotypes = MOB_UNDEAD|MOB_HUMANOID
	armor = 15 //feels no pain, but not too resistant
	burnmod = 2 // don't get burned
	speedmod = 1 // not as heavy as stone
	punchdamagelow = 4
	punchstunchance = 0.2
	punchdamagehigh = 8 // not as heavy as stone
	prefix = "Cloth"
	special_names = null
	ghost_cooldown = 5 MINUTES // Revive timer is 90 seconds. Kind of the gimmick for them to get back up if not dealt with.

/datum/species/golem/cloth/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	ADD_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)

/datum/species/golem/cloth/on_species_loss(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)
	..()

/datum/species/golem/cloth/check_roundstart_eligible()
	if(SSgamemode.holidays && SSgamemode.holidays[HALLOWEEN])
		return TRUE
	return ..()

/datum/species/golem/cloth/random_name(gender,unique,lastname)
	var/pharaoh_name = pick("Neferkare", "Hudjefa", "Khufu", "Mentuhotep", "Ahmose", "Amenhotep", "Thutmose", "Hatshepsut", "Tutankhamun", "Ramses", "Seti", \
	"Merenptah", "Djer", "Semerkhet", "Nynetjer", "Khafre", "Pepi", "Intef", "Ay") //yes, Ay was an actual pharaoh
	var/golem_name = "[pharaoh_name] \Roman[rand(1,99)]"
	return golem_name

/datum/species/golem/cloth/spec_life(mob/living/carbon/human/H)
	if(H.fire_stacks < 1)
		H.adjust_fire_stacks(1) //always prone to burning
	..()

/datum/species/golem/cloth/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	if(gibbed)
		return
	if(H.on_fire)
		H.visible_message(span_danger("[H] burns into ash!"))
		H.dust(just_ash = TRUE)
		return

	H.visible_message(span_danger("[H] falls apart into a pile of bandages!"))
	new /obj/structure/cloth_pile(get_turf(H), H)

/obj/structure/cloth_pile
	name = "pile of bandages"
	desc = "It emits a strange aura, as if there was still life within it..."
	max_integrity = 50
	armor = list(MELEE = 90, BULLET = 90, LASER = 25, ENERGY = 80, BOMB = 50, BIO = 100, FIRE = -50, ACID = -50)
	icon = 'icons/obj/misc.dmi'
	icon_state = "pile_bandages"
	resistance_flags = FLAMMABLE

	var/revive_time = 900
	var/mob/living/carbon/human/cloth_golem

/obj/structure/cloth_pile/Initialize(mapload, mob/living/carbon/human/H)
	. = ..()
	if(!QDELETED(H) && is_species(H, /datum/species/golem/cloth))
		H.unequip_everything()
		H.forceMove(src)
		cloth_golem = H
		to_chat(cloth_golem, span_notice("You start gathering your life energy, preparing to rise again..."))
		addtimer(CALLBACK(src, PROC_REF(revive)), revive_time)
	else
		return INITIALIZE_HINT_QDEL

/obj/structure/cloth_pile/Destroy()
	if(cloth_golem)
		QDEL_NULL(cloth_golem)
	return ..()

/obj/structure/cloth_pile/burn()
	visible_message(span_danger("[src] burns into ash!"))
	new /obj/effect/decal/cleanable/ash(get_turf(src))
	..()

/obj/structure/cloth_pile/proc/revive()
	if(QDELETED(src) || QDELETED(cloth_golem)) //QDELETED also checks for null, so if no cloth golem is set this won't runtime
		return
	if(cloth_golem.suiciding || cloth_golem.hellbound)
		QDEL_NULL(cloth_golem)
		return

	invisibility = INVISIBILITY_MAXIMUM //disappear before the animation
	new /obj/effect/temp_visual/mummy_animation(get_turf(src))
	if(cloth_golem.revive(full_heal = TRUE, admin_revive = TRUE))
		cloth_golem.grab_ghost() //won't pull if it's a suicide
	sleep(2 SECONDS)
	cloth_golem.forceMove(get_turf(src))
	cloth_golem.visible_message(span_danger("[src] rises and reforms into [cloth_golem]!"),span_userdanger("You reform into yourself!"))
	cloth_golem = null
	qdel(src)

/obj/structure/cloth_pile/attackby(obj/item/P, mob/living/carbon/human/user, params)
	. = ..()

	if(resistance_flags & ON_FIRE)
		return

	if(P.is_hot())
		visible_message(span_danger("[src] bursts into flames!"))
		fire_act()

/datum/species/golem/plastic
	name = "Plastic Golem"
	id = "plastic golem"
	prefix = "Plastic"
	special_names = list("Sheet", "Bag", "Bottle")
	fixed_mut_color = "#ffffff"
	info_text = "As a <span class='danger'>Plastic Golem</span>, you are capable of ventcrawling and passing through plastic flaps as long as you are naked."
	ghost_cooldown = 18 MINUTES // Iron golem, except they get ventcrawling.

/datum/species/golem/plastic/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.ventcrawler = VENTCRAWLER_NUDE

/datum/species/golem/plastic/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.ventcrawler = initial(C.ventcrawler)

/datum/species/golem/bronze
	name = "Bronze Golem"
	id = "bronze golem"
	prefix = "Bronze"
	special_names = list("Bell")
	fixed_mut_color = "#cd7f32"
	info_text = "As a <span class='danger'>Bronze Golem</span>, you are very resistant to loud noises, and make loud noises if something hard hits you, however this ability does hurt your hearing."
	special_step_sounds = list('sound/machines/clockcult/integration_cog_install.ogg', 'sound/magic/clockwork/fellowship_armory.ogg' )
	ghost_cooldown = 18 MINUTES // Annoying to those who enter melee combat with it.
	mutantears = /obj/item/organ/ears/bronze
	var/last_gong_time = 0
	var/gong_cooldown = 150

/datum/species/golem/bronze/bullet_act(obj/projectile/P, mob/living/carbon/human/H)
	if(!(world.time > last_gong_time + gong_cooldown))
		return BULLET_ACT_HIT
	if(P.armor_flag == BULLET || P.armor_flag == BOMB)
		gong(H)
		return BULLET_ACT_HIT

/datum/species/golem/bronze/spec_hitby(atom/movable/AM, mob/living/carbon/human/H)
	..()
	if(world.time > last_gong_time + gong_cooldown)
		gong(H)

/datum/species/golem/bronze/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style, modifiers)
	..()
	if(world.time > last_gong_time + gong_cooldown &&  M.combat_mode)
		gong(H)

/datum/species/golem/bronze/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	..()
	if(world.time > last_gong_time + gong_cooldown)
		gong(H)

/datum/species/golem/bronze/on_hit(obj/projectile/P, mob/living/carbon/human/H)
	..()
	if(world.time > last_gong_time + gong_cooldown)
		gong(H)

/datum/species/golem/bronze/proc/gong(mob/living/carbon/human/H)
	last_gong_time = world.time
	for(var/mob/living/M in get_hearers_in_view(7,H))
		if(M.stat == DEAD)	//F
			return
		if(M == H)
			H.show_message(span_narsiesmall("You cringe with pain as your body rings around you!"), MSG_AUDIBLE)
			H.playsound_local(H, 'sound/effects/gong.ogg', 100, TRUE)
			H.soundbang_act(2, 0, 10, 1)
			M.adjust_jitter(7 SECONDS)
		var/distance = max(0,get_dist(get_turf(H),get_turf(M)))
		switch(distance)
			if(0 to 1)
				M.show_message(span_narsiesmall("GONG!"), MSG_AUDIBLE)
				M.playsound_local(H, 'sound/effects/gong.ogg', 100, TRUE)
				M.soundbang_act(1, 0, 10, 3)
				M.adjust_confusion(10 SECONDS)
				M.adjust_jitter(4 SECONDS)
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "gonged", /datum/mood_event/loud_gong)
			if(2 to 3)
				M.show_message(span_cult("GONG!"), MSG_AUDIBLE)
				M.playsound_local(H, 'sound/effects/gong.ogg', 75, TRUE)
				M.soundbang_act(1, 0, 5, 2)
				M.adjust_jitter(3 SECONDS)
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "gonged", /datum/mood_event/loud_gong)
			else
				M.show_message(span_warning("GONG!"), MSG_AUDIBLE)
				M.playsound_local(H, 'sound/effects/gong.ogg', 50, TRUE)

/datum/species/golem/snow
	name = "Snow Golem"
	id = "snow golem"
	limbs_id = "sn_golem"
	fixed_mut_color = "null" //custom sprites
	armor = 45 //down from 55
	burnmod = 3 //melts easily
	info_text = "As a <span class='danger'>Snow Golem</span>, you are extremely vulnerable to burn damage, but you can generate snowballs and shoot cryokinetic beams. You will also turn to snow when dying, preventing any form of recovery."
	prefix = "Snow"
	special_names = list("Flake", "Blizzard", "Storm", "Frosty")
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES, NOHUSK) //no mutcolors, no eye sprites
	inherent_traits = list(TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	ghost_cooldown = 20 MINUTES // A golem that kites by slowing people down (with cyro) and uses snowballs (does stamina damage).

	/// A ref to our "throw snowball" spell we get on species gain.
	var/datum/action/cooldown/spell/conjure_item/snowball/snowball
	/// A ref to our cryobeam spell we get on species gain.
	var/datum/action/cooldown/spell/pointed/projectile/cryo/cryo

/datum/species/golem/snow/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	H.visible_message(span_danger("[H] turns into a pile of snow!"))
	for(var/obj/item/W in H)
		H.dropItemToGround(W)
	for(var/i=1, i <= rand(3,5), i++)
		new /obj/item/stack/sheet/mineral/snow(get_turf(H))
	new /obj/item/reagent_containers/food/snacks/grown/carrot(get_turf(H))
	qdel(H)

/datum/species/golem/snow/on_species_gain(mob/living/carbon/grant_to, datum/species/old_species)
	. = ..()
	grant_to.weather_immunities |= WEATHER_SNOW
	snowball = new(grant_to)
	snowball.StartCooldown()
	snowball.Grant(grant_to)

	cryo = new(grant_to)
	cryo.StartCooldown()
	cryo.Grant(grant_to)

/datum/species/golem/snow/on_species_loss(mob/living/carbon/remove_from)
	. = ..()
	remove_from.weather_immunities &= ~WEATHER_SNOW
	QDEL_NULL(snowball)
	QDEL_NULL(cryo)
	return ..()

/datum/species/golem/cardboard //Faster but weaker, can also make new shells on its own
	name = "Cardboard Golem"
	id = "cardboard golem"
	prefix = "Cardboard"
	special_names = list("Box")
	info_text = "As a <span class='danger'>Cardboard Golem</span>, you aren't very strong, but you are a bit quicker and can easily create more brethren by using cardboard on yourself."
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK)
	inherent_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	limbs_id = "c_golem" //special sprites
	attack_verbs = list("whips")
	attack_sound = 'sound/weapons/whip.ogg'
	miss_sound = 'sound/weapons/etherealmiss.ogg'
	fixed_mut_color = null
	armor = 25
	burnmod = 1.25
	heatmod = 2
	speedmod = 1.5
	punchdamagelow = 4
	punchstunchance = 0.2
	punchdamagehigh = 8
	var/last_creation = 0
	var/brother_creation_cooldown = 300
	ghost_cooldown = 2 MINUTES // The ability to create a golem shell as a golem. This is the embodiment of golem army, surely?

/datum/species/golem/cardboard/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	. = ..()
	if(user != H)
		return FALSE //forced reproduction is rape.
	if(istype(I, /obj/item/stack/sheet/cardboard))
		var/obj/item/stack/sheet/cardboard/C = I
		if(last_creation + brother_creation_cooldown > world.time) //no cheesing dork
			return
		if(C.amount < 10)
			to_chat(H, span_warning("You do not have enough cardboard!"))
			return FALSE
		to_chat(H, span_notice("You attempt to create a new cardboard brother."))
		if(do_after(user, 3 SECONDS, user))
			if(last_creation + brother_creation_cooldown > world.time) //no cheesing dork
				return
			if(!C.use(10))
				to_chat(H, span_warning("You do not have enough cardboard!"))
				return FALSE
			to_chat(H, span_notice("You create a new cardboard golem shell."))
			create_brother(H.loc)

/datum/species/golem/cardboard/proc/create_brother(location)
	new /obj/effect/mob_spawn/human/golem/servant(location, /datum/species/golem/cardboard, owner)
	last_creation = world.time

/datum/species/golem/leather
	name = "Leather Golem"
	id = "leather golem"
	special_names = list("Face", "Man", "Belt") //Ah dude 4 strength 4 stam leather belt AHHH
	inherent_traits = list(TRAIT_NOBREATH,TRAIT_NOHUNGER, TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER, TRAIT_STRONG_GRABBER)
	prefix = "Leather"
	fixed_mut_color = "#624a2e"
	info_text = "As a <span class='danger'>Leather Golem</span>, you are flammable, but you can grab things with incredible ease, allowing all your grabs to start at a strong level."
	grab_sound = 'sound/weapons/whipgrab.ogg'
	attack_sound = 'sound/weapons/whip.ogg'
	ghost_cooldown = 18 MINUTES // Has instant aggro grab. Not as terrible since it doesn't stun though.

/datum/species/golem/durathread
	name = "Durathread Golem"
	id = "durathread golem"
	prefix = "Durathread"
	limbs_id = "d_golem"
	special_names = list("Boll","Weave")
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK)
	fixed_mut_color = null
	inherent_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	info_text = "As a <span class='danger'>Durathread Golem</span>, your strikes will cause those your targets to start choking, but your woven body won't withstand fire as well."
	ghost_cooldown = 18 MINUTES // Chokes people.

/datum/species/golem/durathread/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	target.apply_status_effect(STATUS_EFFECT_CHOKINGSTRAND)

/datum/species/golem/bone
	name = "Bone Golem"
	id = "bone golem"
	say_mod = "rattles"
	prefix = "Bone"
	limbs_id = "b_golem"
	special_names = list("Head", "Broth", "Fracture", "Rattler", "Appetit")
	liked_food = GROSS | MEAT | RAW
	toxic_food = null
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH,HAS_BONE, NOHUSK)
	inherent_biotypes = MOB_UNDEAD|MOB_HUMANOID
	mutanttongue = /obj/item/organ/tongue/bone
	possible_genders = list(PLURAL)
	fixed_mut_color = null
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_FAKEDEATH,TRAIT_CALCIUM_HEALER,TRAIT_NOHUNGER)
	info_text = "As a <span class='danger'>Bone Golem</span>, You have a powerful spell that lets you chill your enemies with fear, and milk heals you! Just make sure to watch our for bone-hurting juice."
	var/datum/action/innate/bonechill/bonechill
	ghost_cooldown = 18 MINUTES // Has AOE slowdown spell.

/datum/species/golem/bone/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(ishuman(C))
		bonechill = new
		bonechill.Grant(C)

/datum/species/golem/bone/on_species_loss(mob/living/carbon/C)
	if(bonechill)
		bonechill.Remove(C)
	..()

/datum/action/innate/bonechill
	name = "Bone Chill"
	desc = "Rattle your bones and strike fear into your enemies!"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	button_icon_state = "bonechill"
	var/cooldown = 600
	var/last_use
	var/snas_chance = 3

/datum/action/innate/bonechill/Activate()
	if(world.time < last_use + cooldown)
		to_chat(span_notice("You aren't ready yet to rattle your bones again"))
		return
	owner.visible_message(span_warning("[owner] rattles [owner.p_their()] bones harrowingly."), span_notice("You rattle your bones"))
	last_use = world.time
	if(prob(snas_chance))
		playsound(get_turf(owner),'sound/magic/RATTLEMEBONES2.ogg', 100)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			var/mutable_appearance/badtime = mutable_appearance('icons/mob/human_parts.dmi', "b_golem_eyes", -FIRE_LAYER-0.5)
			badtime.appearance_flags = RESET_COLOR
			H.overlays_standing[FIRE_LAYER+0.5] = badtime
			H.apply_overlay(FIRE_LAYER+0.5)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon, remove_overlay), FIRE_LAYER+0.5), 25)
	else
		playsound(get_turf(owner),'sound/magic/RATTLEMEBONES.ogg', 100)
	for(var/mob/living/L in orange(7, get_turf(owner)))
		if((L.mob_biotypes & MOB_UNDEAD) || isgolem(L) || HAS_TRAIT(L, TRAIT_RESISTCOLD))
			return //Do not affect our brothers

		to_chat(L, span_cultlarge("A spine-chilling sound chills you to the bone!"))
		L.apply_status_effect(/datum/status_effect/bonechill)
		SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "spooked", /datum/mood_event/spooked)

/datum/species/golem/capitalist
	name = "Capitalist Golem"
	id = "capitalist golem"
	prefix = "Capitalist"
	attack_verbs = list("monopoliz")
	limbs_id = "ca_golem"
	special_names = list("John D. Rockefeller","Rich Uncle Pennybags","Commodore Vanderbilt","Entrepreneur","Mr. Moneybags", "Adam Smith")
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK)
	fixed_mut_color = null
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	info_text = "As a <span class='danger'>Capitalist Golem</span>, your fist spreads the powerful industrializing light of capitalism."
	changesource_flags = MIRROR_BADMIN
	random_eligible = FALSE
	ghost_cooldown = null // Adminbus only.

/datum/species/golem/capitalist/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.equip_to_slot_or_del(new /obj/item/clothing/head/that (), ITEM_SLOT_HEAD)
	C.equip_to_slot_or_del(new /obj/item/clothing/glasses/monocle (), ITEM_SLOT_EYES)
	C.revive(full_heal = TRUE)
	to_chat(C, span_alert("You are now a capitalist golem! Do not harm fellow capitalist golems. Kill communist golems and hit people with your fists to spread the industrializing light of capitalism to others! Hello I like money!")) //yogs memes
	to_chat(C, span_userdanger("Hit non-golems several times in order to get them fat and on your side!"))

	SEND_SOUND(C, sound('sound/misc/capitialism.ogg'))
	var/datum/action/cooldown/spell/aoe/knock/OPEN_THE_DOOR = new(C)
	OPEN_THE_DOOR.Grant(C)
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	C.mind.add_antag_datum(/datum/antagonist/golem/capitalist)

/datum/species/golem/capitalist/on_species_loss(mob/living/carbon/C)
	. = ..()
	UnregisterSignal(C, COMSIG_MOB_SAY)
	for(var/datum/action/cooldown/spell/aoe/knock/OPEN_THE_DOOR in C.actions)
		OPEN_THE_DOOR.Remove(C)
	var/datum/antagonist/golem/capitalist/CA = C.mind.has_antag_datum(/datum/antagonist/golem/capitalist)
	if(CA && !CA.removing)
		C.mind.remove_antag_datum(/datum/antagonist/golem/capitalist)

/datum/species/golem/capitalist/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	..()
	if(isgolem(target))
		return
	if(target.nutrition >= NUTRITION_LEVEL_FAT)
		target.set_species(/datum/species/golem/capitalist)
		return
	target.adjust_nutrition(40)

/datum/species/golem/capitalist/proc/handle_speech(datum/source, list/speech_args)
	playsound(source, 'sound/misc/mymoney.ogg', 25, TRUE)
	speech_args[SPEECH_MESSAGE] = "Hello, I like money!"

/datum/species/golem/church_capitalist //slightly faster reskinned iron golem gained from a cult of st credit rite
	name = "Churchgoing Capitalist Golem"
	id = "church_capitalist golem"
	prefix = "Religio-Capitalist"
	attack_verbs = list("monopoliz")
	limbs_id = "ca_golem"
	special_names = list("John D. Rockefeller","Rich Uncle Pennybags","Commodore Vanderbilt","Entrepreneur","Mr. Moneybags", "Adam Smith")
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES, NOHUSK)
	fixed_mut_color = null
	speedmod = 1.5
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	info_text = "As a <span class='danger'>Churchgoing Capitalist Golem</span>, your god-given right is to make fat stacks of money!"
	changesource_flags = MIRROR_BADMIN
	random_eligible = FALSE
	ghost_cooldown = null // Adminbus only.

/datum/species/golem/church_capitalist/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.equip_to_slot_or_del(new /obj/item/clothing/head/that (), ITEM_SLOT_HEAD)
	C.equip_to_slot_or_del(new /obj/item/clothing/glasses/monocle (), ITEM_SLOT_EYES)
	C.revive(full_heal = TRUE, admin_revive = FALSE)

	SEND_SOUND(C, sound('sound/misc/capitialism.ogg'))

/datum/species/golem/soviet
	name = "Soviet Golem"
	id = "soviet golem"
	prefix = "Comrade"
	attack_verbs = list("nationaliz")
	limbs_id = "s_golem"
	special_names = list("Stalin","Lenin","Trotsky","Marx","Comrade") //comrade comrade
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES,NOFLASH, NOHUSK)
	fixed_mut_color = null
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	info_text = "As a <span class='danger'>Soviet Golem</span>, your fist spreads the bright soviet light of communism."
	changesource_flags = MIRROR_BADMIN
	random_eligible = FALSE
	ghost_cooldown = null // Adminbus only.

/datum/species/golem/soviet/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.equip_to_slot_or_del(new /obj/item/clothing/head/ushanka (), ITEM_SLOT_HEAD)
	C.revive(full_heal = TRUE)
	to_chat(C, span_alert("You are now a soviet golem! Do not harm fellow soviet golems. Kill captalist golems and hit people with your fists to spread the glorious light of communism to others! Cyka Blyat!"))
	to_chat(C, span_userdanger("Hit non-golems several times in order to get them starving and on your side!"))

	SEND_SOUND(C, sound('sound/misc/Russian_Anthem_chorus.ogg'))
	var/datum/action/cooldown/spell/aoe/knock/OPEN_THE_DOOR = new(C)
	OPEN_THE_DOOR.Grant(C)
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	C.mind.add_antag_datum(/datum/antagonist/golem/communist)

/datum/species/golem/soviet/on_species_loss(mob/living/carbon/C)
	. = ..()
	for(var/datum/action/cooldown/spell/aoe/knock/OPEN_THE_DOOR in C.actions)
		OPEN_THE_DOOR.Remove(C)
	UnregisterSignal(C, COMSIG_MOB_SAY)
	var/datum/antagonist/golem/communist/CU = C.mind.has_antag_datum(/datum/antagonist/golem/communist)
	if(CU && !CU.removing)
		C.mind.remove_antag_datum(/datum/antagonist/golem/communist)

/datum/species/golem/soviet/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	..()
	if(isgolem(target))
		return
	if(target.nutrition <= NUTRITION_LEVEL_STARVING)
		target.set_species(/datum/species/golem/soviet)
		return
	target.adjust_nutrition(-40)

/datum/species/golem/soviet/proc/handle_speech(datum/source, list/speech_args)
	playsound(source, 'sound/misc/Cyka Blyat.ogg', 25, TRUE) //if it's handled with the ambient it's funnier
	speech_args[SPEECH_MESSAGE] = "Cyka Blyat"

/datum/species/golem/cheese
	name = "Cheese Golem"
	id = "cheese golem"
	fixed_mut_color = "#F1D127"
	meat = /obj/item/stack/sheet/cheese
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOGUNS,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER)
	armor = 10
	burnmod = 1.25
	heatmod = 1.5
	brutemod = 0.8
	info_text = "You are a <span class='danger'>Cheese Golem</span>, you take extra damage from heat and fire, you're resistant to brute, but people can eat you!"
	prefix = "Cheese"
	special_names = list("Gouda")
	var/integrity = 40
	punchdamagehigh = 10
	ghost_cooldown = 10 MINUTES // Must be worse than iron golems.

/datum/species/golem/cheese/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H)
	..()
	if(M.reagents && M != H && M.combat_mode)
		if((M.nutrition + 10) > (600 * (1 + M.overeatduration / 2000)))
			return
		else
			M.visible_message(span_danger("[M] takes a bite out of [H]!"))
			playsound(get_turf(H), 'sound/items/eatfood.ogg', 25, 0)
			M.reagents.add_reagent(/datum/reagent/consumable/nutriment, 0.4)
			M.reagents.add_reagent(/datum/reagent/consumable/nutriment/vitamin, 0.4)
			if(integrity <= 0)
				qdel(H)
				M.visible_message(span_danger("[H]'s can no longer maintain stuctural integrity and falls to pieces!"))
			else
				integrity = integrity - 0.4

//Tougher than diamond, can burn but it doesn't damage them
/datum/species/golem/mhydrogen
	name = "Metallic Hydrogen Golem"
	id = "Metallic Hydrogen golem"
	fixed_mut_color = "#dddddd"
	info_text = "As a <span class='danger'>Metallic Hydrogen Golem</span>, you were forged in the highest pressures and the highest heats. Your exotic makeup makes you tougher than diamond."
	prefix = "Hydrogen"
	stunmod = 0.6 //as opposed to plasteel's 0.4
	special_names = list("Primordial","Indivisible","Proton", "Superconductor","Supersolid","Metastable","Oppenheimer") //the first element, in an exotic and theoretical state
	armor = 75 //5 more than diamond, 20 more than base golem
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER,TRAIT_NOGUNS,TRAIT_NOHUNGER) //removed NOFIRE because hydrogen burns and they come from the fire department
	ghost_cooldown = 30 MINUTES // Objectively better than diamond golems.

/datum/species/golem/mhydrogen/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	ADD_TRAIT(C, TRAIT_ANTIMAGIC, SPECIES_TRAIT)

/datum/species/golem/mhydrogen/on_species_loss(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_ANTIMAGIC, SPECIES_TRAIT)
	return ..()

//Fast golem that can be only created with use of telecrystals, can make ninja-like teleports
/datum/species/golem/telecrystal
	name = "Telecrystal Golem"
	id = "telecrystal golem"
	limbs_id = "cr_golem"
	fixed_mut_color = "#e02828"
	speedmod = 1 //same as golden golem
	random_eligible = FALSE //too strong for a charged black extract
	info_text = "As a <span class='danger'>Telecrystal Golem</span>, you are faster than an avarage golem. Being created out of telecrystal, a much stable but less powerful variation of bluespace, you possess the ability to make controlled short ranged phase jumps."
	species_traits = list(NOBLOOD,MUTCOLORS,NO_UNDERWEAR,NOFLASH, NOHUSK)
	prefix = "Telecrystal"
	special_names = list("Agent", "Operative")
	var/datum/action/cooldown/spell/pointed/phase_jump/phase_jump
	ghost_cooldown = null // Adminbus or a terribly expensive investment by a traitor. Either way, deserves no cooldown.

/datum/species/golem/telecrystal/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(ishuman(C))
		phase_jump = new(C)
		phase_jump.Grant(C)

/datum/species/golem/telecrystal/on_species_loss(mob/living/carbon/C)
	if(phase_jump)
		phase_jump.Remove(C)
	..()

/datum/action/cooldown/spell/pointed/phase_jump
	name = "Phase Jump"
	desc = "Tap the power of your telecrystal body to teleport a short distance!"
	button_icon_state = "phasejump"
	ranged_mousepointer = 'icons/effects/mouse_pointers/phase_jump.dmi'

	cooldown_time = 20 SECONDS
	cast_range = 3
	active_msg = span_notice("You start channeling your telecrystal core....")
	deactive_msg = span_notice("You stop channeling your telecrystal core.")
	spell_requirements = NONE
	var/beam_icon = "tentacle"

/datum/action/cooldown/spell/pointed/phase_jump/InterceptClickOn(mob/living/user, params, atom/target)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/phasein = /obj/effect/temp_visual/dir_setting/cult/phase
	var/phaseout = /obj/effect/temp_visual/dir_setting/cult/phase/out
	var/obj/spot1 = new phaseout(get_turf(user), user.dir)
	owner.forceMove(target_turf)
	var/obj/spot2 = new phasein(get_turf(user), user.dir)
	spot1.Beam(spot2, beam_icon, time=2 SECONDS)
	user.visible_message(span_danger("[user] phase shifts away!"), span_warning("You shift around the space around you."))
	return TRUE

/datum/action/cooldown/spell/pointed/phase_jump/is_valid_target(atom/target)
	. = ..()
	if(!.)
		return FALSE
	var/turf/T = get_turf(target)
	var/area/AU = get_area(owner)
	var/area/AT = get_area(T)
	if((AT.area_flags & NOTELEPORT) || (AU.area_flags & NOTELEPORT))
		owner.balloon_alert(owner, "can't teleport there!")
		return FALSE
	return TRUE

/datum/species/golem/ruinous //slightly weaker and faster,gets telepathy,speaks louder, and their text is cult colored
	name = "Ruinous Golem"
	id = "ruinous golem"
	limbs_id = "ruingolem"
	possible_genders = list(PLURAL)
	armor = 40 //down from 55
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NOEYESPRITES, NOHUSK) //no mutcolors or eyesprites
	speedmod = 1.5 //inbetween gold golem and iron
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/blessed
	info_text = "As an <span class='danger'>Ruinous Golem</span>, you are made of an ancient powerful metal. While not particularly tough, \
				you have a connection with the old gods that grants you a selection of abilities."
	prefix = "Ruinous"
	special_names = list("One", "Elder", "Watcher", "Walker") //ominous
	ghost_cooldown = 15 MINUTES // Can't tell if better or worse.
	var/datum/action/cooldown/spell/list_target/telepathy/eldritch/ruinoustelepathy
//	var/datum/action/cooldown/spell/touch/flagellate/flagellate

/datum/species/golem/ruinous/on_species_loss(mob/living/carbon/C)
	..()
	UnregisterSignal(C, COMSIG_MOB_SAY)
	REMOVE_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)
	ruinoustelepathy?.Remove(C)
//	if(flagellate)
//		C.RemoveSpell(flagellate)

/datum/species/golem/ruinous/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	ADD_TRAIT(C, TRAIT_HOLY, SPECIES_TRAIT)
	ruinoustelepathy = new(C)
	ruinoustelepathy.Grant(C)
//	flagellate = new
//	C.AddSpell(flagellate)

/datum/species/golem/ruinous/proc/handle_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_CULTLARGE
	playsound(source, 'sound/effects/curseattack.ogg', 100, 1, 1)

/datum/species/golem/wax //has a love-hate relationship with fire
	name = "Wax Golem"
	id = "wax golem"
	limbs_id = "waxgolem"
	possible_genders = list(PLURAL)
	info_text = "As a <span class='danger'>Wax Golem</span>, you are made of very resilient wax and wick. \
	While you can burn, you take much less burn damage than other golems. You also have the ability to revive after death if you died while on fire."
	species_traits = list(NOBLOOD,NO_UNDERWEAR, NO_DNA_COPY, NOTRANSSTING, NOEYESPRITES, NOHUSK) //no mutcolors or eyesprites
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_NOBREATH,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOGUNS,TRAIT_NOHUNGER) //no resistheat or nofire
	armor = 10 // made of wax, tough wax but still wax
	burnmod = 0.75
	speedmod = 1 // not as heavy as stone
	heatmod = 0.1 //very little damage, but still there. Its like how a candle doesn't melt in seconds but still melts.
	punchdamagehigh = 9 // not as heavy as stone
	prefix = "Wax"
	special_names = list("Candelabra", "Candle")
	ghost_cooldown = 6 MINUTES // Similar revive gimmick to cloth golems, but a bit faster (80 seconds)

/datum/species/golem/wax/spec_life(mob/living/carbon/human/H)
	if(H.fire_stacks < 1)
		H.adjust_fire_stacks(1) //always prone to burning
	..()

/datum/species/golem/wax/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	if(gibbed)
		return
	if(H.on_fire)
		H.visible_message(span_danger("[H] melts apart into wax!"))
		new /obj/structure/wax_pile(get_turf(H), H)
		return
	else
		return

/obj/structure/wax_pile
	name = "pile of wax"
	desc = "It emits a strange aura, as if there was still life within it..."
	max_integrity = 150
	armor = list(MELEE = 50, BULLET = 50, LASER = 25, ENERGY = 80, BOMB = 50, BIO = 100, FIRE = 95, ACID = -50)
	icon = 'icons/obj/misc.dmi'
	icon_state = "pile_wax"

	var/revive_time = 80 SECONDS
	var/mob/living/carbon/human/wax_golem

/obj/structure/wax_pile/Initialize(mapload, mob/living/carbon/human/H)
	. = ..()
	if(!QDELETED(H) && is_species(H, /datum/species/golem/wax))
		H.unequip_everything()
		H.forceMove(src)
		wax_golem = H
		to_chat(wax_golem, span_notice("You start gathering your life energy, preparing to rise again..."))
		addtimer(CALLBACK(src, PROC_REF(revive)), revive_time)
	else
		return INITIALIZE_HINT_QDEL

/obj/structure/wax_pile/Destroy()
	if(wax_golem)
		QDEL_NULL(wax_golem)
	return ..()

/obj/structure/wax_pile/proc/revive()
	if(QDELETED(src) || QDELETED(wax_golem)) //QDELETED also checks for null, so if no wax golem is set this won't runtime
		return
	if(wax_golem.suiciding || wax_golem.hellbound)
		QDEL_NULL(wax_golem)
		return

	invisibility = INVISIBILITY_MAXIMUM //disappear before the animation
	new /obj/effect/temp_visual/wax_animation(get_turf(src))
	if(wax_golem.revive(full_heal = TRUE, admin_revive = TRUE))
		wax_golem.grab_ghost() //won't pull if it's a suicide
	sleep(2 SECONDS)
	wax_golem.forceMove(get_turf(src))
	wax_golem.visible_message(span_danger("[src] rises and reforms into [wax_golem]!"),span_userdanger("You reform into yourself!"))
	wax_golem = null
	qdel(src)

/datum/species/golem/supermatter
	name = "Supermatter Golem"
	id = "supermatter golem"
	mutanthands = /obj/item/melee/supermatter_sword/hand
	inherent_traits = list(TRAIT_NOHARDCRIT,TRAIT_NOSOFTCRIT,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_NOFIRE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER,TRAIT_NOGUNS)
	changesource_flags = MIRROR_BADMIN
	random_eligible = FALSE // Hell no
	info_text = "As a <span class='danger'>Supermatter Golem</span>, you dust almost any physical object that interacts with you, while taking half as much brute damage and three times more burn damage. You also explode on death."
	attack_verbs = list("dusting punch")
	attack_sound = 'sound/effects/supermatter.ogg'
	fixed_mut_color = "ff0"
	brutemod = 1.5
	burnmod = 3
	ghost_cooldown = null // Adminbus only.
	var/burnheal = 1
	var/bruteheal = 0.5
	var/randexplode = FALSE

/datum/species/golem/supermatter/spec_hitby(atom/movable/AM, mob/living/carbon/human/H)
	..()
	H.adjustFireLoss(2)
	playsound(get_turf(H), 'sound/effects/supermatter.ogg', 10, TRUE)
	H.visible_message(span_danger("[AM] knocks into [H], and then turns into dust with a flash of light!"))
	qdel(AM)

/datum/species/golem/supermatter/spec_attack_hand(mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style)
	..()
	M.visible_message(span_danger("[M] tries to punch [H], but turns into dust with a brilliant flash of light!"))
	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 10, TRUE)
	M.dust()

/datum/species/golem/supermatter/spec_attacked_by(obj/item/I, mob/living/user, obj/item/bodypart/affecting, mob/living/carbon/human/H)
	..()
	H.visible_message(span_danger("[user] tries to attack [H] with [I], but [I] turns into dust with a brilliant flash of light!"))
	playsound(get_turf(H), 'sound/effects/supermatter.ogg', 10, TRUE)
	qdel(I)


/datum/species/golem/supermatter/bullet_act(obj/projectile/P, mob/living/carbon/human/H)
	. = ..()
	if(istype(P, /obj/projectile/magic) || P.armor_flag == LASER || P.armor_flag == ENERGY)
		return .
	H.visible_message(span_danger("[P] melts on collision with [H]!"))
	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 10, TRUE)
	return BULLET_ACT_FORCE_PIERCE

/datum/species/golem/supermatter/spec_life(mob/living/carbon/C)
	. = ..()
	C.adjustFireLoss(-burnheal)
	C.adjustBruteLoss(-bruteheal)
	if(C.InCritical() && prob(1.5))
		randexplode = TRUE
		C.visible_message(span_danger("[C]'s body violently explodes!"))
		explosion(get_turf(C), 1 ,3, 6)
		qdel(C)

/datum/species/golem/supermatter/spec_death(gibbed, mob/living/carbon/human/H)
	..()
	if(gibbed)
		return
	if(randexplode) //No double explosions
		return
	H.visible_message(span_danger("[H]'s body violently explodes!"))
	explosion(get_turf(H), 1 ,3, 6)
	qdel(H)

/obj/item/melee/supermatter_sword/hand
	name = "supermatter hand"
	desc = "A hand of a robust supermatter golem."
	icon = 'icons/obj/weapons/hand.dmi'
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'
	icon_state = "disintegrate"
	item_state = "disintegrate"
	color = "#ffff00"

/obj/item/melee/supermatter_sword/hand/Initialize(mapload,silent,synthetic)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)

/datum/species/golem/cloth/get_species_description()
	return "A wrapped up Mummy! They descend upon Space Station Thirteen every year to spook the crew! \"Return the slab!\""

/datum/species/golem/cloth/get_species_lore()
	return list(
		"Mummies are very self conscious. They're shaped weird, they walk slow, and worst of all, \
		they're considered the laziest halloween costume. But that's not even true, they say.",

		"Making a mummy costume may be easy, but making a CONVINCING mummy costume requires \
		things like proper fabric and purposeful staining to achieve the look. Which is FAR from easy. Gosh.",
	)

// Calls parent, as Golems have a species-wide perk we care about.
/datum/species/golem/cloth/create_pref_unique_perks()
	var/list/to_add = ..()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = "recycle",
		SPECIES_PERK_NAME = "Reformation",
		SPECIES_PERK_DESC = "Mummies collapse into \
			a pile of bandages after they die. If left alone, they will reform back \
			into themselves. The bandages themselves are very vulnerable to fire.",
	))

	return to_add

// Override to add a perk elaborating on just how dangerous fire is.
/datum/species/golem/cloth/create_pref_temperature_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = "fire-alt",
		SPECIES_PERK_NAME = "Incredibly Flammable",
		SPECIES_PERK_DESC = "Mummies are made entirely of cloth, which makes them \
			very vulnerable to fire. They will not reform if they die while on \
			fire, and they will easily catch alight. If your bandages burn to ash, you're toast!",
	))

	return to_add

/datum/species/golem/tar
	name = "Tar Golem"
	id = "tar golem"
	species_traits = list(NOBLOOD,MUTCOLORS,NO_UNDERWEAR, NO_DNA_COPY, NOTRANSSTING, NOHUSK)
	inherent_traits = list(TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_GENELESS,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER,TRAIT_NOGUNS)
	speedmod = 1.5 // Slightly faster
	armor = 25
	punchstunchance = 0.2
	fixed_mut_color = "48002b"
	info_text = "As a <span class='danger'>Tar Golem</span>, you burn very very easily and can temporarily turn yourself into a pool of tar, in this form you are invulnerable to all attacks."
	random_eligible = FALSE //If false, the golem subtype can't be made through golem mutation toxin
	prefix = "Tar"
	special_names = list("Tar'ath", "Tar'eth", "Tar'kian", "Eth'ar", "Rum'tir")
	var/datum/action/cooldown/spell/jaunt/ethereal_jaunt/tar_pool/TP

/datum/species/golem/tar/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	. = ..()
	TP = new
	TP.Grant(C)


/datum/species/golem/tar/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	. = ..()
	TP?.Remove(C)
