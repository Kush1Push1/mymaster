// Used for translating channels to tokens on examination
GLOBAL_LIST_INIT(channel_tokens, list(
	RADIO_CHANNEL_COMMON = RADIO_KEY_COMMON,
	RADIO_CHANNEL_SCIENCE = RADIO_TOKEN_SCIENCE,
	RADIO_CHANNEL_COMMAND = RADIO_TOKEN_COMMAND,
	RADIO_CHANNEL_MEDICAL = RADIO_TOKEN_MEDICAL,
	RADIO_CHANNEL_ENGINEERING = RADIO_TOKEN_ENGINEERING,
	RADIO_CHANNEL_SECURITY = RADIO_TOKEN_SECURITY,
	RADIO_CHANNEL_LAW = RADIO_TOKEN_LAW,
	RADIO_CHANNEL_CENTCOM = RADIO_TOKEN_CENTCOM,
	RADIO_CHANNEL_SYNDICATE = RADIO_TOKEN_SYNDICATE,
	RADIO_CHANNEL_DS1 = RADIO_TOKEN_DS1,
	RADIO_CHANNEL_DS2 = RADIO_TOKEN_DS2,
	RADIO_CHANNEL_TARKOFF = RADIO_TOKEN_TARKOFF,
	RADIO_CHANNEL_PIRATE = RADIO_TOKEN_PIRATE,
	RADIO_CHANNEL_INTEQ = RADIO_TOKEN_INTEQ,
	RADIO_CHANNEL_SUPPLY = RADIO_TOKEN_SUPPLY,
	RADIO_CHANNEL_SERVICE = RADIO_TOKEN_SERVICE,
	RADIO_CHANNEL_HOTEL = RADIO_TOKEN_HOTEL, //SPLURT EDIT ADDITION
	MODE_BINARY = MODE_TOKEN_BINARY,
	RADIO_CHANNEL_AI_PRIVATE = RADIO_TOKEN_AI_PRIVATE
))

/obj/item/radio/headset
	name = "radio headset"
	desc = "An updated, modular intercom that fits over the head. Takes encryption keys."
	icon_state = "headset"
	item_state = "headset"
	custom_materials = list(/datum/material/iron=75)
	subspace_transmission = TRUE
	canhear_range = 0 // can't hear headsets from very far away

	slot_flags = ITEM_SLOT_EARS
	var/obj/item/encryptionkey/keyslot2 = null
	dog_fashion = null
	var/bowman = FALSE

	// headset is too small to display overlays
	overlay_speaker_idle = null
	overlay_speaker_active = null
	overlay_mic_idle = null
	overlay_mic_active = null

/obj/item/radio/headset/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins putting \the [src]'s antenna up [user.ru_ego()] nose! It looks like [user.ru_who()] trying to give себя cancer!</span>")
	return TOXLOSS

/obj/item/radio/headset/examine(mob/user)
	. = ..()

	if(item_flags & IN_INVENTORY && loc == user)
		// construction of frequency description
		var/list/avail_chans = list("Use [RADIO_KEY_COMMON] for the currently tuned frequency")
		if(translate_binary)
			avail_chans += "use [MODE_TOKEN_BINARY] for [MODE_BINARY]"
		if(length(channels))
			for(var/i in 1 to length(channels))
				if(i == 1)
					avail_chans += "use [MODE_TOKEN_DEPARTMENT] or [GLOB.channel_tokens[channels[i]]] for [lowertext(channels[i])]"
				else
					avail_chans += "use [GLOB.channel_tokens[channels[i]]] for [lowertext(channels[i])]"
		. += "<span class='notice'>A small screen on the headset displays the following available frequencies:\n[english_list(avail_chans)]."

		if(command)
			. += "<span class='info'>Alt-click to toggle the high-volume mode.</span>"
	else
		. += "<span class='notice'>A small screen on the headset flashes, it's too small to read without holding or wearing the headset.</span>"

/obj/item/radio/headset/ComponentInitialize()
	. = ..()
	if (bowman)
		AddComponent(/datum/component/wearertargeting/earprotection, list(ITEM_SLOT_EARS_LEFT, ITEM_SLOT_EARS_RIGHT))

/obj/item/radio/headset/Initialize(mapload)
	. = ..()
	recalculateChannels()

