
/mob/living/proc/get_bodypart(zone)
	return

/mob/living/carbon/get_bodypart(zone)
	if(!zone)
		zone = BODY_ZONE_CHEST
	if(zone == BODY_ZONE_PRECISE_MOUTH || zone == BODY_ZONE_PRECISE_EYES) //yes this is required.
		zone = BODY_ZONE_HEAD
	if(zone == BODY_ZONE_PRECISE_GROIN)
		zone = BODY_ZONE_CHEST
	for(var/X in bodyparts)
		var/obj/item/bodypart/L = X
		if(L.body_zone == zone)
			return L

/mob/living/carbon/has_hand_for_held_index(i)
	if(i)
		var/obj/item/bodypart/L = hand_bodyparts[i]
		if(L && !L.bodypart_disabled)
			return L
	return FALSE

///Get the bodypart for whatever hand we have active, Only relevant for carbons
/mob/proc/get_active_hand()
	return FALSE

/mob/living/carbon/get_active_hand()
	var/which_hand = BODY_ZONE_PRECISE_L_HAND
	if(!(active_hand_index % 2))
		which_hand = BODY_ZONE_PRECISE_R_HAND
	return get_bodypart(check_zone(which_hand))

/mob/living/carbon/get_active_hand()
	var/which_hand = BODY_ZONE_PRECISE_L_HAND
	if(!(active_hand_index % 2))
		which_hand = BODY_ZONE_PRECISE_R_HAND
	return get_bodypart(check_zone(which_hand))

/mob/proc/has_left_hand(check_disabled = TRUE)
	return TRUE

/mob/living/carbon/has_left_hand(check_disabled = TRUE)
	for(var/obj/item/bodypart/L in hand_bodyparts)
		if(L.held_index % 2)
			if(!check_disabled || !L.bodypart_disabled)
				return TRUE
	return FALSE

/mob/living/carbon/alien/larva/has_left_hand()
	return 1


/mob/proc/has_right_hand(check_disabled = TRUE)
	return TRUE

/mob/living/carbon/has_right_hand(check_disabled = TRUE)
	for(var/obj/item/bodypart/L in hand_bodyparts)
		if(!(L.held_index % 2))
			if(!check_disabled || !L.bodypart_disabled)
				return TRUE
	return FALSE

/mob/living/carbon/alien/larva/has_right_hand()
	return 1



//Limb numbers
/mob/proc/get_num_arms(check_disabled = TRUE)
	return 2

/mob/living/carbon/get_num_arms(check_disabled = TRUE)
	. = 0
	for(var/X in bodyparts)
		var/obj/item/bodypart/affecting = X
		if(affecting.body_part & (ARM_RIGHT|ARM_LEFT))
			if(!check_disabled || !affecting.bodypart_disabled)
				.++


//sometimes we want to ignore that we don't have the required amount of arms.
/mob/proc/get_arm_ignore()
	return 0

/mob/living/carbon/alien/larva/get_arm_ignore()
	return 1 //so we can still handcuff larvas.


/mob/proc/get_num_legs(check_disabled = TRUE)
	return 2

/mob/living/carbon/get_num_legs(check_disabled = TRUE)
	. = 0
	for(var/X in bodyparts)
		var/obj/item/bodypart/affecting = X
		if(affecting.body_part & (LEG_RIGHT|LEG_LEFT))
			if(!check_disabled || !affecting.bodypart_disabled)
				.++

//sometimes we want to ignore that we don't have the required amount of legs.
/mob/proc/get_leg_ignore()
	return FALSE

/mob/living/carbon/alien/larva/get_leg_ignore()
	return TRUE

/mob/living/carbon/human/get_leg_ignore()
	if(movement_type & (FLYING | FLOATING))
		return TRUE
	return FALSE

/mob/living/proc/get_missing_limbs()
	return list()

/mob/living/carbon/get_missing_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	for(var/zone in full)
		if(get_bodypart(zone))
			full -= zone
	return full

/mob/living/carbon/alien/larva/get_missing_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST)
	for(var/zone in full)
		if(get_bodypart(zone))
			full -= zone
	return full

/mob/living/proc/get_disabled_limbs()
	return list()

/mob/living/carbon/get_disabled_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	var/list/disabled = list()
	for(var/zone in full)
		var/obj/item/bodypart/affecting = get_bodypart(zone)
		if(affecting && affecting.bodypart_disabled)
			disabled += zone
	return disabled

/mob/living/carbon/alien/larva/get_disabled_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST)
	var/list/disabled = list()
	for(var/zone in full)
		var/obj/item/bodypart/affecting = get_bodypart(zone)
		if(affecting && affecting.bodypart_disabled)
			disabled += zone
	return disabled

//Remove all embedded objects from all limbs on the carbon mob
/mob/living/carbon/proc/remove_all_embedded_objects(silent = TRUE, forced = TRUE)
	var/turf/T = get_turf(src)
	for(var/obj/item/I in get_embedded_objects())
		remove_embedded_object(I, T, silent, forced)

/mob/living/carbon/proc/has_embedded_objects()
	. = FALSE
	for(var/X in bodyparts)
		var/obj/item/bodypart/L = X
		for(var/obj/item/I in L.embedded_objects)
			return TRUE


