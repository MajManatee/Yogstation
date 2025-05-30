#define FILE_ANTAG_REP "data/AntagReputation.json"
#define ROUNDCOUNT_ENGINE_JUST_EXPLODED 0

//yogs edit
#define NEXT_MINETYPE_JUNGLE 0
#define NEXT_MINETYPE_LAVALAND 1
#define NEXT_MINETYPE_EITHER 2
//yogs end
SUBSYSTEM_DEF(persistence)
	name = "Persistence"
	init_order = INIT_ORDER_PERSISTENCE
	flags = SS_NO_FIRE

	var/list/obj/structure/chisel_message/chisel_messages = list()
	var/list/saved_messages = list()
	var/list/saved_modes = list(1,2,3)
	var/list/saved_trophies = list()
	var/list/antag_rep = list()
	var/list/antag_rep_change = list()
	var/list/picture_logging_information = list()
	var/list/obj/structure/sign/picture_frame/photo_frames = list()
	var/list/obj/item/storage/photo_album/photo_albums = list()
	var/list/ai_network_rankings = list("ram" = list(), "cpu" = list())
	var/rounds_since_engine_exploded = 0

	var/next_minetype //yogs

/datum/controller/subsystem/persistence/Initialize()
	LoadPoly()
	LoadChiselMessages()
	LoadTrophies()
	LoadRecentModes()
	LoadPhotoPersistence()
	if(CONFIG_GET(flag/use_antag_rep))
		LoadAntagReputation()
	LoadRandomizedRecipes()
	LoadAINetworkRanking()
	LoadDelaminationCounter()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/persistence/proc/LoadPoly()
	for(var/mob/living/simple_animal/parrot/Poly/P in GLOB.alive_mob_list)
		twitterize(P.speech_buffer, "polytalk")
		break //Who's been duping the bird?!

/datum/controller/subsystem/persistence/proc/LoadChiselMessages()
	var/list/saved_messages = list()
	if(fexists("data/npc_saves/ChiselMessages.sav")) //legacy compatability to convert old format to new
		var/savefile/chisel_messages_sav = new /savefile("data/npc_saves/ChiselMessages.sav")
		var/saved_json
		chisel_messages_sav[SSmapping.config.map_name] >> saved_json
		if(!saved_json)
			return
		saved_messages = json_decode(saved_json)
		fdel("data/npc_saves/ChiselMessages.sav")
	else
		var/json_file = file("data/npc_saves/ChiselMessages[SSmapping.config.map_name].json")
		if(!fexists(json_file))
			return
		var/list/json = json_decode(file2text(json_file))

		if(!json)
			return
		saved_messages = json["data"]

	for(var/item in saved_messages)
		if(!islist(item))
			continue

		var/xvar = item["x"]
		var/yvar = item["y"]
		var/zvar = item["z"]

		if(!xvar || !yvar || !zvar)
			continue

		var/turf/T = locate(xvar, yvar, zvar)
		if(!isturf(T))
			continue

		if(locate(/obj/structure/chisel_message) in T)
			continue

		var/obj/structure/chisel_message/M = new(T)

		if(!QDELETED(M))
			M.unpack(item)

	log_world("Loaded [saved_messages.len] engraved messages on map [SSmapping.config.map_name]")

/datum/controller/subsystem/persistence/proc/LoadTrophies()
	if(fexists("data/npc_saves/TrophyItems.sav")) //legacy compatability to convert old format to new
		var/savefile/S = new /savefile("data/npc_saves/TrophyItems.sav")
		var/saved_json
		S >> saved_json
		if(!saved_json)
			return
		saved_trophies = json_decode(saved_json)
		fdel("data/npc_saves/TrophyItems.sav")
	else
		var/json_file = file("data/npc_saves/TrophyItems.json")
		if(!fexists(json_file))
			return
		var/list/json = json_decode(file2text(json_file))
		if(!json)
			return
		saved_trophies = json["data"]
	SetUpTrophies(saved_trophies.Copy())

