
#define DUALWIELD_PENALTY_EXTRA_MULTIPLIER 1.4

/obj/item/gun
	name = "gun"
	desc = "It's a gun. It's pretty terrible, though."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "detective"
	item_state = "gun"
	flags_1 =  CONDUCT_1
	obj_flags = UNIQUE_RENAME
	slot_flags = ITEM_SLOT_BELT
	materials = list(/datum/material/iron=2000)
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	force = 5
	item_flags = NEEDS_PERMIT
	attack_verb = list("struck", "hit", "bashed")
	cryo_preserve = TRUE
	fryable = TRUE

	var/fire_sound = "gunshot"
	var/vary_fire_sound = TRUE
	var/fire_sound_volume = 50
	var/dry_fire_sound = 'sound/weapons/gun_dry_fire.ogg'
	var/obj/item/suppressor/suppressed	//whether or not a message is displayed when fired
	var/obj/item/enloudener/enloudened	//whether or not an additional sound is played
	var/can_suppress = FALSE
	var/suppressed_sound = 'sound/weapons/gunshot_silenced.ogg'
	var/suppressed_volume = 10
	var/can_unsuppress = TRUE
	var/recoil = 0					//boom boom shake the room
	var/clumsy_check = TRUE
	var/obj/item/ammo_casing/chambered = null
	trigger_guard = TRIGGER_GUARD_NORMAL//trigger guard on the weapon, hulks can't fire them with their big meaty fingers
	var/sawn_desc = null				//description change if weapon is sawn-off
	var/sawn_off = FALSE
	var/burst_size = 1					//how large a burst is
	var/fire_delay = 0					//rate of fire for burst firing and semi auto
	var/firing_burst = 0				//Prevent the weapon from firing again while already firing
	var/semicd = 0						//cooldown handler
	var/weapon_weight = WEAPON_LIGHT
	var/spread = 5						//Spread induced by the gun itself. SEE LINE BELOW.
	var/default_spread = 5				//MUST be equal to the value above; used to calculate adjustments for if semi-auto is used on a burst weapon.
	var/randomspread = 1				//Set to 0 for shotguns. This is used for weapons that don't fire all their bullets at once.

	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'

	var/obj/item/firing_pin/pin = /obj/item/firing_pin //standard firing pin for most guns
	var/no_pin_required = FALSE //whether the gun can be fired without a pin

	var/can_flashlight = FALSE //if a flashlight can be added or removed if it already has one.
	var/obj/item/flashlight/seclite/gun_light
	var/mutable_appearance/flashlight_overlay
	var/datum/action/item_action/toggle_gunlight/alight

	var/can_bayonet = FALSE //if a bayonet can be added or removed if it already has one.
	var/obj/item/kitchen/knife/bayonet
	var/mutable_appearance/knife_overlay
	var/knife_x_offset = 0
	var/knife_y_offset = 0

	var/list/available_attachments = list() // What attachments can this gun have
	var/max_attachments = 0 // How many attachments can this gun hold, recommend not going over 5

	var/list/current_attachments = list()
	var/list/attachment_overlays = list()
	var/attachment_flags = 0
	var/attachment_actions = list()

	var/ammo_x_offset = 0 //used for positioning ammo count overlay on sprite
	var/ammo_y_offset = 0
	var/flight_x_offset = 0
	var/flight_y_offset = 0

	//Zooming
	var/zoomable = FALSE //whether the gun generates a Zoom action on creation
	var/zoomed = FALSE //Zoom toggle
	var/zoom_amt = 3 //Distance in TURFs to move the user's screen forward (the "zoom" effect)
	var/zoom_out_amt = 0
	var/datum/action/toggle_scope_zoom/azoom
	var/recent_shoot = null //time of the last shot with the gun. Used to track if firing happened for feedback out of all things

	var/list/obj/effect/projectile/tracer/current_tracers

/obj/item/gun/Initialize()
	. = ..()
	if(pin)
		if(no_pin_required)
			pin = null
		else
			pin = new pin(src)
	if(gun_light)
		alight = new(src)
	current_tracers = list()
	build_zooming()