/obj/item/radio/headset/Destroy()
	QDEL_NULL(keyslot2)
	return ..()

/obj/item/radio/headset/talk_into(mob/living/M, message, channel, list/spans,datum/language/language)
	if (!listening)
		return ITALICS | REDUCE_RANGE
	if (language != /datum/language/signlanguage)
		return ..()

/obj/item/radio/headset/can_receive(freq, level, AIuser)
	if(ishuman(src.loc))
		var/mob/living/carbon/human/H = src.loc
		if(H.ears == src)
			return ..(freq, level)
		//skyrat edit
		else if(H.ears_extra == src)
			return ..(freq, level)
		//
	else if(AIuser)
		return ..(freq, level)
	return FALSE

/obj/item/radio/headset/MouseDrop(mob/over, src_location, over_location)
	var/mob/headset_user = usr
	if((headset_user == over) && headset_user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return attack_self(headset_user)
	return ..()

/obj/item/radio/headset/syndicate //disguised to look like a normal headset for stealth ops

/obj/item/radio/headset/syndicate/alt //undisguised bowman with flash protection
	name = "Syndicate Headset"
	desc = "Боевые наушники Синдиката, способные прослушивать рацию всех ближайших используемых диапазонов. Защищает уши от громких звуков."
	icon_state = "syndie_headset"
	item_state = "syndie_headset"
	bowman = TRUE

/obj/item/radio/headset/syndicate/alt/leader
	name = "Team Leader Syndicate Headset"
	command = TRUE

/obj/item/radio/headset/syndicate/Initialize(mapload)
	. = ..()
	make_syndie()

/obj/item/radio/headset/pirate

/obj/item/radio/headset/pirate/Initialize(mapload)
	. = ..()
	make_pirate()

/obj/item/radio/headset/inteq //disguised to look like a normal headset for stealth ops

/obj/item/radio/headset/inteq/alt //undisguised bowman with flash protection
	name = "InteQ Headset"
	desc = "Боевые наушники InteQ, способные прослушивать рацию всех ближайших используемых диапазонов. Защищает уши от громких звуков."
	icon_state = "inteq_headset_alt"
	item_state = "inteq_headset_alt"
	//freqlock = TRUE
	bowman = TRUE
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol_head.dmi'
	//mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_head.dmi'
	radiosound = 'modular_bluemoon/kovac_shitcode/sound/radio.ogg'

/obj/item/radio/headset/inteq/alt/leader
	name = "Team Leader InteQ Headset"
	command = TRUE

/obj/item/radio/headset/inteq/Initialize(mapload)
	. = ..()
	make_inteq()

/obj/item/radio/headset/binary

/obj/item/radio/headset/binary/Initialize(mapload)
	. = ..()
	qdel(keyslot)
	keyslot = new /obj/item/encryptionkey/binary
	recalculateChannels()

/obj/item/radio/headset/headset_prisoner
	name = "prison radio headset"
	desc = "An updated, modular intercom that fits over the head. Takes encryption keys. It looks like it has been modified to not broadcast."
	icon_state = "prisoner_headset"
	prison_radio = TRUE

/obj/item/radio/headset/headset_sec
	name = "security radio headset"
	desc = "This is used by your elite security force."
	icon_state = "sec_headset"
	keyslot = new /obj/item/encryptionkey/headset_sec


/obj/item/radio/headset/headset_sec/alt
	name = "security bowman headset"
	desc = "This is used by your elite security force. Protects ears from flashbangs."
	icon_state = "sec_headset_alt"
	item_state = "sec_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_law
	name = "law radio headset"
	desc = "This is used by your local budget lawyer."
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	icon_state = "law_headset"
	keyslot = new /obj/item/encryptionkey/headset_law

/obj/item/radio/headset/headset_law/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/law
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/headset_eng
	name = "engineering radio headset"
	desc = "When the engineers wish to chat like girls."
	icon_state = "eng_headset"
	keyslot = new /obj/item/encryptionkey/headset_eng

/obj/item/radio/headset/headset_med
	name = "medical radio headset"
	desc = "A headset for the trained staff of the medbay."
	icon_state = "med_headset"
	keyslot = new /obj/item/encryptionkey/headset_med

/obj/item/radio/headset/headset_sci
	name = "science radio headset"
	desc = "A sciency headset. Like usual."
	icon_state = "sci_headset"
	keyslot = new /obj/item/encryptionkey/headset_sci

/obj/item/radio/headset/headset_medsci
	name = "medical research radio headset"
	desc = "A headset that is a result of the mating between medical and science."
	icon_state = "medsci_headset"
	keyslot = new /obj/item/encryptionkey/headset_medsci

/obj/item/radio/headset/headset_com
	name = "command radio headset"
	desc = "A headset with a commanding channel.\nTo access the command channel, use :c."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/headset_com

/obj/item/radio/headset/heads
	command = TRUE

/obj/item/radio/headset/heads/captain
	name = "\proper the captain's headset"
	desc = "The headset of the king."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/captain

/obj/item/radio/headset/heads/captain/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/cap
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator



/obj/item/radio/headset/heads/captain/alt
	name = "\proper the captain's bowman headset"
	desc = "The headset of the boss. Protects ears from flashbangs."
	icon_state = "com_headset_alt"
	item_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/rd
	name = "\proper the research director's headset"
	desc = "Headset of the fellow who keeps society marching towards technological singularity."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/rd

/obj/item/radio/headset/heads/rd/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/rd
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/heads/hos
	name = "\proper the head of security's headset"
	desc = "The headset of the man in charge of keeping order and protecting the station."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/hos

/obj/item/radio/headset/heads/hos/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/law
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/heads/hos/alt
	name = "\proper the head of security's bowman headset"
	desc = "The headset of the man in charge of keeping order and protecting the station. Protects ears from flashbangs."
	icon_state = "com_headset_alt"
	item_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/ce
	name = "\proper the chief engineer's headset"
	desc = "The headset of the guy in charge of keeping the station powered and undamaged."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/ce

/obj/item/radio/headset/heads/ce/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/ce
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/heads/cmo
	name = "\proper the chief medical officer's headset"
	desc = "The headset of the highly trained medical chief."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/cmo

/obj/item/radio/headset/heads/cmo/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/cmo
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/heads/hop
	name = "\proper the head of personnel's headset"
	desc = "The headset of the guy who will one day be captain."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/hop

/obj/item/radio/headset/heads/qm
	name = "\proper the quartermaster's headset"
	desc = "The headset of the king (or queen) of paperwork."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/qm

/obj/item/radio/headset/heads/qm/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/qm
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/headset_cargo
	name = "supply radio headset"
	desc = "A headset used by the QM and his slaves."
	icon_state = "cargo_headset"
	keyslot = new /obj/item/encryptionkey/headset_cargo

/obj/item/radio/headset/headset_cargo/mining
	name = "mining radio headset"
	desc = "Headset used by shaft miners."
	icon_state = "mine_headset"
	keyslot = new /obj/item/encryptionkey/headset_mining

/obj/item/radio/headset/headset_srv
	name = "service radio headset"
	desc = "Headset used by the service staff, tasked with keeping the station full, happy and clean."
	icon_state = "srv_headset"
	keyslot = new /obj/item/encryptionkey/headset_service

/obj/item/radio/headset/headset_clown
	name = "clown's headset"
	desc = "A headset for the clown. Finally. A megaphone you can't take away."
	icon_state = "srv_headset"
	keyslot = new /obj/item/encryptionkey/headset_service
	command = TRUE
	commandspan = SPAN_CLOWN

/obj/item/radio/headset/headset_clown/equipped(mob/user, slot)
	..()
	if((slot == ITEM_SLOT_EARS_LEFT) || (slot == ITEM_SLOT_EARS_RIGHT))
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/clown
	else
		user.typing_indicator_state = /obj/effect/overlay/typing_indicator

/obj/item/radio/headset/headset_cent
	name = "\improper CentCom headset"
	desc = "A headset used by the upper echelons of Nanotrasen."
	icon_state = "cent_headset"
	keyslot = new /obj/item/encryptionkey/headset_com
	keyslot2 = new /obj/item/encryptionkey/headset_cent

/obj/item/radio/headset/headset_cent/empty
	keyslot = null
	keyslot2 = null

/obj/item/radio/headset/headset_cent/commander
	keyslot = new /obj/item/encryptionkey/heads/captain

/obj/item/radio/headset/headset_cent/alt
	name = "\improper CentCom bowman headset"
	desc = "A headset especially for emergency response personnel. Protects ears from flashbangs."
	icon_state = "cent_headset_alt"
	item_state = "cent_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/silicon/pai
	name = "\proper mini Integrated Subspace Transceiver "
	subspace_transmission = FALSE

/obj/item/radio/headset/silicon/pai/emp_act(severity)
	. = ..()
	return EMP_PROTECT_SELF

/obj/item/radio/headset/silicon/ai
	name = "\proper Integrated Subspace Transceiver "
	keyslot2 = new /obj/item/encryptionkey/ai
	command = TRUE

/obj/item/radio/headset/silicon/can_receive(freq, level)
	return ..(freq, level, TRUE)

/obj/item/radio/headset/attackby(obj/item/W, mob/user, params)
	user.set_machine(src)
	if (istype(W,/obj/item/headsetupgrader))
		if (!bowman)
			to_chat(user,"<span class='notice'>You upgrade [src].</span>")
			bowmanize()
			qdel(W)
	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(keyslot || keyslot2)
			for(var/ch_name in channels)
				SSradio.remove_object(src, GLOB.radiochannels[ch_name])
				secure_radio_connections[ch_name] = null

			if(keyslot)
				user.put_in_hands(keyslot)
				keyslot = null
			if(keyslot2)
				user.put_in_hands(keyslot2)
				keyslot2 = null

			recalculateChannels()
			to_chat(user, "<span class='notice'>You pop out the encryption keys in the headset.</span>")

		else
			to_chat(user, "<span class='warning'>This headset doesn't have any unique encryption keys!  How useless...</span>")

	else if(istype(W, /obj/item/encryptionkey))
		if(keyslot && keyslot2)
			to_chat(user, "<span class='warning'>The headset can't hold another key!</span>")
			return

		if(!keyslot)
			if(!user.transferItemToLoc(W, src))
				return
			keyslot = W

		else
			if(!user.transferItemToLoc(W, src))
				return
			keyslot2 = W


		recalculateChannels()
	else
		return ..()


/obj/item/radio/headset/recalculateChannels()
	..()
	if(keyslot2)
		for(var/ch_name in keyslot2.channels)
			if(!(ch_name in src.channels))
				channels[ch_name] = keyslot2.channels[ch_name]

		if(keyslot2.translate_binary)
			translate_binary = TRUE
		if(keyslot2.syndie)
			syndie = TRUE
		if (keyslot2.independent)
			independent = TRUE

	for(var/ch_name in channels)
		secure_radio_connections[ch_name] = add_radio(src, GLOB.radiochannels[ch_name])

/obj/item/radio/headset/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !Adjacent(user) || user.incapacitated())
		return
	if (command)
		use_command = !use_command
		to_chat(user, "<span class='notice'>You toggle high-volume mode [use_command ? "on" : "off"].</span>")
		return TRUE

/obj/item/radio/headset/proc/bowmanize()
	cut_overlays()
	var/icon/yeas = icon(icon,icon_state)
	icon_state = "antenna_alt"
	var/mutable_appearance/center = mutable_appearance(icon,"center_alt")
	center.color = yeas.GetPixel(15,18)
	var/mutable_appearance/centeralt = mutable_appearance(icon,"centeralt_alt")
	centeralt.color = yeas.GetPixel(14,22)
	var/mutable_appearance/centercenter = mutable_appearance(icon,"centercenter_alt")
	centercenter.color = yeas.GetPixel(13,19)
	var/mutable_appearance/centerpixel = mutable_appearance(icon,"centerpixel_alt")
	centerpixel.color = yeas.GetPixel(13,21)
	add_overlay(center)
	add_overlay(centeralt)
	add_overlay(centercenter)
	add_overlay(centerpixel)
	name = replacetext(name,"headset", "bowman headset")
	desc = "[desc] Protects ears from flashbangs."
	bowman = TRUE
	AddComponent(/datum/component/wearertargeting/earprotection, list(ITEM_SLOT_EARS_LEFT, ITEM_SLOT_EARS_RIGHT))
