//If someone can do this in a neater way, be my guest-Kor

//To do: Allow corpses to appear mangled, bloody, etc. Allow customizing the bodies appearance (they're all bald and white right now).

/obj/effect/mob_spawn
	name = "Unknown"
	density = TRUE
	anchored = TRUE
	var/job_description = null
	var/mob_type = null
	var/mob_name = ""
	var/mob_gender = null
	var/death = TRUE //Kill the mob
	var/roundstart = TRUE //fires on initialize
	var/instant = FALSE	//fires on New
	var/short_desc = "The mapper forgot to set this!"
	var/flavour_text = ""
	var/important_info = ""
	var/faction = null
	var/permanent = FALSE	//If true, the spawner will not disappear upon running out of uses.
	var/random = FALSE		//Don't set a name or gender, just go random
	var/antagonist_type
	var/objectives = null
	var/uses = 1			//how many times can we spawn from it. set to -1 for infinite.
	var/brute_damage = 0
	var/oxy_damage = 0
	var/burn_damage = 0
	var/datum/disease/disease = null //Do they start with a pre-spawned disease?
	var/mob_color //Change the mob's color
	var/assignedrole
	var/show_flavour = TRUE
	var/banType = "lavaland"
	var/ghost_usable = TRUE
	var/skip_reentry_check = FALSE //Skips the ghost role blacklist time for people who ghost/suicide/cryo
	var/loadout_enabled = FALSE
	var/can_load_appearance = FALSE
	var/make_bank_account = FALSE // BLUEMOON ADD
	var/starting_money = 0 // BLUEMOON ADD работает только при make_bank_account = TRUE
	var/category = "misc" // BLUEMOON ADD - категоризация для отображения по спискам

///override this to add special spawn conditions to a ghost role
/obj/effect/mob_spawn/proc/allow_spawn(mob/user, silent = FALSE)
	return TRUE

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/mob_spawn/attack_ghost(mob/user, latejoinercalling)
	if(!SSticker.HasRoundStarted() || !loc || !ghost_usable)
		return
	if(jobban_isbanned(user, banType))
		to_chat(user, "<span class='warning'>You are jobanned!</span>")
		return
	if(!allow_spawn(user, silent = FALSE))
		return
	if(QDELETED(src) || QDELETED(user))
		return
	if(isobserver(user) && !skip_reentry_check)
		var/mob/dead/observer/O = user
		if(!O.can_reenter_round())
			return FALSE
	var/ghost_role = alert(latejoinercalling ? "Latejoin as [mob_name]? (This is a ghost role, and as such, it's very likely to be off-station.)" : "Become [mob_name]? (Warning, You can no longer be cloned!)",,"Да","Нет")
	if(ghost_role == "Нет" || !loc)
		return
	var/requested_char = FALSE
	if(can_load_appearance == TRUE && ispath(mob_type, /mob/living/carbon/human)) // Can't just use if(can_load_appearance), 2 has a different behavior
		switch(alert(user, "Желаете загрузить текущего своего выбранного персонажа?", "Play as your character!", "Yes", "No", "Actually nevermind"))
			if("Yes")
				requested_char = TRUE
			if("Actually nevermind")
				return
	if(!uses)
		to_chat(user, "<span class='warning'>This spawner is out of charges!</span>")
		return
	if(QDELETED(src) || QDELETED(user))
		return
	if(latejoinercalling)
		var/mob/dead/new_player/NP = user
		if(istype(NP))
			NP.close_spawn_windows()
			NP.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	log_game("[key_name(user)] становится [mob_name]!")
	create(ckey = user.ckey, load_character = requested_char)
	return TRUE

/obj/effect/mob_spawn/Initialize(mapload)
	. = ..()
	if(instant || (roundstart && (mapload || (SSticker && SSticker.current_state > GAME_STATE_SETTING_UP))))
		INVOKE_ASYNC(src, PROC_REF(create))
	else if(ghost_usable)
		GLOB.poi_list |= src
		LAZYADD(GLOB.mob_spawners[job_description ? job_description : name], src)