/obj/item/gun/Destroy()
	if(isobj(pin)) //Can still be the initial path, then we skip
		QDEL_NULL(pin)
	if(gun_light)
		QDEL_NULL(gun_light)
	if(bayonet)
		QDEL_NULL(bayonet)
	if(chambered) //Not all guns are chambered (EMP'ed energy guns etc)
		QDEL_NULL(chambered)
	if(azoom)
		QDEL_NULL(azoom)
	return ..()

//ALL GUNS ARE NOW STAFF OF THE HONKMOTHER HONK
/obj/item/gun/honk_act()
	new /obj/item/gun/magic/staff/honk(src.loc)
	qdel(src)

/obj/item/gun/handle_atom_del(atom/A)
	if(A == pin)
		pin = null
	if(A == chambered)
		chambered = null
		update_icon()
	if(A == bayonet)
		clear_bayonet()
	if(A == gun_light)
		clear_gunlight()
	if(A in current_attachments)
		var/obj/item/attachment/T = A
		T.on_detach(src)
		
	return ..()

/obj/item/gun/CheckParts(list/parts_list)
	..()
	var/obj/item/gun/G = locate(/obj/item/gun) in contents
	if(G)
		G.forceMove(loc)
		var/pin = G.pin
		if(!pin)
			visible_message("[G] has no pin to remove.", null, null, 3)
		if(pin && G.pin.gun_remove()) //if this returns false the gun and pin are not going to exist
			visible_message("[G] can now fit a new pin, but the old one was destroyed in the process.", null, null, 3)
			QDEL_NULL(pin)
		qdel(src)

/obj/item/gun/examine(mob/user)
	. = ..()
	if(!no_pin_required)
		if(pin)
			. += "It has \a [pin] installed."
		else
			. += "It doesn't have a <b>firing pin</b> installed, and won't fire."

	if(gun_light)
		. += "It has \a [gun_light] [can_flashlight ? "" : "permanently "]mounted on it."
		if(can_flashlight) //if it has a light and this is false, the light is permanent.
			. += span_info("[gun_light] looks like it can be <b>unscrewed</b> from [src].")
	else if(can_flashlight)
		. += "It has a mounting point for a <b>seclite</b>."

	if(bayonet)
		. += "It has \a [bayonet] [can_bayonet ? "" : "permanently "]affixed to it."
		if(can_bayonet) //if it has a bayonet and this is false, the bayonet is permanent.
			. += span_info("[bayonet] looks like it can be <b>unscrewed</b> from [src].")
	else if(can_bayonet)
		. += "It has a <b>bayonet</b> lug on it."
	
	for(var/obj/item/attachment/A in current_attachments)
		. += "It has \a [A] affixed to it."

/obj/item/gun/equipped(mob/living/user, slot)
	. = ..()
	for(var/obj/item/attachment/A in current_attachments)
		A.set_user(user)
		if(user.is_holding(src))
			A.pickup_user(user)
		else
			A.equip_user(user)
	if(zoomed && user.get_active_held_item() != src)
		zoom(user, user.dir, FALSE) //we can only stay zoomed in if it's in our hands	//yeah and we only unzoom if we're actually zoomed using the gun!!

//called after the gun has successfully fired its chambered ammo.
/obj/item/gun/proc/process_chamber()
	return FALSE

//check if there's enough ammo/energy/whatever to shoot one time
//i.e if clicking would make it shoot
/obj/item/gun/proc/can_shoot()
	return TRUE

/obj/item/gun/proc/shoot_with_empty_chamber(mob/living/user as mob|obj)
	to_chat(user, span_danger("*click*"))
	playsound(src, dry_fire_sound, 30, TRUE)


