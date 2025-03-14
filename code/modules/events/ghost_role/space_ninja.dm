//Note to future generations: I didn't write this god-awful code I just ported it to the event system and tried to make it less moon-speaky.
//Don't judge me D; ~Carn //Maximum judging occuring - Remie.
// Tut tut Remie, let's keep our comments constructive. - coiax

/*

Contents:
- The Ninja "Random" Event
- Ninja creation code
*/

/datum/round_event_control/ninja
	name = "Space Ninja"
	typepath = /datum/round_event/ghost_role/ninja
	max_occurrences = 1
	earliest_start = 40 MINUTES
	min_players = 15
	track = EVENT_TRACK_ROLESET
	tags = list(TAG_COMBAT, TAG_DESTRUCTIVE, TAG_EXTERNAL)
	checks_antag_cap = TRUE

/datum/round_event/ghost_role/ninja
	var/success_spawn = 0
	role_name = "space ninja"
	minimum_required = 1

	var/helping_station
	var/spawn_loc
	var/give_objectives = TRUE

/datum/round_event/ghost_role/ninja/setup()
	helping_station = rand(0,1)
	setup = TRUE //storytellers

/datum/round_event/ghost_role/ninja/kill()
	if(!success_spawn && control)
		control.occurrences--
	return ..()


/datum/round_event/ghost_role/ninja/spawn_role()
	//selecting a spawn_loc
	if(!spawn_loc)
		var/list/spawn_locs = list()
		for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
			if(isturf(L.loc))
				spawn_locs += L.loc

		for(var/X in GLOB.xeno_spawn)
			var/turf/T = X
			var/light_amount = T.get_lumcount()
			if(light_amount < SHADOW_SPECIES_DIM_LIGHT)
				spawn_locs += T

		if(!spawn_locs.len)
			return kill()
		spawn_loc = pick(spawn_locs)
	if(!spawn_loc)
		return MAP_ERROR

	//selecting a candidate player
	var/list/candidates = get_candidates(ROLE_NINJA, null, ROLE_NINJA)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected_candidate = pick_n_take(candidates)
	var/key = selected_candidate.key

	//Prepare ninja player mind
	var/datum/mind/Mind = new /datum/mind(key)
	Mind.assigned_role = ROLE_NINJA
	Mind.special_role = ROLE_NINJA
	Mind.active = 1

	//spawn the ninja and assign the candidate
	var/mob/living/carbon/human/Ninja = create_space_ninja(spawn_loc)
	Mind.transfer_to(Ninja)
	var/datum/antagonist/ninja/ninjadatum = new
	ninjadatum.helping_station = pick(TRUE,FALSE)
	Mind.add_antag_datum(ninjadatum)

	var/datum/language_holder/H = Ninja.get_language_holder() //yogs start
	H.remove_all_languages()
	H.grant_language(/datum/language/japanese) //yogs end

	if(Ninja.mind != Mind)			//something has gone wrong!
		CRASH("Ninja created with incorrect mind")

	spawned_mobs += Ninja
	message_admins("[ADMIN_LOOKUPFLW(Ninja)] has been made into a ninja by an event.")
	log_game("[key_name(Ninja)] was spawned as a ninja by an event.")

	return SUCCESSFUL_SPAWN


//=======//NINJA CREATION PROCS//=======//

/proc/create_space_ninja(spawn_loc)
	var/mob/living/carbon/human/new_ninja = new(spawn_loc)
	new_ninja.randomize_human_appearance(~(RANDOMIZE_NAME|RANDOMIZE_SPECIES))
	var/new_name = "[pick(GLOB.ninja_titles)] [pick(GLOB.ninja_names)]"
	new_ninja.name = new_name
	new_ninja.real_name = new_name
	new_ninja.dna.update_dna_identity()
	return new_ninja