/obj/effect/mob_spawn/Destroy()
	GLOB.poi_list -= src
	var/job_name = job_description ? job_description : name
	LAZYREMOVE(GLOB.mob_spawners[job_name], src)
	if(!LAZYLEN(GLOB.mob_spawners[job_name]))
		GLOB.mob_spawners -= job_name
	return ..()

/obj/effect/mob_spawn/proc/can_latejoin() //If it can be taken from the lobby.
	return ghost_usable

/obj/effect/mob_spawn/proc/special(mob/M)
	return

/obj/effect/mob_spawn/proc/special_post_appearance(mob/H)
	return

/obj/effect/mob_spawn/proc/equip(mob/M, load_character)
	return

/obj/effect/mob_spawn/proc/create(ckey, name, load_character)
	var/mob/living/M = new mob_type(get_turf(src)) //living mobs only
	if(!random)
		M.real_name = mob_name ? mob_name : M.name
		if(!mob_gender)
			mob_gender = pick(MALE, FEMALE)
		M.gender = mob_gender
	if(faction)
		M.faction = list(faction)
	if(disease)
		M.ForceContractDisease(new disease)
	if(death)
		M.death(1) //Kills the new mob

	M.adjustOxyLoss(oxy_damage)
	M.adjustBruteLoss(brute_damage)
	M.adjustFireLoss(burn_damage)
	M.color = mob_color
	equip(M, load_character)

	if(ckey)
		M.ckey = ckey
		if(ishuman(M) && load_character)
			var/mob/living/carbon/human/H = M
			if (H.client)
				if (loadout_enabled == TRUE)
					SSjob.equip_loadout(null, H)
					SSjob.post_equip_loadout(null, H)
			H.load_client_appearance(H.client)
		//splurt change
		if(jobban_isbanned(M, "pacifist")) //do you love repeat code? i sure do
			to_chat(M, "<span class='cult'>You are pacification banned. Pacifist has been force applied.</span>")
			ADD_TRAIT(M, TRAIT_PACIFISM, "pacification ban")
		// BLUEMOON EDIT START
		if(show_flavour)
			var/output_message = ""
			output_message += "<p class='medium'>Вы - <b>[src.name]</b>.</p>"
			output_message += "<p>[short_desc]</p>"
			if(flavour_text != "")
				output_message += "<p>[flavour_text]</p>"
			if(important_info != "")
				output_message += "<span class='warning'>[important_info]</span>"
			output_message += "\n<span class='boldwarning'>В режим игры Extended станцию посещать допустимо, в Dynamic — запрещено!</span>"
			to_chat(M, examine_block(output_message))
		// BLUEMOON EDIT END
		var/datum/mind/MM = M.mind
		var/datum/antagonist/A
		// BLUEMOON EDIT START - правки гостролей
		// Хэндлить у хуманов будем, собственно, у хуманов, чтобы нормально с ghost_team работать
		if(!istype(src, /obj/effect/mob_spawn/human))
			if(antagonist_type)
				A = MM.add_antag_datum(antagonist_type)
			if(objectives)
				if(!A)
					A = MM.add_antag_datum(/datum/antagonist/custom)
				for(var/objective in objectives)
					var/datum/objective/O = new/datum/objective(objective)
					O.owner = MM
					A.objectives += O
		// BLUEMOON EDIT END
		if(assignedrole)
			M.mind.assigned_role = assignedrole
		special(M, name)
		MM.name = M.real_name
		if(make_bank_account)
			handlebank(M, starting_money)
		special_post_appearance(M, name) // BLUEMOON ADD
		if(M.client && ishuman(M) && load_character)
			SSlanguage.AssignLanguage(M, M.client)
	if(uses > 0)
		uses--
	if(!permanent && !uses)
		qdel(src)