/obj/item/gun/proc/shoot_live_shot(mob/living/user, pointblank = 0, atom/pbtarget = null, message = 1)
	if(recoil > 0)
		shake_camera(user, recoil + 1, recoil)

	if(suppressed)
		playsound(user, suppressed_sound, suppressed_volume, vary_fire_sound)
		if(istype(suppressed) && suppressed.break_chance && prob(suppressed.break_chance))
			to_chat(user, span_warning("\the [suppressed] falls apart!"))
			w_class -= suppressed.w_class
			qdel(suppressed)
			suppressed = null
			update_icon()
	else
		if(enloudened && enloudened.enloudened_sound)
			playsound(user, enloudened.enloudened_sound, fire_sound_volume, vary_fire_sound)
		playsound(user, fire_sound, fire_sound_volume, vary_fire_sound)
		if(message)
			if(pointblank)
				user.visible_message(span_danger("[user] fires [src] point blank at [pbtarget]!"), null, null, COMBAT_MESSAGE_RANGE)
			else
				user.visible_message(span_danger("[user] fires [src]!"), null, null, COMBAT_MESSAGE_RANGE)

/obj/item/gun/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_CONTENTS))
		for(var/obj/O in contents)
			O.emp_act(severity)

/obj/item/gun/afterattack(atom/target, mob/living/user, flag, params)
	. = ..()
	if(!target)
		return
	if(firing_burst)
		return
	if(flag) //It's adjacent, is the user, or is on the user's person
		if(target in user.contents) //can't shoot stuff inside us.
			return
		if(!ismob(target) || user.a_intent == INTENT_HARM) //melee attack
			return
		if(target == user && user.zone_selected != BODY_ZONE_PRECISE_MOUTH) //so we can't shoot ourselves (unless mouth selected)
			return
		if(ismob(target) && user.a_intent == INTENT_GRAB && !istype(user.mind.martial_art, /datum/martial_art/ultra_violence))//remove gunpoint from ipc martial art, it's slow
			for(var/datum/component/gunpoint/G in user.GetComponents(/datum/component/gunpoint))
				if(G && G.weapon == src) //spam check
					return
			user.AddComponent(/datum/component/gunpoint, target, src)
			return
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			for(var/i in C.all_wounds)
				var/datum/wound/W = i
				if(W.try_treating(src, user))
					return // another coward cured!

	if(istype(user))//Check if the user can use the gun, if the user isn't alive(turrets) assume it can.
		var/mob/living/L = user
		if(!can_trigger_gun(L))
			return

	if(flag)
		if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
			handle_suicide(user, target, params)
			return

	if(!can_shoot()) //Just because you can pull the trigger doesn't mean it can shoot.
		shoot_with_empty_chamber(user)
		return

	//Exclude lasertag guns from the TRAIT_CLUMSY check.
	if(check_botched(user))
		return

	if(weapon_weight == WEAPON_HEAVY && user.get_inactive_held_item())
		to_chat(user, span_userdanger("You need both hands free to fire \the [src]!"))
		return

	//DUAL (or more!) WIELDING
	var/bonus_spread = 0
	var/cd_mod = CLICK_CD_RANGE
	if(chambered?.click_cooldown_override)
		cd_mod = chambered.click_cooldown_override
	
	if(ishuman(user) && user.a_intent == INTENT_HARM)
		var/mob/living/carbon/human/H = user
		if(weapon_weight < WEAPON_MEDIUM && istype(H.held_items[H.get_inactive_hand_index()], /obj/item/gun) && can_trigger_gun(user))
			bonus_spread += 18 * weapon_weight
			cd_mod = cd_mod * 0.75
			H.swap_hand()

	process_fire(target, user, TRUE, params, null, bonus_spread, cd_mod)

/obj/item/gun/proc/check_botched(mob/living/user, params)
	if(clumsy_check)
		if(istype(user))
			if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(40))
				to_chat(user, span_userdanger("You shoot yourself in the foot with [src]!"))
				var/shot_leg = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				process_fire(user, user, FALSE, params, shot_leg)
				user.dropItemToGround(src, TRUE)
				return TRUE

/obj/item/gun/can_trigger_gun(mob/living/user)
	. = ..()
	if(!handle_pins(user))
		return FALSE

