/obj/item/projectile/bullet/neurotoxin
	name = "neurotoxin spit"
	icon_state = "neurotoxin"
	damage = 5
	damage_type = TOX
	paralyze = 100

/obj/item/projectile/bullet/neurotoxin/on_hit(atom/target, blocked = FALSE)
	if(isalien(target) || target.ckey == "saphiriccoverlord")
		paralyze = 0
		nodamage = TRUE
	return ..()