// Base version - place these on maps/templates.
/obj/effect/mob_spawn/human
	mob_type = /mob/living/carbon/human
	icon_state = "corpsegreytider"
	//Human specific stuff.
	var/mob_species = null		//Set to make them a mutant race such as lizard or skeleton. Uses the datum typepath instead of the ID.
	var/datum/outfit/outfit = /datum/outfit	//If this is a path, it will be instanced in Initialize()
	var/disable_pda = TRUE
	var/disable_sensors = TRUE
	//All of these only affect the ID that the outfit has placed in the ID slot
	var/id_job = null			//Such as "Clown" or "Chef." This just determines what the ID reads as, not their access
	var/id_access = null		//This is for access. See access.dm for which jobs give what access. Use "Captain" if you want it to be all access.
	var/id_access_list = null	//Allows you to manually add access to an ID card.

	var/husk = null
	//these vars are for lazy mappers to override parts of the outfit
	//these cannot be null by default, or mappers cannot set them to null if they want nothing in that slot
	var/uniform = -1
	var/r_hand = -1
	var/l_hand = -1
	var/suit = -1
	var/shoes = -1
	var/gloves = -1
	var/ears = -1
	var/glasses = -1
	var/mask = -1
	var/head = -1
	var/belt = -1
	var/r_pocket = -1
	var/l_pocket = -1
	var/back = -1
	var/id = -1
	var/neck = -1
	var/backpack_contents = -1
	var/suit_store = -1

	var/hair_style
	var/facial_hair_style
	var/skin_tone

	assignedrole = "Ghost Role"
	var/datum/team/ghost_role/ghost_team

	var/give_cooler_to_mob_if_synth = FALSE // BLUEMOON ADD - если персонаж - синтетик, то ему выдаётся заряженный космический охладитель. Для специальных ролей

	/// set this to make the spawner use the outfit.name instead of its name var for things like cryo announcements and ghost records
	/// modifying the actual name during the game will cause issues with the GLOB.mob_spawners associative list
	var/use_outfit_name

/obj/effect/mob_spawn/human/Initialize(mapload)
	if(ispath(outfit))
		outfit = new outfit()
	if(!outfit)
		outfit = new /datum/outfit
	return ..()

// BLUEMOON ADD START - особые действия после выставления персонажу расы и внешности игрока (ставлю сюда, чтобы повысить читаемость)
/obj/effect/mob_spawn/human/special_post_appearance(mob/H)
	// Не добавлено в аутфит, т.к. раса ставится ПОСЛЕ выставления аутфита
	if(give_cooler_to_mob_if_synth)
		if(HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM))
			if(!r_hand)
				H.put_in_r_hand(new /obj/item/device/cooler/charged(H))
			else if(!l_hand)
				H.put_in_l_hand(new /obj/item/device/cooler/charged(H))
			else
				to_chat(H, span_reallybig("Не забудьте забрать космический охладитель под собой.")) // чтобы не упустили из виду при резком спавне
				new /obj/item/device/cooler/charged(H.loc)
	. = ..()

// Создаём банк аккаунт и всё такое
/obj/effect/mob_spawn/proc/handlebank(mob/living/carbon/human/owner, starting_money = 0)
	return

/obj/effect/mob_spawn/human/handlebank(mob/living/carbon/human/owner, starting_money = 0)
	var/datum/bank_account/offstation_bank_account = new(owner.real_name)
	owner.account_id = offstation_bank_account.account_id
	owner.add_memory("Номер вашего банковского аккаунта - [owner.account_id].")
	if(owner.wear_id)
		var/obj/item/card/id/id_card = owner.wear_id
		id_card.registered_account = offstation_bank_account
	if(starting_money > 0)
		offstation_bank_account.account_balance = starting_money

// BLUEMOON ADD END

