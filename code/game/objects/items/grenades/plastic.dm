/obj/item/grenade/plastic
	name = "plastic explosive"
	desc = "Used to put holes in specific areas without too much extra hole."
	icon_state = "plastic-explosive0"
	item_state = "plastic-explosive"
	lefthand_file = 'icons/mob/inhands/weapons/bombs_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/bombs_righthand.dmi'
	item_flags = NOBLUDGEON
	flags_1 = NONE
	det_time = 10
	display_timer = 0
	w_class = WEIGHT_CLASS_SMALL
	var/atom/target = null
	var/mutable_appearance/plastic_overlay
	var/obj/item/assembly_holder/nadeassembly = null
	var/assemblyattacher
	var/directional = FALSE
	var/aim_dir = NORTH
	var/boom_sizes = list(0, 0, 3)
	var/can_attach_mob = FALSE
	var/full_damage_on_mobs = FALSE
	var/alert_admins = TRUE

/obj/item/grenade/plastic/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_EMPPROOF_CONTENTS, "innate_empproof")
	plastic_overlay = mutable_appearance(icon, "[item_state]2", ABOVE_ALL_MOB_LAYER)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/item/grenade/plastic/Destroy()
	qdel(nadeassembly)
	if(target)
		UnregisterSignal(target, COMSIG_ATOM_UPDATE_OVERLAYS)
		target.update_appearance()
		target = null
	nadeassembly = null
	return ..()

/obj/item/grenade/plastic/attackby(obj/item/I, mob/user, params)
	if(!nadeassembly && istype(I, /obj/item/assembly_holder))
		var/obj/item/assembly_holder/A = I
		if(!user.transferItemToLoc(I, src))
			return ..()
		nadeassembly = A
		A.master = src
		assemblyattacher = user.ckey
		to_chat(user, span_notice("You add [A] to the [name]."))
		playsound(src, 'sound/weapons/tap.ogg', 20, 1)
		update_appearance(UPDATE_ICON)
		return
	if(nadeassembly && I.tool_behaviour == TOOL_WIRECUTTER)
		I.play_tool_sound(src, 20)
		nadeassembly.forceMove(get_turf(src))
		nadeassembly.master = null
		nadeassembly = null
		update_appearance(UPDATE_ICON)
		return
	return ..()

/obj/item/grenade/plastic/prime()
	var/turf/location
	var/density_check = FALSE
	if(target)
		if(!QDELETED(target))
			location = get_turf(target)
			density_check = target.density //since turfs getting exploded makes this a bit fucky wucky we need to assert whether we should go directional before that part
			target.cut_overlay(plastic_overlay, TRUE)
			if(!ismob(target) || full_damage_on_mobs)
				target.ex_act(2, target)
	else
		location = get_turf(src)
	if(location)
		if(directional && target && density_check)
			var/turf/T = get_step(location, aim_dir)
			explosion(get_step(T, aim_dir), boom_sizes[1], boom_sizes[2], boom_sizes[3])
		else
			explosion(location, boom_sizes[1], boom_sizes[2], boom_sizes[3])
	if(isliving(target))
		var/mob/living/M = target
		M.gib()
	qdel(src)

//assembly stuff
/obj/item/grenade/plastic/receive_signal()
	prime()

/obj/item/grenade/plastic/proc/on_entered(datum/source, atom/movable/AM, ...)
	if(nadeassembly)
		nadeassembly.Crossed(AM)

/obj/item/grenade/plastic/on_found(mob/finder)
	if(nadeassembly)
		nadeassembly.on_found(finder)

/obj/item/grenade/plastic/attack_self(mob/user)
	if(nadeassembly)
		nadeassembly.attack_self(user)
		return
	var/newtime = input(usr, "Please set the timer.", "Timer", 10) as num
	if(user.get_active_held_item() == src)
		newtime = clamp(newtime, 10, 60000)
		det_time = newtime
		to_chat(user, "Timer set for [det_time] seconds.")

/obj/item/grenade/plastic/afterattack(atom/movable/AM, mob/user, flag, notify_ghosts = TRUE)
	. = ..()
	aim_dir = get_dir(user,AM)
	if(!flag)
		return
	if(ismob(AM) && !can_attach_mob)
		return
	if(AM.GetComponent(/datum/component/storage))
		var/fuckup_safety = tgui_alert(user, "Doing this will arm the explosive and attach it to the [AM.name], not put it inside. Are you sure you want to do this?", "Are you sure?", list("Yes", "No"))
		if(fuckup_safety != "Yes")
			return

	to_chat(user, span_notice("You start planting [src]. The timer is set to [det_time]..."))

	if(do_after(user, 3 SECONDS, AM))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return
		target = AM

		if(alert_admins)
			message_admins("[ADMIN_LOOKUPFLW(user)] planted [name] on [target.name] at [ADMIN_VERBOSEJMP(target)] with [det_time] second fuse")
		log_game("[key_name(user)] planted [name] on [target.name] at [AREACOORD(user)] with a [det_time] second fuse")

		if(notify_ghosts)
			notify_ghosts("[user] has planted \a [src] on [target] with a [det_time] second fuse!", source = target, action = NOTIFY_JUMP, header = "Bomb Planted" )

		moveToNullspace()	//Yep

		if(istype(AM, /obj/item)) //your crappy throwing star can't fly so good with a giant brick of c4 on it.
			var/obj/item/I = AM
			I.throw_speed = max(1, (I.throw_speed - 3))
			I.throw_range = max(1, (I.throw_range - 3))
			I.embedding = I.embedding.setRating(embed_chance = 0)

		RegisterSignal(target, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_attached_overlays))
		target.update_appearance(UPDATE_OVERLAYS)
		if(!nadeassembly)
			to_chat(user, span_notice("You plant the bomb. Timer counting down from [det_time]."))
			addtimer(CALLBACK(src, PROC_REF(prime)), det_time*10)
		else
			qdel(src)	//How?