/obj/item/gun/proc/handle_pins(mob/living/user)
	if(no_pin_required)
		return TRUE
	if(pin)
		if(pin.pin_auth(user) || (pin.obj_flags & EMAGGED))
			return TRUE
		else
			pin.auth_fail(user)
			return FALSE
	else
		to_chat(user, span_warning("[src]'s trigger is locked. This weapon doesn't have a firing pin installed!"))
	return FALSE

/obj/item/gun/proc/recharge_newshot()
	return

/obj/item/gun/proc/process_burst(mob/living/user, atom/target, message = TRUE, params=null, zone_override = "", sprd = 0, randomized_gun_spread = 0, randomized_bonus_spread = 0, rand_spr = 0, iteration = 0)
	if(!user || !firing_burst)
		firing_burst = FALSE
		return FALSE
	if(!issilicon(user))
		if(iteration > 1 && !(user.is_holding(src))) //for burst firing
			firing_burst = FALSE
			return FALSE
	if(chambered && chambered.BB)
		if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
			if(chambered.harmful) // Is the bullet chambered harmful?
				to_chat(user, span_notice(" [src] is lethally chambered! You don't want to risk harming anyone..."))
				return
		if(randomspread)
			sprd = round((rand() - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * (randomized_gun_spread + randomized_bonus_spread))
		else //Smart spread
			sprd = round((((rand_spr/burst_size) * iteration) - (0.5 + (rand_spr * 0.25))) * (randomized_gun_spread + randomized_bonus_spread))
		before_firing(target,user)
		if(!chambered.fire_casing(target, user, params, ,suppressed, zone_override, sprd, src))
			shoot_with_empty_chamber(user)
			firing_burst = FALSE
			return FALSE
		else
			if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
				shoot_live_shot(user, 1, target, message)
			else
				shoot_live_shot(user, 0, target, message)
			if (iteration >= burst_size)
				firing_burst = FALSE
	else
		shoot_with_empty_chamber(user)
		firing_burst = FALSE
		return FALSE
	process_chamber()
	update_icon()
	return TRUE

/// cd_override is FALSE or 0 by default (no override), if you want to make a gun have no click cooldown then just make it something small like 0.001
/obj/item/gun/proc/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, cd_override = FALSE)
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN, user, target, params, zone_override)

	for(var/obj/item/attachment/A in current_attachments)
		A.on_gun_fire(src)

	add_fingerprint(user)

	if(semicd)
		return

	var/sprd = 0
	var/randomized_gun_spread = 0
	var/rand_spr = rand()
	if(spread > 0)
		randomized_gun_spread =	rand(0,spread)
	if(ishuman(user)) //nice shootin' tex
		var/mob/living/carbon/human/H = user
		bonus_spread += H.dna.species.aiminginaccuracy
	var/randomized_bonus_spread = rand(0, bonus_spread)

	if(burst_size > 1)
		firing_burst = TRUE
		for(var/i = 1 to burst_size)
			addtimer(CALLBACK(src, .proc/process_burst, user, target, message, params, zone_override, sprd, randomized_gun_spread, randomized_bonus_spread, rand_spr, i), fire_delay * (i - 1))
	else
		if(chambered)
			if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
				if(chambered.harmful) // Is the bullet chambered harmful?
					to_chat(user, span_notice(" [src] is lethally chambered! You don't want to risk harming anyone..."))
					return
			sprd = round((rand() - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * (randomized_gun_spread + randomized_bonus_spread))
			before_firing(target,user)
			if(!chambered.fire_casing(target, user, params, , suppressed, zone_override, sprd, src, cd_override))
				shoot_with_empty_chamber(user)
				return
			else
				if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
					shoot_live_shot(user, 1, target, message)
				else
					shoot_live_shot(user, 0, target, message)
		else
			shoot_with_empty_chamber(user)
			return
		process_chamber()
		update_icon()
		semicd = TRUE
		addtimer(CALLBACK(src, .proc/reset_semicd), fire_delay)

	if(user)
		user.update_inv_hands()
	SSblackbox.record_feedback("tally", "gun_fired", 1, type)
	recent_shoot = world.time
	return TRUE

/obj/item/gun/update_icon()
	..()


/obj/item/gun/proc/reset_semicd()
	semicd = FALSE

/obj/item/gun/attack(mob/M as mob, mob/user)
	if(user.a_intent == INTENT_HARM) //Flogging
		if(bayonet)
			M.attackby(bayonet, user)
			return
		else
			return ..()
	return

/obj/item/gun/attack_obj(obj/O, mob/user)
	if(user.a_intent == INTENT_HARM)
		if(bayonet)
			O.attackby(bayonet, user)
			return
	return ..()

/obj/item/gun/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	else if (istype(I, /obj/item/attachment))
		var/support = FALSE

		for(var/n in available_attachments)
			if(istype(I, n))
				support = TRUE
				break

		if(!support)
			to_chat(user, span_warning("\The [src] does not support \the [I]!"))
			return ..()

		var/already_has = FALSE
		for(var/n in current_attachments)
			if(istype(I, n))
				already_has = TRUE
				break
		
		if(already_has)
			to_chat(user, span_warning("\The [src] already has \a [I]!"))
			return ..()
		
		if(LAZYLEN(current_attachments) >= max_attachments)
			to_chat(user, span_warning("\The [src] has no more room for any more attachments!"))
			return ..()

		var/obj/item/attachment/A = I

		if(A.attachment_type != 0 && ((attachment_flags &= A.attachment_type) != 0))
			to_chat(user, span_warning("\The [src] does not have any available places to attach \the [I] onto!"))
			return ..()

		to_chat(user, span_notice("You [A.attach_verb] \the [I] into place on [src]."))
		A.on_attach(src, user)

	else if(istype(I, /obj/item/flashlight/seclite))
		if(!can_flashlight)
			return ..()
		var/obj/item/flashlight/seclite/S = I
		if(!gun_light)
			if(!user.transferItemToLoc(I, src))
				return
			to_chat(user, span_notice("You click [S] into place on [src]."))
			set_gun_light(S)
			update_gunlight()
			alight = new(src)
			if(loc == user)
				alight.Grant(user)
	else if(istype(I, /obj/item/kitchen/knife))
		var/obj/item/kitchen/knife/K = I
		if(!can_bayonet || !K.bayonet || bayonet) //ensure the gun has an attachment point available, and that the knife is compatible with it.
			return ..()
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, span_notice("You attach [K] to [src]'s bayonet lug."))
		bayonet = K
		var/state = "bayonet"							//Generic state.
		if(bayonet.icon_state in icon_states('icons/obj/guns/bayonets.dmi'))		//Snowflake state?
			state = bayonet.icon_state
		var/icon/bayonet_icons = 'icons/obj/guns/bayonets.dmi'
		knife_overlay = mutable_appearance(bayonet_icons, state)
		knife_overlay.pixel_x = knife_x_offset
		knife_overlay.pixel_y = knife_y_offset
		add_overlay(knife_overlay, TRUE)
	else
		return ..()