/datum/controller/subsystem/persistence/proc/LoadRecentModes()
	var/json_file = file("data/RecentModes.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_modes = json["data"]

/datum/controller/subsystem/persistence/proc/LoadAntagReputation()
	var/json = file2text(FILE_ANTAG_REP)
	if(!json)
		var/json_file = file(FILE_ANTAG_REP)
		if(!fexists(json_file))
			WARNING("Failed to load antag reputation. File likely corrupt.")
			return
		return
	antag_rep = json_decode(json)

/datum/controller/subsystem/persistence/proc/LoadAINetworkRanking()
	var/json = file2text("data/AINetworkRank.json")
	if(!json)
		var/json_file = file("data/AINetworkRank.json")
		if(!fexists(json_file))
			WARNING("Failed to load ai network ranks. File likely corrupt.")
			return
		return
	ai_network_rankings = json_decode(json)

/datum/controller/subsystem/persistence/proc/SetUpTrophies(list/trophy_items)
	for(var/A in GLOB.trophy_cases)
		var/obj/structure/displaycase/trophy/T = A
		if (T.showpiece)
			continue
		T.added_roundstart = TRUE

		var/trophy_data = pick_n_take(trophy_items)

		if(!islist(trophy_data))
			continue

		var/list/chosen_trophy = trophy_data

		if(!chosen_trophy || isemptylist(chosen_trophy)) //Malformed
			continue

		var/path = text2path(chosen_trophy["path"]) //If the item no longer exist, this returns null
		if(!path)
			continue

		T.showpiece = new /obj/item/showpiece_dummy(T, path)
		T.trophy_message = chosen_trophy["message"]
		T.placer_key = chosen_trophy["placer_key"]
		T.update_appearance(UPDATE_ICON)

/datum/controller/subsystem/persistence/proc/CollectData()
	CollectChiselMessages()
	CollectTrophies()
	CollectRoundtype()
	SavePhotoPersistence()						//THIS IS PERSISTENCE, NOT THE LOGGING PORTION.
	if(CONFIG_GET(flag/use_antag_rep))
		CollectAntagReputation()
	SaveRandomizedRecipes()
	SaveScars()
	SaveAIRankings()
	SaveDelaminationCounter()

/datum/controller/subsystem/persistence/proc/GetPhotoAlbums()
	var/album_path = file("data/photo_albums.json")
	if(fexists(album_path))
		return json_decode(file2text(album_path))

/datum/controller/subsystem/persistence/proc/GetPhotoFrames()
	var/frame_path = file("data/photo_frames.json")
	if(fexists(frame_path))
		return json_decode(file2text(frame_path))

/datum/controller/subsystem/persistence/proc/LoadPhotoPersistence()
	var/album_path = file("data/photo_albums.json")
	var/frame_path = file("data/photo_frames.json")
	if(fexists(album_path))
		var/list/json = json_decode(file2text(album_path))
		if(json.len)
			for(var/i in photo_albums)
				var/obj/item/storage/photo_album/A = i
				if(!A.persistence_id)
					continue
				if(json[A.persistence_id])
					A.populate_from_id_list(json[A.persistence_id])

	if(fexists(frame_path))
		var/list/json = json_decode(file2text(frame_path))
		if(json.len)
			for(var/i in photo_frames)
				var/obj/structure/sign/picture_frame/PF = i
				if(!PF.persistence_id)
					continue
				if(json[PF.persistence_id])
					PF.load_from_id(json[PF.persistence_id])

/datum/controller/subsystem/persistence/proc/SavePhotoPersistence()
	var/album_path = file("data/photo_albums.json")
	var/frame_path = file("data/photo_frames.json")

	var/list/frame_json = list()
	var/list/album_json = list()

	if(fexists(album_path))
		album_json = json_decode(file2text(album_path))
		fdel(album_path)

	for(var/i in photo_albums)
		var/obj/item/storage/photo_album/A = i
		if(!istype(A) || !A.persistence_id)
			continue
		var/list/L = A.get_picture_id_list()
		album_json[A.persistence_id] = L

	album_json = json_encode(album_json)

	WRITE_FILE(album_path, album_json)

	if(fexists(frame_path))
		frame_json = json_decode(file2text(frame_path))
		fdel(frame_path)

	for(var/i in photo_frames)
		var/obj/structure/sign/picture_frame/F = i
		if(!istype(F) || !F.persistence_id)
			continue
		frame_json[F.persistence_id] = F.get_photo_id()

	frame_json = json_encode(frame_json)

	WRITE_FILE(frame_path, frame_json)

/datum/controller/subsystem/persistence/proc/CollectChiselMessages()
	var/json_file = file("data/npc_saves/ChiselMessages[SSmapping.config.map_name].json")

	for(var/obj/structure/chisel_message/M in chisel_messages)
		saved_messages += list(M.pack())

	log_world("Saved [saved_messages.len] engraved messages on map [SSmapping.config.map_name]")
	var/list/file_data = list()
	file_data["data"] = saved_messages
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/SaveChiselMessage(obj/structure/chisel_message/M)
	saved_messages += list(M.pack()) // dm eats one list


/datum/controller/subsystem/persistence/proc/CollectTrophies()
	var/json_file = file("data/npc_saves/TrophyItems.json")
	var/list/file_data = list()
	file_data["data"] = remove_duplicate_trophies(saved_trophies)
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/remove_duplicate_trophies(list/trophies)
	var/list/ukeys = list()
	. = list()
	for(var/trophy in trophies)
		var/tkey = "[trophy["path"]]-[trophy["message"]]"
		if(ukeys[tkey])
			continue
		else
			. += list(trophy)
			ukeys[tkey] = TRUE

/datum/controller/subsystem/persistence/proc/SaveTrophy(obj/structure/displaycase/trophy/T)
	if(!T.added_roundstart && T.showpiece)
		var/list/data = list()
		data["path"] = T.showpiece.type
		data["message"] = T.trophy_message
		data["placer_key"] = T.placer_key
		saved_trophies += list(data)

/datum/controller/subsystem/persistence/proc/CollectRoundtype()
	saved_modes[3] = saved_modes[2]
	saved_modes[2] = saved_modes[1]
	saved_modes[1] = "PLACEHOLDER WHILE STORYTELLERS"
	var/json_file = file("data/RecentModes.json")
	var/list/file_data = list()
	file_data["data"] = saved_modes
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/CollectAntagReputation()
	var/ANTAG_REP_MAXIMUM = CONFIG_GET(number/antag_rep_maximum)

	for(var/p_ckey in antag_rep_change)
//		var/start = antag_rep[p_ckey]
		antag_rep[p_ckey] = max(0, min(antag_rep[p_ckey]+antag_rep_change[p_ckey], ANTAG_REP_MAXIMUM))

//		WARNING("AR_DEBUG: [p_ckey]: Committed [antag_rep_change[p_ckey]] reputation, going from [start] to [antag_rep[p_ckey]]")

	antag_rep_change = list()

	fdel(FILE_ANTAG_REP)
	text2file(json_encode(antag_rep), FILE_ANTAG_REP)

/datum/controller/subsystem/persistence/proc/SaveAIRankings()
	var/min_ram = 0
	var/min_cpu = 0

	for(var/ram_record in ai_network_rankings["ram"])
		if(ram_record["score"] < min_ram)
			min_ram = ram_record["score"]
	for(var/cpu_record in ai_network_rankings["cpu"])
		if(cpu_record["score"] < min_ram)
			min_cpu = cpu_record["score"]

	var/list/resource_list = list()
	for(var/datum/ai_network/AN in SSmachines.ainets)
		resource_list |= AN.resources

	var/list/contenders_ram = list()
	var/list/contenders_cpu = list()

	for(var/datum/ai_shared_resources/R in resource_list)
		if(R.total_cpu() > min_cpu)
			contenders_cpu += R.total_cpu()
		if(R.total_ram() > min_ram)
			contenders_ram += R.total_ram()

	var/cpu_winner = max(contenders_cpu)
	var/ram_winner = max(contenders_ram)
	

	if(!isnull(cpu_winner))
		var/cpu_entry = list("score" = cpu_winner, "round_id" = GLOB.round_id)

		ai_network_rankings["cpu"] += list(cpu_entry)
		ai_network_rankings["cpu"] = sortList(ai_network_rankings["cpu"], /proc/cmp_ai_record_dsc)
		if(length(ai_network_rankings["cpu"]) > 5)
			var/list/cpu_rankings = ai_network_rankings["cpu"]
			cpu_rankings.len = 5
			ai_network_rankings["cpu"] = cpu_rankings

	if(!isnull(ram_winner))
		var/ram_entry = list("score" = ram_winner, "round_id" = GLOB.round_id)
		ai_network_rankings["ram"] += list(ram_entry)
		ai_network_rankings["ram"] = sortList(ai_network_rankings["ram"], /proc/cmp_ai_record_dsc)
		if(length(ai_network_rankings["ram"]) > 5)
			var/list/ram_rankings = ai_network_rankings["ram"]
			ram_rankings.len = 5
			ai_network_rankings["ram"] = ram_rankings

	fdel("data/AINetworkRank.json")
	text2file(json_encode(ai_network_rankings), "data/AINetworkRank.json")


/datum/controller/subsystem/persistence/proc/LoadRandomizedRecipes()
	var/json_file = file("data/RandomizedChemRecipes.json")
	var/json
	if(fexists(json_file))
		json = json_decode(file2text(json_file))

	for(var/randomized_type in subtypesof(/datum/chemical_reaction/randomized))
		var/datum/chemical_reaction/randomized/R = new randomized_type
		var/loaded = FALSE
		if(R.persistent && json)
			var/list/recipe_data = json[R.id]
			if(recipe_data)
				if(R.LoadOldRecipe(recipe_data) && (daysSince(R.created) <= R.persistence_period))
					loaded = TRUE
		if(!loaded) //We do not have information for whatever reason, just generate new one
			R.GenerateRecipe()

		if(!R.HasConflicts()) //Might want to try again if conflicts happened in the future.
			add_chemical_reaction(R)

/datum/controller/subsystem/persistence/proc/SaveRandomizedRecipes()
	var/json_file = file("data/RandomizedChemRecipes.json")
	var/list/file_data = list()

	//asert globchems done
	for(var/randomized_type in subtypesof(/datum/chemical_reaction/randomized))
		var/datum/chemical_reaction/randomized/R = randomized_type
		R = get_chemical_reaction(initial(R.id)) //ew, would be nice to add some simple tracking
		if(R && R.persistent && R.id)
			var/recipe_data = list()
			recipe_data["timestamp"] = R.created
			recipe_data["required_reagents"] = R.required_reagents
			recipe_data["required_catalysts"] = R.required_catalysts
			recipe_data["required_temp"] = R.required_temp
			recipe_data["is_cold_recipe"] = R.is_cold_recipe
			recipe_data["results"] = R.results
			recipe_data["required_container"] = "[R.required_container]"
			file_data["[R.id]"] = recipe_data

	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/SaveScars()
	for(var/i in GLOB.joined_player_list)
		var/mob/living/carbon/human/ending_human = get_mob_by_ckey(i)
		if(!istype(ending_human) || !ending_human.mind?.original_character_slot_index || !ending_human.client || !ending_human.client.prefs || !ending_human.client.prefs.read_preference(/datum/preference/toggle/persistent_scars))
			continue

		var/mob/living/carbon/human/original_human = ending_human.mind.original_character.resolve()

		if(!original_human)
			continue

		if(original_human.stat == DEAD || !original_human.all_scars || original_human != ending_human)
			original_human.save_persistent_scars(TRUE)
		else
			original_human.save_persistent_scars()


/datum/controller/subsystem/persistence/proc/LoadMinetype()
	var/json_file = file("data/next_minetype.json")
	if(fexists(json_file))
		next_minetype = json_decode(file2text(json_file))
	else 
		next_minetype = NEXT_MINETYPE_EITHER
	SaveMinetype()

/datum/controller/subsystem/persistence/proc/SaveMinetype(minetype = NEXT_MINETYPE_EITHER)
	var/json_file = file("data/next_minetype.json")
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(minetype))


#define DELAMINATION_COUNT_FILEPATH "data/rounds_since_delamination.txt"

/datum/controller/subsystem/persistence/proc/LoadDelaminationCounter()
	if (!fexists(DELAMINATION_COUNT_FILEPATH))
		return
	rounds_since_engine_exploded = text2num(file2text(DELAMINATION_COUNT_FILEPATH))
	for (var/obj/structure/sign/delamination_counter/sign as anything in GLOB.map_delamination_counters)
		sign.update_count(rounds_since_engine_exploded)

/datum/controller/subsystem/persistence/proc/SaveDelaminationCounter()
	rustg_file_write("[rounds_since_engine_exploded + 1]", DELAMINATION_COUNT_FILEPATH)

#undef DELAMINATION_COUNT_FILEPATH