/obj/effect/mob_spawn/human/equip(mob/living/carbon/human/H, load_character)
	if(!load_character && mob_species)
		H.set_species(mob_species)
	if(husk)
		H.Drain()
	else //Because for some reason I can't track down, things are getting turned into husks even if husk = false. It's in some damage proc somewhere.
		H.cure_husk()
	if(!load_character)
		H.underwear = "Nude"
		H.undershirt = "Nude"
		H.socks = "Nude"
		if(hair_style)
			H.hair_style = hair_style
		else
			H.hair_style = random_hair_style(gender)
		if(facial_hair_style)
			H.facial_hair_style = facial_hair_style
		else
			H.facial_hair_style = random_facial_hair_style(gender)
		if(skin_tone)
			H.skin_tone = skin_tone
			if(!GLOB.skin_tones[H.skin_tone])
				H.dna.skin_tone_override = H.skin_tone
		else
			H.skin_tone = random_skin_tone()
		H.update_hair()
		H.update_body() //update_genitals arg FALSE because these don't quite require/have them most times.
	if(outfit)
		var/static/list/slots = list("uniform", "r_hand", "l_hand", "suit", "shoes", "gloves", "ears", "glasses", "mask", "head", "belt", "r_pocket", "l_pocket", "back", "id", "neck", "backpack_contents", "suit_store")
		for(var/slot in slots)
			var/T = vars[slot]
			if(!isnum(T))
				outfit.vars[slot] = T
		H.equipOutfit(outfit)
		if(disable_pda)
			// We don't want corpse PDAs to show up in the messenger list.
			var/obj/item/pda/PDA = locate(/obj/item/pda) in H
			if(PDA)
				PDA.toff = TRUE
		if(disable_sensors)
			// Using crew monitors to find corpses while creative makes finding certain ruins too easy.
			var/obj/item/clothing/under/C = H.w_uniform
			if(istype(C))
				C.sensor_mode = NO_SENSORS

	var/obj/item/card/id/W = H.wear_id
	if(W)
		if(id_access)
			for(var/jobtype in typesof(/datum/job))
				var/datum/job/J = new jobtype
				if(J.title == id_access)
					W.access = J.get_access()
					break
		if(id_access_list)
			if(!islist(W.access))
				W.access = list()
			W.access |= id_access_list
		if(id_job)
			W.assignment = id_job
		W.registered_name = H.real_name
		W.update_label()

//Instant version - use when spawning corpses during runtime
/obj/effect/mob_spawn/human/corpse
	roundstart = FALSE
	instant = TRUE

/obj/effect/mob_spawn/human/corpse/damaged
	brute_damage = 1000

/obj/effect/mob_spawn/human/alive
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	death = FALSE
	roundstart = FALSE //you could use these for alive fake humans on roundstart but this is more common scenario

/obj/effect/mob_spawn/human/corpse/delayed
	ghost_usable = FALSE //These are just not-yet-set corpses.
	instant = FALSE

//Non-human spawners

/obj/effect/mob_spawn/AICorpse //Creates a corrupted AI
	mob_type = /mob/living/silicon/ai/spawned

/obj/effect/mob_spawn/AICorpse/create(ckey, name, load_character)
	var/ai_already_present = locate(/mob/living/silicon/ai) in loc
	if(ai_already_present)
		qdel(src)
		return
	. = ..()

// TODO: Port the upstream tgstation rewrite of this.
/obj/effect/mob_spawn/AICorpse/equip(mob/living/silicon/ai/ai)
	. = ..()
	if(!isAI(ai)) // This should never happen.
		stack_trace("[type] spawned a mob of type [ai?.type || "NULL"] that was not an AI!")
		return
	ai.name = name
	ai.real_name = name
	ai.aiPDA.toff = TRUE //turns the AI's PDA messenger off, stopping it showing up on player PDAs
	ai.death() //call the AI's death proc

/obj/effect/mob_spawn/slime
	mob_type = 	/mob/living/simple_animal/slime
	var/mobcolour = "grey"
	icon = 'icons/mob/slimes.dmi'
	icon_state = "grey baby slime" //sets the icon in the map editor

/obj/effect/mob_spawn/slime/equip(mob/living/simple_animal/slime/S)
	S.colour = mobcolour

/obj/effect/mob_spawn/human/facehugger/create(ckey, name, load_character) //Creates a squashed facehugger
	var/obj/item/clothing/mask/facehugger/O = new(src.loc) //variable O is a new facehugger at the location of the landmark
	O.name = src.name
	O.Die() //call the facehugger's death proc
	qdel(src)

/obj/effect/mob_spawn/mouse
	name = "sleeper"
	mob_type = 	/mob/living/simple_animal/mouse
	death = FALSE
	roundstart = FALSE
	job_description = "Mouse"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"

