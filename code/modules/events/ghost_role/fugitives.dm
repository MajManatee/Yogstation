/datum/round_event_control/fugitives
	name = "Spawn Fugitives"
	typepath = /datum/round_event/ghost_role/fugitives
	max_occurrences = 1
	min_players = 20
	earliest_start = 30 MINUTES //deadchat sink, lets not even consider it early on.
	track = EVENT_TRACK_MAJOR
	tags = list(TAG_COMBAT, TAG_EXTERNAL)

/datum/round_event/ghost_role/fugitives
	minimum_required = 1
	role_name = "fugitive"
	fakeable = FALSE

/datum/round_event/ghost_role/fugitives/spawn_role()
	var/list/possible_spawns = list()//Some xeno spawns are in some spots that will instantly kill the refugees, like atmos
	for(var/turf/X in GLOB.xeno_spawn)
		if(istype(X.loc, /area/maintenance))
			possible_spawns += X
	if(!possible_spawns.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	var/turf/landing_turf = pick(possible_spawns)
	var/list/possible_backstories = list()
	var/list/candidates = get_candidates(ROLE_FUGITIVE, null, ROLE_FUGITIVE)
	if(candidates.len >= 1) //solo refugees
		possible_backstories.Add("waldo")
	if(candidates.len >= 2)//group refugees
		possible_backstories.Add("prisoner", "cultist", "synth")
	if(!possible_backstories.len)
		return NOT_ENOUGH_PLAYERS

	var/backstory = pick(possible_backstories)
	var/member_size = min(candidates.len, 5)
	var/leader
	switch(backstory)
		if("cultist","synth") // Yogs -- fixes this switch case
			leader = pick_n_take(candidates)
		if("waldo")
			member_size = 0 //solo refugees have no leader so the member_size gets bumped to one a bit later
	var/list/members = list()
	var/list/spawned_mobs = list()
	if(isnull(leader))
		member_size++ //if there is no leader role, then the would be leader is a normal member of the team.

	for(var/i in 1 to member_size)
		members += pick_n_take(candidates)

	for(var/mob/dead/selected in members)
		var/mob/living/carbon/human/S = gear_fugitive(selected, landing_turf, backstory)
		spawned_mobs += S
	if(!isnull(leader))
		gear_fugitive_leader(leader, landing_turf, backstory)

//after spawning
	playsound(src, 'sound/weapons/emitter.ogg', 50, 1)
	new /obj/item/storage/toolbox/mechanical(landing_turf) //so they can actually escape maint
	addtimer(CALLBACK(src, PROC_REF(spawn_hunters)), 10 MINUTES)
	role_name = "fugitive hunter"
	return SUCCESSFUL_SPAWN

/datum/round_event/ghost_role/fugitives/proc/gear_fugitive(mob/dead/selected, turf/landing_turf, backstory) //spawns normal fugitive
	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = TRUE
	var/mob/living/carbon/human/S = new(landing_turf)
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Fugitive"
	player_mind.special_role = "Fugitive"
	player_mind.add_antag_datum(/datum/antagonist/fugitive)
	var/datum/antagonist/fugitive/fugitiveantag = player_mind.has_antag_datum(/datum/antagonist/fugitive)
	INVOKE_ASYNC(fugitiveantag, TYPE_PROC_REF(/datum/antagonist/fugitive, greet), backstory) //some fugitives have a sleep on their greet, so we don't want to stop the entire antag granting proc with fluff

	switch(backstory)
		if("prisoner")
			S.equipOutfit(/datum/outfit/prisoner)
		if("cultist")
			S.equipOutfit(/datum/outfit/yalp_cultist)
			var/datum/action/innate/yalpcomms/comm
			comm = new
			comm.Grant(S)
		if("waldo")
			S.equipOutfit(/datum/outfit/waldo)
		if("synth")
			S.equipOutfit(/datum/outfit/synthetic)
			S.set_species(/datum/species/ipc/self)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Fugitive by an event.")
	log_game("[key_name(S)] was spawned as a Fugitive by an event.")
	spawned_mobs += S
	return S

 //special spawn for one member. it can be used for a special mob or simply to give one normal member special items.
/datum/round_event/ghost_role/fugitives/proc/gear_fugitive_leader(mob/dead/leader, turf/landing_turf, backstory)
	var/datum/mind/player_mind = new /datum/mind(leader.key)
	player_mind.active = TRUE
	switch(backstory)
		if("cultist")
			var/mob/camera/yalp_elor/yalp = new(landing_turf)
			player_mind.transfer_to(yalp)
			player_mind.assigned_role = "Yalp Elor"
			player_mind.special_role = "Old God"
			player_mind.add_antag_datum(/datum/antagonist/fugitive)


//security team gets called in after 10 minutes of prep to find the refugees
/datum/round_event/ghost_role/fugitives/proc/spawn_hunters()
	var/backstory = pick("space cop", "russian")
	var/datum/map_template/shuttle/ship
	if(backstory == "space cop")
		ship = new /datum/map_template/shuttle/hunter/space_cop
	else
		ship = new /datum/map_template/shuttle/hunter/russian
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Fugitive Hunters (Created from fugitive event) found no turf to load in")
	if(!ship.load(T))
		CRASH("Loading hunter ship failed!")
	priority_announce("Unidentified armed ship detected near the station.")