/obj/item/gun/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	
	var/has_fl = FALSE
	var/has_bayo = FALSE
	var/amt_modular = LAZYLEN(current_attachments)
	if(can_flashlight && gun_light)
		has_fl = TRUE
	if(bayonet && can_bayonet)
		has_bayo = TRUE
	
	var/attachments_amt = amt_modular + has_fl + has_bayo
	if(attachments_amt > 1) //give them a choice instead of removing both
		var/list/possible_items = list(gun_light, bayonet)
		possible_items += current_attachments
		var/obj/item/item_to_remove = input(user, "Select an attachment to remove", "Attachment Removal") as null|obj in possible_items
		if(!item_to_remove || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
			return
		return remove_gun_attachment(user, I, item_to_remove)

	else if(amt_modular == 1)
		return remove_gun_attachment(user, I, current_attachments[1], "unscrewed")

	else if(has_fl) //if it has a gun_light and can_flashlight is false, the flashlight is permanently attached.
		return remove_gun_attachment(user, I, gun_light, "unscrewed")

	else if(has_bayo) //if it has a bayonet, and the bayonet can be removed
		return remove_gun_attachment(user, I, bayonet, "unfix")

/obj/item/gun/proc/remove_gun_attachment(mob/living/user, obj/item/tool_item, obj/item/item_to_remove, removal_verb)
	if(tool_item)
		tool_item.play_tool_sound(src)
	to_chat(user, span_notice("You [removal_verb ? removal_verb : "remove"] [item_to_remove] from [src]."))
	item_to_remove.forceMove(drop_location())

	if(Adjacent(user) && !issilicon(user))
		user.put_in_hands(item_to_remove)

	if(istype(item_to_remove, /obj/item/attachment))
		var/obj/item/attachment/A = item_to_remove
		return A.on_detach(src, user)

	if(item_to_remove == bayonet)
		return clear_bayonet()
	else if(item_to_remove == gun_light)
		return clear_gunlight()

/obj/item/gun/proc/clear_bayonet()
	if(!bayonet)
		return
	bayonet = null
	if(knife_overlay)
		cut_overlay(knife_overlay, TRUE)
		knife_overlay = null
	return TRUE

/obj/item/gun/proc/clear_gunlight()
	if(!gun_light)
		return
	var/obj/item/flashlight/seclite/removed_light = gun_light
	set_gun_light(null)
	update_gunlight()
	removed_light.update_brightness()
	QDEL_NULL(alight)
	return TRUE

///Called when gun_light value changes.
/obj/item/gun/proc/set_gun_light(obj/item/flashlight/seclite/new_light)
	if(gun_light == new_light)
		return
	. = gun_light
	gun_light = new_light
	if(gun_light)
		gun_light.set_light_flags(gun_light.light_flags | LIGHT_ATTACHED)
		if(gun_light.loc != src)
			gun_light.forceMove(src)
	else if(.)
		var/obj/item/flashlight/seclite/old_gun_light = .
		old_gun_light.set_light_flags(old_gun_light.light_flags & ~LIGHT_ATTACHED)
		if(old_gun_light.loc == src)
			old_gun_light.forceMove(get_turf(src))

/obj/item/gun/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, alight))
		toggle_gunlight()
	else
		..()