/obj/effect/mob_spawn/cow
	name = "sleeper"
	mob_type = 	/mob/living/simple_animal/cow
	death = FALSE
	roundstart = FALSE
	job_description = "Cow"
	mob_gender = FEMALE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"

// I'll work on making a list of corpses people request for maps, or that I think will be commonly used. Syndicate operatives for example.

///////////Civilians//////////////////////

/obj/effect/mob_spawn/human/corpse/assistant
	name = "Assistant"
	outfit = /datum/outfit/job/assistant

/obj/effect/mob_spawn/human/corpse/assistant/beesease_infection
	disease = /datum/disease/beesease

/obj/effect/mob_spawn/human/corpse/assistant/brainrot_infection
	disease = /datum/disease/brainrot

/obj/effect/mob_spawn/human/corpse/assistant/spanishflu_infection
	disease = /datum/disease/fluspanish

/obj/effect/mob_spawn/human/corpse/cargo_tech
	name = "Cargo Tech"
	outfit = /datum/outfit/job/cargo_tech

/obj/effect/mob_spawn/human/cook
	name = "Cook"
	outfit = /datum/outfit/job/cook


/obj/effect/mob_spawn/human/doctor
	name = "Doctor"
	outfit = /datum/outfit/job/doctor


/obj/effect/mob_spawn/human/doctor/alive
	death = FALSE
	roundstart = FALSE
	random = TRUE
	name = "sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "You are a space doctor!"
	assignedrole = "Space Doctor"
	job_description = "Off-station Doctor"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/doctor/alive/equip(mob/living/carbon/human/H)
	..()
	// Remove radio and PDA so they wouldn't annoy station crew.
	var/list/del_types = list(/obj/item/pda, /obj/item/radio/headset)
	for(var/del_type in del_types)
		var/obj/item/I = locate(del_type) in H
		qdel(I)

/obj/effect/mob_spawn/human/engineer
	name = "Engineer"
	outfit = /datum/outfit/job/engineer/gloved

/obj/effect/mob_spawn/human/engineer/rig
	outfit = /datum/outfit/job/engineer/gloved/rig

/obj/effect/mob_spawn/human/clown
	name = "Clown"
	outfit = /datum/outfit/job/clown

/obj/effect/mob_spawn/human/scientist
	name = "Scientist"
	outfit = /datum/outfit/job/scientist

/obj/effect/mob_spawn/human/miner
	name = "Shaft Miner"
	outfit = /datum/outfit/job/miner

/obj/effect/mob_spawn/human/miner/rig
	outfit = /datum/outfit/job/miner/equipped/hardsuit

/obj/effect/mob_spawn/human/miner/explorer
	outfit = /datum/outfit/job/miner/equipped


/obj/effect/mob_spawn/human/plasmaman
	mob_species = /datum/species/plasmaman
	outfit = /datum/outfit/plasmaman


/obj/effect/mob_spawn/human/bartender
	name = "Space Bartender"
	id_job = "Bartender"
	id_access_list = list(ACCESS_BAR)
	outfit = /datum/outfit/spacebartender

/obj/effect/mob_spawn/human/bartender/alive
	death = FALSE
	roundstart = FALSE
	random = TRUE
	job_description = "Off-station Bartender"
	name = "bartender sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "You are a space bartender!"
	flavour_text = "Время смешивать напитки и менять жизни. Курение космических наркотиков облегчает понимание странного диалекта ваших покровителей!"
	assignedrole = "Space Bartender"
	id_job = "Bartender"
	can_load_appearance = TRUE

/datum/outfit/spacebartender
	name = "Space Bartender"
	uniform = /obj/item/clothing/under/rank/civilian/bartender
	back = /obj/item/storage/backpack
	shoes = /obj/item/clothing/shoes/sneakers/black
	suit = /obj/item/clothing/suit/armor/vest
	glasses = /obj/item/clothing/glasses/sunglasses/reagent
	id = /obj/item/card/id