/obj/item/grenade/plastic/proc/update_attached_overlays(atom/source, list/overlay_list)
	overlay_list += plastic_overlay

/obj/item/grenade/plastic/proc/shout_syndicate_crap(mob/M)
	if(!M)
		return
	var/message_say = "FOR NO RAISIN!"
	if(M.mind)
		var/datum/mind/UM = M.mind
		if(UM.has_antag_datum(/datum/antagonist/nukeop) || UM.has_antag_datum(/datum/antagonist/traitor))
			message_say = "FOR THE SYNDICATE!"
		else if(UM.has_antag_datum(/datum/antagonist/changeling))
			message_say = "FOR THE HIVE!"
		else if(UM.has_antag_datum(/datum/antagonist/cult))
			message_say = "FOR NAR-SIE!"
		else if(UM.has_antag_datum(/datum/antagonist/clockcult))
			message_say = "FOR RATVAR!"
		else if(UM.has_antag_datum(/datum/antagonist/rev))
			message_say = "VIVA LA REVOLUTION!"
	M.say(message_say, forced="C4 suicide")

/obj/item/grenade/plastic/suicide_act(mob/living/user)
	message_admins("[ADMIN_LOOKUPFLW(user)] suicided with [src] at [ADMIN_VERBOSEJMP(user)]")
	log_game("[key_name(user)] suicided with [src] at [AREACOORD(user)]")
	user.visible_message(span_suicide("[user] activates [src] and holds it above [user.p_their()] head! It looks like [user.p_theyre()] going out with a bang!"))
	shout_syndicate_crap(user)
	explosion(user,0,2,0) //Cheap explosion imitation because putting prime() here causes runtimes
	user.gib(1, 1)
	qdel(src)

/obj/item/grenade/plastic/update_icon_state()
	. = ..()
	if(nadeassembly)
		icon_state = "[item_state]1"
	else
		icon_state = "[item_state]0"

//////////////////////////
///// The Explosives /////
//////////////////////////

/obj/item/grenade/plastic/c4
	name = "C4"
	desc = "Used to put holes in specific areas without too much extra hole. A saboteur's favorite."
	gender = PLURAL
	var/open_panel = 0
	can_attach_mob = TRUE

/obj/item/grenade/plastic/c4/Initialize(mapload)
	. = ..()
	wires = new /datum/wires/explosive/c4(src)

/obj/item/grenade/plastic/c4/Destroy()
	qdel(wires)
	if(target)
		UnregisterSignal(target, COMSIG_ATOM_UPDATE_OVERLAYS)
		target.update_appearance(UPDATE_OVERLAYS)
	wires = null
	target = null
	return ..()

/obj/item/grenade/plastic/c4/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] activates the [src.name] and holds it above [user.p_their()] head! It looks like [user.p_theyre()] going out with a bang!"))
	shout_syndicate_crap(user)
	target = user
	message_admins("[ADMIN_LOOKUPFLW(user)] suicided with [name] at [ADMIN_VERBOSEJMP(src)]")
	log_game("[key_name(user)] suicided with [name] at [AREACOORD(user)]")
	sleep(1 SECONDS)
	prime()
	user.gib(1, 1)

/obj/item/grenade/plastic/c4/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		open_panel = !open_panel
		to_chat(user, span_notice("You [open_panel ? "open" : "close"] the wire panel."))
	else if(is_wire_tool(I))
		wires.interact(user)
	else
		return ..()

/obj/item/grenade/plastic/c4/prime()
	if(QDELETED(src))
		return
	var/turf/location
	if(target)
		if(!QDELETED(target))
			location = get_turf(target)
			target.cut_overlay(plastic_overlay, TRUE)
			if(!ismob(target) || full_damage_on_mobs)
				target.ex_act(EXPLODE_HEAVY, target)
	else
		location = get_turf(src)
	if(location)
		explosion(location,0,0,3)
	qdel(src)

/obj/item/grenade/plastic/c4/attack(mob/M, mob/user, def_zone)
	return

// X4 is an upgraded directional variant of c4 which is relatively safe to be standing next to. And much less safe to be standing on the other side of.
// C4 is intended to be used for infiltration, and destroying tech. X4 is intended to be used for heavy breaching and tight spaces.
// Intended to replace C4 for nukeops, and to be a randomdrop in surplus/random traitor purchases.

/obj/item/grenade/plastic/x4
	name = "X4"
	desc = "A shaped high-explosive breaching charge. Designed to ensure user safety and wall nonsafety."
	icon_state = "plasticx40"
	item_state = "plasticx4"
	gender = PLURAL
	directional = TRUE
	boom_sizes = list(0, 2, 5)