/obj/item/gun/proc/toggle_gunlight()
	if(!gun_light)
		return

	var/mob/living/carbon/human/user = usr
	gun_light.on = !gun_light.on
	gun_light.update_brightness()
	to_chat(user, span_notice("You toggle the gunlight [gun_light.on ? "on":"off"]."))

	playsound(user, 'sound/weapons/empty.ogg', 100, TRUE)
	update_gunlight()

/obj/item/gun/proc/update_gunlight()
	if(gun_light)
		cut_overlay(flashlight_overlay, TRUE)
		var/state = "flight[gun_light.on? "_on":""]"	//Generic state.
		if(gun_light.icon_state in icon_states('icons/obj/guns/flashlights.dmi'))	//Snowflake state?
			state = gun_light.icon_state
		flashlight_overlay = mutable_appearance('icons/obj/guns/flashlights.dmi', state)
		flashlight_overlay.pixel_x = flight_x_offset
		flashlight_overlay.pixel_y = flight_y_offset
		add_overlay(flashlight_overlay, TRUE)
	else
		set_light_on(FALSE)
		cut_overlay(flashlight_overlay, TRUE)
		flashlight_overlay = null
	update_icon()
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/gun/proc/update_attachments()
	for(var/mutable_appearance/M in attachment_overlays)
		cut_overlay(M, TRUE)
	attachment_overlays = list()

	var/att_position = 0
	for(var/obj/item/attachment/A in current_attachments)
		var/mutable_appearance/M = mutable_appearance('icons/obj/guns/attachment.dmi', "[A.icon_state]_a")
		M.pixel_x = att_position * 6
		add_overlay(M, TRUE)
		attachment_overlays += M
		att_position += 1

	update_icon(TRUE)
	for(var/datum/action/A as anything in actions)
		A.UpdateButtonIcon()

/obj/item/gun/pickup(mob/user)
	..()
	for(var/obj/item/attachment/A in current_attachments)
		A.set_user(user)
		A.pickup_user(user)
	for(var/datum/action/att_act in attachment_actions)
		att_act.Grant(user)
	if(azoom)
		azoom.Grant(user)