/obj/effect/mob_spawn/human/beach
	outfit = /datum/outfit/beachbum
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/beach/alive
	death = FALSE
	roundstart = FALSE
	random = TRUE
	job_description = "Beach Biodome Bum"
	mob_name = "Beach Bum"
	name = "beach bum sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "You're a spunky lifeguard!"
	flavour_text = "Вы посетитель пляжа и вы уже не помните, сколько вы здесь пробыли! Какое же это приятное место."
	assignedrole = "Beach Bum"
	can_load_appearance = TRUE
	category = "offstation"

/obj/effect/mob_spawn/human/beach/alive/lifeguard
	flavour_text = "Вы - пляжный спасатель! Присматривай за посетителями пляжа, чтобы никто не утонул, не был съеден акулами и так далее."
	mob_gender = "female"
	name = "lifeguard sleeper"
	id_job = "Lifeguard"
	job_description = "Beach Biodome Lifeguard"
	uniform = /obj/item/clothing/under/shorts/red
	can_load_appearance = TRUE
	category = "offstation"

/datum/outfit/beachbum
	name = "Beach Bum"
	glasses = /obj/item/clothing/glasses/sunglasses
	r_pocket = /obj/item/storage/wallet/random
	l_pocket = /obj/item/reagent_containers/food/snacks/pizzaslice/dank;
	uniform = /obj/item/clothing/under/pants/youngfolksjeans
	id = /obj/item/card/id

/datum/outfit/beachbum/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(visualsOnly)
		return
	H.dna.add_mutation(STONER)

/////////////////Officers+Nanotrasen Security//////////////////////

/obj/effect/mob_spawn/human/bridgeofficer
	name = "Bridge Officer"
	id_job = "Bridge Officer"
	id_access_list = list(ACCESS_CENT_CAPTAIN)
	outfit = /datum/outfit/nanotrasenbridgeofficercorpse

/datum/outfit/nanotrasenbridgeofficercorpse
	name = "Bridge Officer Corpse"
	ears = /obj/item/radio/headset/heads/hop
	uniform = /obj/item/clothing/under/rank/centcom/officer
	suit = /obj/item/clothing/suit/armor/bulletproof
	shoes = /obj/item/clothing/shoes/sneakers/black
	glasses = /obj/item/clothing/glasses/sunglasses
	id = /obj/item/card/id


/obj/effect/mob_spawn/human/commander
	name = "Commander"
	id_job = "Commander"
	id_access_list = list(ACCESS_CENT_CAPTAIN, ACCESS_CENT_GENERAL, ACCESS_CENT_SPECOPS, ACCESS_CENT_MEDICAL, ACCESS_CENT_STORAGE)
	outfit = /datum/outfit/nanotrasencommandercorpse

/datum/outfit/nanotrasencommandercorpse
	name = "Nanotrasen Private Security Commander"
	uniform = /obj/item/clothing/under/rank/centcom/commander
	suit = /obj/item/clothing/suit/armor/bulletproof
	ears = /obj/item/radio/headset/heads/captain
	glasses = /obj/item/clothing/glasses/eyepatch
	mask = /obj/item/clothing/mask/cigarette/cigar/cohiba
	head = /obj/item/clothing/head/centhat
	gloves = /obj/item/clothing/gloves/tackler/combat
	shoes = /obj/item/clothing/shoes/combat/swat
	r_pocket = /obj/item/lighter
	id = /obj/item/card/id


/obj/effect/mob_spawn/human/nanotrasensoldier
	name = "Nanotrasen Private Security Officer"
	id_job = "Private Security Force"
	id_access_list = list(ACCESS_CENT_CAPTAIN, ACCESS_CENT_GENERAL, ACCESS_CENT_SPECOPS, ACCESS_CENT_MEDICAL, ACCESS_CENT_STORAGE, ACCESS_SECURITY)
	outfit = /datum/outfit/nanotrasensoldiercorpse

/datum/outfit/nanotrasensoldiercorpse
	name = "NT Private Security Officer Corpse"
	uniform = /obj/item/clothing/under/rank/security/officer
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	head = /obj/item/clothing/head/helmet/swat/nanotrasen
	back = /obj/item/storage/backpack/security
	id = /obj/item/card/id


