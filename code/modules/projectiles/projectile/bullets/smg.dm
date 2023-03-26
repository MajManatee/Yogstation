// .45 (M1911 & C-20r SMG)

/obj/item/projectile/bullet/c45
	name = ".45 bullet"
	damage = 30
	wound_bonus = -10

/obj/item/projectile/bullet/c45/ap
	name = ".45 armor-piercing bullet"
	damage = 27
	armour_penetration = 40

/obj/item/projectile/bullet/c45/hp
	name = ".45 hollow-point bullet"
	damage = 45
	armour_penetration = -45
	sharpness = SHARP_EDGED
	wound_bonus = -5 //Basically L6 HP treatment on these values because it's, well, nukies
	bare_wound_bonus = 5

/obj/item/projectile/bullet/c45/venom
	name = ".45 venom bullet"
	damage = 20

/obj/item/projectile/bullet/c45/venom/on_hit(atom/target, blocked)
	if((blocked != 100) && iscarbon(target))
		var/mob/living/carbon/victim = target
		victim.reagents.add_reagent(/datum/reagent/toxin/venom, 4)
	return ..()

// 4.6x30mm (WT-550 Autocarbine)

/obj/item/projectile/bullet/c46x30mm
	name = "4.6x30mm bullet"
	damage = 15
	wound_bonus = -5
	bare_wound_bonus = 5

/obj/item/projectile/bullet/c46x30mm/ap
	name = "4.6x30mm armor-piercing bullet"
	damage = 12
	armour_penetration = 40

/obj/item/projectile/bullet/incendiary/c46x30mm
	name = "4.6x30mm incendiary bullet"
	damage = 9
	fire_stacks = 1

/obj/item/projectile/bullet/c46x30mm/rubber
	name = "4.6x30mm rubber bullet"
	damage = 5
	stamina = 22

/obj/item/projectile/bullet/c46x30mm/venom
	name = "4.6x30mm venom bullet" // Doesnt actually inject toxin. Just does toxin damage.
	damage = 6

/obj/item/projectile/bullet/c46x30mm/venom/on_hit(atom/target, blocked)
	if((blocked != 100) && iscarbon(target))
		var/mob/living/carbon/victim = target
		victim.reagents.add_reagent(/datum/reagent/toxin, 4)
		victim.adjustToxLoss(6)

	return ..()
/obj/item/projectile/bullet/c46x30mm/kraken
	name = "4.6x30mm kraken bullet"
	damage = 22
	armour_penetration = -50
	wound_bonus = -30 // we arent dismembering people here
	bare_wound_bonus = 3