/obj/item/gun/dropped(mob/user)
	. = ..()
	for(var/obj/item/attachment/A in current_attachments)
		A.set_user()
		A.drop_user(user)
	for(var/datum/action/att_act in attachment_actions)
		att_act.Remove(user)
	if(azoom)
		azoom.Remove(user)
	if(zoomed)
		zoom(user, user.dir)

/obj/item/gun/proc/handle_suicide(mob/living/carbon/human/user, mob/living/carbon/human/target, params, bypass_timer)
	if(!ishuman(user) || !ishuman(target))
		return

	if(semicd)
		return

	if(user == target)
		target.visible_message(span_warning("[user] sticks [src] in [user.p_their()] mouth, ready to pull the trigger..."), \
			span_userdanger("You stick [src] in your mouth, ready to pull the trigger..."))
	else
		target.visible_message(span_warning("[user] points [src] at [target]'s head, ready to pull the trigger..."), \
			span_userdanger("[user] points [src] at your head, ready to pull the trigger..."))

	semicd = TRUE

	if(!bypass_timer && (!do_mob(user, target, 120) || user.zone_selected != BODY_ZONE_PRECISE_MOUTH))
		if(user)
			if(user == target)
				user.visible_message(span_notice("[user] decided not to shoot."))
			else if(target && target.Adjacent(user))
				target.visible_message(span_notice("[user] has decided to spare [target]"), span_notice("[user] has decided to spare your life!"))
		semicd = FALSE
		return

	semicd = FALSE

	if(user == target && user.has_horror_inside())
		user.visible_message(span_warning("[user] decided not to shoot."), span_notice("Something inside your head stops your action!"))
		return

	target.visible_message(span_warning("[user] pulls the trigger!"), span_userdanger("[(user == target) ? "You pull" : "[user] pulls"] the trigger!"))

	if(chambered && chambered.BB)
		chambered.BB.damage *= 5
		if(chambered.BB.wound_bonus != CANT_WOUND)
			chambered.BB.wound_bonus += 5

	var/fired = process_fire(target, user, TRUE, params, BODY_ZONE_HEAD)
	if(!fired && chambered?.BB)
		chambered.BB.damage /= 5
		if(chambered.BB.wound_bonus != CANT_WOUND)
			chambered.BB.wound_bonus -= 5

/obj/item/gun/proc/unlock() //used in summon guns and as a convience for admins
	if(pin)
		qdel(pin)
	pin = new /obj/item/firing_pin

//Happens before the actual projectile creation
/obj/item/gun/proc/before_firing(atom/target,mob/user)
	return

/////////////
// ZOOMING //
/////////////

/datum/action/toggle_scope_zoom
	name = "Toggle Scope"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_LYING
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	var/obj/item/gun/gun = null

/datum/action/toggle_scope_zoom/Trigger()
	gun.zoom(owner, owner.dir)

/datum/action/toggle_scope_zoom/IsAvailable()
	. = ..()
	if(!. && gun)
		gun.zoom(owner, owner.dir, FALSE)

/datum/action/toggle_scope_zoom/Remove(mob/living/L)
	gun.zoom(L, L.dir, FALSE)
	..()

/obj/item/gun/proc/rotate(atom/thing, old_dir, new_dir)
	if(ismob(thing))
		var/mob/lad = thing
		lad.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)

/obj/item/gun/proc/zoom(mob/living/user, direc, forced_zoom)
	if(!user || !user.client)
		return

	switch(forced_zoom)
		if(FALSE)
			zoomed = FALSE
		if(TRUE)
			zoomed = TRUE
		else
			zoomed = !zoomed

	if(zoomed)
		RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, .proc/rotate)
		user.client.view_size.zoomOut(zoom_out_amt, zoom_amt, direc)
	else
		UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
		user.client.view_size.zoomIn()
	return zoomed

//Proc, so that gun accessories/scopes/etc. can easily add zooming.
/obj/item/gun/proc/build_zooming()
	if(azoom)
		return

	if(zoomable)
		azoom = new()
		azoom.gun = src