/obj/effect/mob_spawn/human/commander/alive
	death = FALSE
	roundstart = FALSE
	job_description = "Nanotrasen Commander"
	mob_name = "Nanotrasen Commander"
	name = "sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "You are a Nanotrasen Commander!"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/nanotrasensoldier/alive
	death = FALSE
	roundstart = FALSE
	mob_name = "Private Security Officer"
	job_description = "Nanotrasen Security"
	name = "sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	faction = "nanotrasenprivate"
	short_desc = "You are a Nanotrasen Private Security Officer!"
	can_load_appearance = TRUE

/////////////////Spooky Undead//////////////////////

/obj/effect/mob_spawn/human/skeleton
	name = "skeletal remains"
	mob_name = "skeleton"
	mob_species = /datum/species/skeleton/space
	mob_gender = NEUTER

/obj/effect/mob_spawn/human/skeleton/alive
	death = FALSE
	roundstart = FALSE
	job_description = "Skeleton"
	icon = 'icons/effects/blood.dmi'
	icon_state = "remains"
	short_desc = "By unknown powers, your skeletal remains have been reanimated!"
	flavour_text = "Walk this mortal plain and terrorize all living adventurers who dare cross your path."
	assignedrole = "Skeleton"

/obj/effect/mob_spawn/human/skeleton/alive/Initialize(mapload)
	. = ..()
	var/arrpee = rand(1,2)
	switch(arrpee)
		if(1)
			flavour_text += " You're a miner from a long since lost mining expiditon. You had been assigned to this cursed rock to preform work for a individual mining company to preform a survery of its potential gain. \
			However, the last thing you remember is fighting for your life when you were ambushed by the local fuana with a friend of yours before it all went dark."
			outfit.uniform = /obj/item/clothing/under/rank/cargo/miner/lavaland
			outfit.suit = /obj/item/clothing/suit/space/hardsuit/mining
			outfit.shoes = /obj/item/clothing/shoes/workboots/mining
			outfit.gloves = /obj/item/clothing/gloves/fingerless
			outfit.back = /obj/item/storage/backpack
			outfit.mask = /obj/item/clothing/mask/gas/explorer
			r_pocket = /obj/item/kitchen/knife/combat
		if(2)
			flavour_text += " You were a pirate ship captain on the hunt for a foretold treasure, from stories of cultists to a legendary pirate hiding their treasure in this hellscape! \
			However, it sadly seems you weren't destined to collect it for when you landed here with your crew, slashing and blasting your way through the hoards of beast lurking below this abandoned facility. \
			You had been betrayed by your own second in hand, that blasted devil tried to claim the treasure for their own, but jokes on them, they wouldn't get too far."
			outfit.uniform = /obj/item/clothing/under/costume/pirate
			outfit.suit = /obj/item/clothing/suit/pirate/captain
			outfit.back = /obj/item/storage/backpack/satchel
			outfit.shoes = /obj/item/clothing/shoes/jackboots
			outfit.head = /obj/item/clothing/head/pirate/captain
			r_pocket = /obj/item/melee/transforming/energy/sword/pirate

/obj/effect/mob_spawn/human/zombie
	name = "rotting corpse"
	mob_name = "zombie"
	mob_species = /datum/species/zombie
	assignedrole = "Zombie"

/obj/effect/mob_spawn/human/zombie/alive
	death = FALSE
	roundstart = FALSE
	job_description = "Zombie"
	icon = 'icons/effects/blood.dmi'
	icon_state = "remains"
	short_desc = "By unknown powers, your rotting remains have been resurrected!"
	flavour_text = "Walk this mortal plain and terrorize all living adventurers who dare cross your path."



/obj/effect/mob_spawn/human/abductor
	name = "abductor"
	mob_name = "alien"
	mob_species = /datum/species/abductor
	outfit = /datum/outfit/abductorcorpse

/datum/outfit/abductorcorpse
	name = "Abductor Corpse"
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/combat