//Helper for quickly creating a new limb - used by augment code in species.dm spec_attacked_by
/mob/living/carbon/proc/newBodyPart(zone, robotic, fixed_icon)
	var/obj/item/bodypart/L
	switch(zone)
		if(BODY_ZONE_L_ARM)
			L = new /obj/item/bodypart/l_arm()
		if(BODY_ZONE_R_ARM)
			L = new /obj/item/bodypart/r_arm()
		if(BODY_ZONE_HEAD)
			L = new /obj/item/bodypart/head()
		if(BODY_ZONE_L_LEG)
			L = new /obj/item/bodypart/leg/left()
		if(BODY_ZONE_R_LEG)
			L = new /obj/item/bodypart/leg/right()
		if(BODY_ZONE_CHEST)
			L = new /obj/item/bodypart/chest()
	if((L.body_part & LEG_LEFT|LEG_RIGHT) && (DIGITIGRADE in dna?.species?.species_traits))
		L.set_digitigrade(TRUE)
	if(L)
		L.update_limb(fixed_icon, src)
		if(robotic)
			L.change_bodypart_status(BODYPART_ROBOTIC)
	. = L

/mob/living/carbon/monkey/newBodyPart(zone, robotic, fixed_icon)
	var/obj/item/bodypart/L
	switch(zone)
		if(BODY_ZONE_L_ARM)
			L = new /obj/item/bodypart/l_arm/monkey()
		if(BODY_ZONE_R_ARM)
			L = new /obj/item/bodypart/r_arm/monkey()
		if(BODY_ZONE_HEAD)
			L = new /obj/item/bodypart/head/monkey()
		if(BODY_ZONE_L_LEG)
			L = new /obj/item/bodypart/leg/left/monkey()
		if(BODY_ZONE_R_LEG)
			L = new /obj/item/bodypart/leg/right/monkey()
		if(BODY_ZONE_CHEST)
			L = new /obj/item/bodypart/chest/monkey()
	if(L)
		L.update_limb(fixed_icon, src)
		if(robotic)
			L.change_bodypart_status(BODYPART_ROBOTIC)
	. = L

/mob/living/carbon/alien/larva/newBodyPart(zone, robotic, fixed_icon)
	var/obj/item/bodypart/L
	switch(zone)
		if(BODY_ZONE_HEAD)
			L = new /obj/item/bodypart/head/larva()
		if(BODY_ZONE_CHEST)
			L = new /obj/item/bodypart/chest/larva()
	if(L)
		L.update_limb(fixed_icon, src)
		if(robotic)
			L.change_bodypart_status(BODYPART_ROBOTIC)
	. = L

/mob/living/carbon/alien/humanoid/newBodyPart(zone, robotic, fixed_icon)
	var/obj/item/bodypart/L
	switch(zone)
		if(BODY_ZONE_L_ARM)
			L = new /obj/item/bodypart/l_arm/alien()
		if(BODY_ZONE_R_ARM)
			L = new /obj/item/bodypart/r_arm/alien()
		if(BODY_ZONE_HEAD)
			L = new /obj/item/bodypart/head/alien()
		if(BODY_ZONE_L_LEG)
			L = new /obj/item/bodypart/leg/left/alien()
		if(BODY_ZONE_R_LEG)
			L = new /obj/item/bodypart/leg/right/alien()
		if(BODY_ZONE_CHEST)
			L = new /obj/item/bodypart/chest/alien()
	if(L)
		L.update_limb(fixed_icon, src)
		if(robotic)
			L.change_bodypart_status(BODYPART_ROBOTIC)
	. = L


/proc/skintone2hex(skin_tone)
	. = 0
	switch(skin_tone)
		if("caucasian1")
			. = "#ffe0d1"
		if("caucasian2")
			. = "#fcccb3"
		if("caucasian3")
			. = "#e8b59b"
		if("latino")
			. = "#d9ae96"
		if("mediterranean")
			. = "#c79b8b"
		if("asian1")
			. = "#ffdeb3"
		if("asian2")
			. = "#e3ba84"
		if("arab")
			. = "#c4915e"
		if("indian")
			. = "#b87840"
		if("mixed1")
			. = "#a57a66"
		if("mixed2")
			. = "#87563d"
		if("mixed3")
			. = "#725547"
		if("mixed4")
			. = "#866e63"
		if("african1")
			. = "#754523"
		if("african2")
			. = "#471c18"
		if("albino")
			. = "#fff4e6"
		if("orange")
			. = "#ffc905"
		if("green")
			. = "#a8e61d"

/mob/living/carbon/proc/digitigrade_leg_swap(swap_back)
	var/body_plan_changed = FALSE
	for(var/X in bodyparts)
		var/obj/item/bodypart/O = X
		var/obj/item/bodypart/N
		if((!O.use_digitigrade && swap_back == FALSE) || (O.use_digitigrade && swap_back == TRUE))
			if(O.body_part & LEG_LEFT)
				if(swap_back == TRUE)
					N = new /obj/item/bodypart/leg/left
				else
					N = new /obj/item/bodypart/leg/left/digitigrade
			else if(O.body_part & LEG_RIGHT)
				if(swap_back == TRUE)
					N = new /obj/item/bodypart/leg/right
				else
					N = new /obj/item/bodypart/leg/right/digitigrade
		if(!N)
			continue
		body_plan_changed = TRUE
		O.drop_limb(1)
		qdel(O)
		N.attach_limb(src)
	if(body_plan_changed && ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.w_uniform)
			H.update_inv_w_uniform()
		if(H.wear_suit)
			H.update_inv_wear_suit()
		if(H.shoes)
			if(!H.can_equip(H.shoes, ITEM_SLOT_FEET, TRUE))
				H.dropItemToGround(H.shoes)
			else
				H.update_inv_shoes()