//For ghost bar.
/obj/effect/mob_spawn/human/alive/space_bar_patron
	name = "Bar cryogenics"
	mob_name = "Bar patron"
	random = TRUE
	permanent = TRUE
	uses = -1
	outfit = /datum/outfit/spacebartender
	assignedrole = "Space Bar Patron"
	job_description = "Space Bar Patron"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/alive/space_bar_patron/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/despawn = alert("Return to cryosleep? (Warning, Your mob will be deleted!)",,"Да","Нет")
	if(despawn == "Нет" || !loc || !Adjacent(user))
		return
	user.visible_message("<span class='notice'>[user.name] climbs back into cryosleep...</span>")
	qdel(user)

/datum/outfit/cryobartender
	name = "Cryogenic Bartender"
	uniform = /obj/item/clothing/under/rank/civilian/bartender
	back = /obj/item/storage/backpack
	shoes = /obj/item/clothing/shoes/sneakers/black
	suit = /obj/item/clothing/suit/armor/vest
	glasses = /obj/item/clothing/glasses/sunglasses/reagent

/obj/effect/mob_spawn/human/lavaknight
	name = "odd cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise a faint glow underneath the built up ice. The machine is attempting to wake up its occupant."
	mob_name = "a displaced knight from another dimension"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	id_job = "Knight"
	job_description = "Cydonian Knight"
	death = FALSE
	random = TRUE
	outfit = /datum/outfit/lavaknight
	mob_species = /datum/species/human
	flavour_text = "<font size=3><b>Y</b></font><b>ou are a knight who conveniently has some form of retrograde amnesia. \
	You cannot remember where you came from. However, a few things remain burnt into your mind, most prominently a vow to never harm another sapient being under any circumstances unless it is hellbent on ending your life. \
	Remember: hostile creatures and such are fair game for attacking, but <span class='danger'>under no circumstances are you to attack anything capable of thought and/or speech</span> unless it has made it its life's calling to chase you to the ends of the earth."
	assignedrole = "Cydonian Knight"

/obj/effect/mob_spawn/human/lavaknight/special(mob/living/new_spawn)
	. = ..()
	if(ishuman(new_spawn))
		var/mob/living/carbon/human/H = new_spawn
		H.dna.features["mam_ears"] = "Cat, Big"	//cat people
		H.dna.features["mcolor"] = H.hair_color
		H.update_body()

/obj/effect/mob_spawn/human/lavaknight/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/datum/outfit/lavaknight
	name = "Cydonian Knight"
	uniform = /obj/item/clothing/under/misc/assistantformal
	mask = /obj/item/clothing/mask/breath
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_pocket = /obj/item/melee/transforming/energy/sword/cx
	suit = /obj/item/clothing/suit/space/hardsuit/lavaknight
	suit_store = /obj/item/tank/internals/oxygen
	id = /obj/item/card/id/knight/blue

/obj/effect/mob_spawn/human/lavaknight/captain
	name = "odd gilded cryogenics pod"
	desc = "A humming cryo pod that appears to be gilded. You can barely recognise a faint glow underneath the built up ice. The machine is attempting to wake up its occupant."
	flavour_text = "<font size=3><b>Y</b></font><b>ou are a knight who conveniently has some form of retrograde amnesia. \
	You cannot remember where you came from. However, a few things remain burnt into your mind, most prominently a vow to never harm another sapient being under any circumstances unless it is hellbent on ending your life. \
	Remember: hostile creatures and such are fair game for attacking, but <span class='danger'>under no circumstances are you to attack anything capable of thought and/or speech</span> unless it has made it its life's calling to chase you to the ends of the earth. \
	You feel a natural instict to lead, and as such, you should strive to lead your comrades to safety, and hopefully home. You also feel a burning determination to uphold your vow, as well as your fellow comrade's."
	outfit = /datum/outfit/lavaknight/captain
	id_job = "Knight Captain"

/datum/outfit/lavaknight/captain
	name ="Cydonian Knight Captain"
	l_pocket = /obj/item/dualsaber/hypereutactic
	id = /obj/item/card/id/knight/captain
