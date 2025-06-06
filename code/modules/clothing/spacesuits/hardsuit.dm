	//Baseline hardsuits
/obj/item/clothing/head/helmet/space/hardsuit
	name = "hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
	icon_state = "hardsuit0-engineering"
	item_state = "eng_helm"
	max_integrity = 300
	armor = list(MELEE = 10, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 50, ACID = 75, WOUND = 15)
	var/basestate = "hardsuit"
	var/brightness_on = 4 //luminosity when on
	var/on = FALSE
	var/obj/item/clothing/suit/space/hardsuit/suit
	var/hardsuit_type = "engineering" //Determines used sprites: hardsuit[on]-[type]
	actions_types = list(/datum/action/item_action/toggle_helmet_light)

	var/rad_count = 0
	var/rad_record = 0
	var/grace_count = 0
	var/datum/looping_sound/geiger/soundloop

/obj/item/clothing/head/helmet/space/hardsuit/Initialize(mapload)
	. = ..()
	soundloop = new(src, FALSE, TRUE)
	soundloop.volume = 5
	START_PROCESSING(SSobj, src)

/obj/item/clothing/head/helmet/space/hardsuit/Destroy()
	. = ..()
	if(!QDELETED(suit))
		qdel(suit)
	suit = null
	QDEL_NULL(soundloop)
	STOP_PROCESSING(SSobj, src)

/obj/item/clothing/head/helmet/space/hardsuit/attack_self(mob/user)
	on = !on
	update_icon() //the mob overlay update is already done by the update_icon_updates_onmob element.
	if(on)
		set_light(brightness_on)
	else
		set_light(0)

/obj/item/clothing/head/helmet/space/hardsuit/update_icon_state()
	icon_state = "[basestate][on]-[hardsuit_type]"

/obj/item/clothing/head/helmet/space/hardsuit/dropped(mob/user)
	..()
	if(suit && !ismob(loc)) //equipped() will handle mob cases, so it doesn't disengage twice.
		suit.RemoveHelmet()
		soundloop.stop(user)

/obj/item/clothing/head/helmet/space/hardsuit/item_action_slot_check(slot, mob/user, datum/action/A)
	if(slot == ITEM_SLOT_HEAD)
		return TRUE

/obj/item/clothing/head/helmet/space/hardsuit/equipped(mob/user, slot)
	..()
	if(slot != ITEM_SLOT_HEAD)
		if(suit)
			suit.RemoveHelmet()
			soundloop.stop(user)
		else
			qdel(src)
	else
		soundloop.start(user)

/obj/item/clothing/head/helmet/space/hardsuit/proc/display_visor_message(var/msg)
	var/mob/wearer = loc
	if(msg && ishuman(wearer))
		wearer.show_message("[icon2html(src, wearer)]<b><span class='robot'>[msg]</span></b>", MSG_VISUAL)

/obj/item/clothing/head/helmet/space/hardsuit/rad_act(severity)
	. = ..()
	rad_count += severity

/obj/item/clothing/head/helmet/space/hardsuit/process()
	if(!rad_count)
		grace_count++
		if(grace_count == 2)
			soundloop.last_radiation = 0
		return

	grace_count = 0
	rad_record -= rad_record/5
	rad_record += rad_count/5
	rad_count = 0

	soundloop.last_radiation = rad_record

/obj/item/clothing/head/helmet/space/hardsuit/emp_act(severity)
	. = ..()
	display_visor_message("[severity > 1 ? "Light" : "Strong"] electromagnetic pulse detected!")


/obj/item/clothing/suit/space/hardsuit
	name = "hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
	icon_state = "hardsuit-engineering"
	item_state = "eng_hardsuit"
	tail_state = "atmos"
	max_integrity = 300
	armor = list(MELEE = 10, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 50, ACID = 75, WOUND = 15)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/t_scanner, /obj/item/construction/rcd, /obj/item/pipe_dispenser)
	siemens_coefficient = 0
	var/obj/item/clothing/head/helmet/space/hardsuit/helmet
	actions_types = list(/datum/action/item_action/toggle_helmet)
	var/helmettype = /obj/item/clothing/head/helmet/space/hardsuit
	var/obj/item/tank/jetpack/suit/jetpack = null
	var/hardsuit_type
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC //bluemood add

/obj/item/clothing/suit/space/hardsuit/Initialize(mapload)
	if(jetpack && ispath(jetpack))
		jetpack = new jetpack(src)
	allowed += list(/obj/item/device/cooler) // BLUEMOON ADD - на все скафандры есть возможность повесить ПОУ
	return ..()

/obj/item/clothing/suit/space/hardsuit/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/tank/jetpack/suit))
		if(jetpack)
			to_chat(user, "<span class='warning'>[src] already has a jetpack installed.</span>")
			return
		if(src == user.get_item_by_slot(ITEM_SLOT_OCLOTHING)) //Make sure the player is not wearing the suit before applying the upgrade.
			to_chat(user, "<span class='warning'>You cannot install the upgrade to [src] while wearing it.</span>")
			return

		if(user.transferItemToLoc(I, src))
			jetpack = I
			to_chat(user, "<span class='notice'>You successfully install the jetpack into [src].</span>")
			return
	else if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(!jetpack)
			to_chat(user, "<span class='warning'>[src] has no jetpack installed.</span>")
			return
		if(src == user.get_item_by_slot(ITEM_SLOT_OCLOTHING))
			to_chat(user, "<span class='warning'>You cannot remove the jetpack from [src] while wearing it.</span>")
			return

		jetpack.turn_off(user)
		jetpack.forceMove(drop_location())
		jetpack = null
		to_chat(user, "<span class='notice'>You successfully remove the jetpack from [src].</span>")
		return
	return ..()


/obj/item/clothing/suit/space/hardsuit/equipped(mob/user, slot)
	..()
	if(jetpack)
		if(slot == ITEM_SLOT_OCLOTHING)
			for(var/X in jetpack.actions)
				var/datum/action/A = X
				A.Grant(user)

/obj/item/clothing/suit/space/hardsuit/dropped(mob/user)
	..()
	if(jetpack)
		for(var/X in jetpack.actions)
			var/datum/action/A = X
			A.Remove(user)

/obj/item/clothing/suit/space/hardsuit/item_action_slot_check(slot, mob/user, datum/action/A)
	if(slot == ITEM_SLOT_OCLOTHING) //we only give the mob the ability to toggle the helmet if he's wearing the hardsuit.
		return TRUE

	//Engineering
/obj/item/clothing/head/helmet/space/hardsuit/engine
	name = "engineering hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
	icon_state = "hardsuit0-engineering"
	item_state = "eng_helm"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 100, ACID = 75, WOUND = 15)
	hardsuit_type = "engineering"
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/space/hardsuit/engine
	name = "engineering hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
	icon_state = "hardsuit-engineering"
	item_state = "eng_hardsuit"
	tail_state = "engineer"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 100, ACID = 75, WOUND = 15)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/engine
	resistance_flags = FIRE_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

	//Atmospherics
/obj/item/clothing/head/helmet/space/hardsuit/engine/atmos
	name = "atmospherics hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has thermal shielding."
	icon_state = "hardsuit0-atmospherics"
	item_state = "atmo_helm"
	hardsuit_type = "atmospherics"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 25, FIRE = 100, ACID = 75, WOUND = 15)
	heat_protection = HEAD												//Uncomment to enable firesuit protection
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/obj/item/clothing/suit/space/hardsuit/engine/atmos
	name = "atmospherics hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has thermal shielding."
	icon_state = "hardsuit-atmospherics"
	item_state = "atmo_hardsuit"
	tail_state = "atmos"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 25, FIRE = 100, ACID = 75, WOUND = 15)
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS					//Uncomment to enable firesuit protection
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/engine/atmos

	//Chief Engineer's hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/engine/elite
	name = "advanced hardsuit helmet"
	desc = "An advanced helmet designed for work in a hazardous, low pressure environment. Shines with a high polish."
	icon_state = "hardsuit0-white"
	item_state = "ce_helm"
	hardsuit_type = "white"
	armor = list(MELEE = 40, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 90, WOUND = 20)
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/obj/item/clothing/suit/space/hardsuit/engine/elite
	icon_state = "hardsuit-white"
	name = "advanced hardsuit"
	desc = "An advanced suit that protects against hazardous, low pressure environments. Shines with a high polish."
	item_state = "ce_hardsuit"
	tail_state = "ce"
	armor = list(MELEE = 40, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 90, WOUND = 20)
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/engine/elite
	jetpack = /obj/item/tank/jetpack/suit

	//Mining hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/mining
	name = "mining hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has reinforced plating for wildlife encounters and dual floodlights."
	icon_state = "hardsuit0-mining"
	item_state = "mining_helm"
	hardsuit_type = "mining"
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF
	heat_protection = HEAD
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 50, BIO = 100, RAD = 50, FIRE = 50, ACID = 75, WOUND = 25)
	brightness_on = 7
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator)

/obj/item/clothing/head/helmet/space/hardsuit/mining/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/armor_plate)
	RegisterSignal(src, COMSIG_ARMOR_PLATED, PROC_REF(upgrade_icon))

/obj/item/clothing/head/helmet/space/hardsuit/mining/proc/upgrade_icon(datum/source, amount, maxamount)
	SIGNAL_HANDLER

	if(amount)
		name = "reinforced [initial(name)]"
		hardsuit_type = "mining_goliath"
		if(amount == maxamount)
			hardsuit_type = "mining_goliath_full"
	icon_state = "hardsuit[on]-[hardsuit_type]"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.head == src)
			wearer.update_inv_head()

/obj/item/clothing/suit/space/hardsuit/mining
	icon_state = "hardsuit-mining"
	name = "mining hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has reinforced plating for wildlife encounters."
	item_state = "mining_hardsuit"
	hardsuit_type = "mining"
	tail_state = "engineer"
	flags_inv = HIDEGLOVES | HIDEJUMPSUIT | HIDESHOES | HIDETAUR
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 50, BIO = 100, RAD = 50, FIRE = 50, ACID = 75, WOUND = 25)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/storage/bag/ore, /obj/item/pickaxe)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/mining
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

/obj/item/clothing/suit/space/hardsuit/mining/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/armor_plate)
	RegisterSignal(src, COMSIG_ARMOR_PLATED, PROC_REF(upgrade_icon))

/obj/item/clothing/suit/space/hardsuit/mining/proc/upgrade_icon(datum/source, amount, maxamount)
	SIGNAL_HANDLER

	if(amount)
		name = "reinforced [initial(name)]"
		hardsuit_type = "mining_goliath"
		if(amount == maxamount)
			hardsuit_type = "mining_goliath_full"
			tail_state = "ert-alert"
	icon_state = "hardsuit-[hardsuit_type]"
	tail_state = "ert-alert"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.wear_suit == src)
			wearer.update_inv_wear_suit()

	//Syndicate hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/syndi
	name = "blood-red hardsuit helmet"
	desc = "A dual-mode advanced helmet designed for work in special operations. It is in EVA mode. Property of Gorlex Marauders."
	alt_desc = "A dual-mode advanced helmet designed for work in special operations. It is in combat mode. Property of Gorlex Marauders."
	icon_state = "hardsuit1-syndi"
	item_state = "syndie_helm"
	hardsuit_type = "syndi"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 50, FIRE = 50, ACID = 90, WOUND = 25)
	on = FALSE
	var/obj/item/clothing/suit/space/hardsuit/syndi/linkedsuit = null
	actions_types = list(/datum/action/item_action/toggle_helmet_mode)
	visor_flags_inv = HIDEMASK|HIDEEYES|HIDEFACE|HIDEFACIALHAIR
	visor_flags = STOPSPRESSUREDAMAGE
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR // BLUEMOON ADD enabling visibility of snouts, faces and beards in combat mode

/obj/item/clothing/head/helmet/space/hardsuit/syndi/update_icon_state()
	icon_state = "hardsuit[on]-[hardsuit_type]"

/obj/item/clothing/head/helmet/space/hardsuit/syndi/Initialize(mapload)
	. = ..()
	if(istype(loc, /obj/item/clothing/suit/space/hardsuit/syndi))
		linkedsuit = loc

/obj/item/clothing/head/helmet/space/hardsuit/syndi/Destroy()
	linkedsuit = null
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/syndi/attack_self(mob/user) //Toggle Helmet
	if(!isturf(user.loc))
		to_chat(user, "<span class='warning'>You cannot toggle your helmet while in this [user.loc]!</span>" )
		return
	on = !on
	if(on || force)
		to_chat(user, "<span class='notice'>You switch your hardsuit to EVA mode, sacrificing speed for space protection.</span>")
		name = initial(name)
		desc = initial(desc)
		set_light(brightness_on)
		clothing_flags |= visor_flags
		flags_cover |= HEADCOVERSEYES | HEADCOVERSMOUTH
		flags_inv |= visor_flags_inv
		cold_protection |= HEAD
	else
		to_chat(user, "<span class='notice'>You switch your hardsuit to combat mode and can now run at full speed.</span>")
		name += " (combat)"
		desc = alt_desc
		set_light(0)
		clothing_flags &= ~visor_flags
		flags_cover &= ~(HEADCOVERSEYES | HEADCOVERSMOUTH)
		flags_inv &= ~visor_flags_inv
		cold_protection &= ~HEAD
	update_icon()
	playsound(src.loc, 'sound/mecha/mechmove03.ogg', 50, 1)
	toggle_hardsuit_mode(user)
	user.update_inv_head()
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.head_update(src, forced = 1)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtons()

/obj/item/clothing/head/helmet/space/hardsuit/syndi/proc/toggle_hardsuit_mode(mob/user) //Helmet Toggles Suit Mode
	if(linkedsuit)
		if(on)
			linkedsuit.name = initial(linkedsuit.name)
			linkedsuit.desc = initial(linkedsuit.desc)
			linkedsuit.slowdown = 0.5
			linkedsuit.clothing_flags |= STOPSPRESSUREDAMAGE
			linkedsuit.cold_protection |= CHEST | GROIN | LEGS | FEET | ARMS | HANDS
		else
			linkedsuit.name += " (combat)"
			linkedsuit.desc = linkedsuit.alt_desc
			linkedsuit.slowdown = 0
			linkedsuit.clothing_flags &= ~STOPSPRESSUREDAMAGE
			linkedsuit.cold_protection &= ~(CHEST | GROIN | LEGS | FEET | ARMS | HANDS)

		linkedsuit.icon_state = "hardsuit[on]-[hardsuit_type]"
		linkedsuit.update_icon()
		user.update_inv_wear_suit()
		user.update_inv_w_uniform()
		user.update_equipment_speed_mods()

/obj/item/clothing/suit/space/hardsuit/syndi
	name = "blood-red hardsuit"
	desc = "A dual-mode advanced hardsuit designed for work in special operations. It is in EVA mode. Property of Gorlex Marauders."
	alt_desc = "A dual-mode advanced hardsuit designed for work in special operations. It is in combat mode. Property of Gorlex Marauders."
	icon_state = "hardsuit1-syndi"
	item_state = "syndie_hardsuit"
	tail_state = "syndicate-blood"
	hardsuit_type = "syndi"
	w_class = WEIGHT_CLASS_NORMAL
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 50, FIRE = 50, ACID = 90, WOUND = 25)
	allowed = list(/obj/item/gun, /obj/item/ammo_box,/obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi
	jetpack = /obj/item/tank/jetpack/suit
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

//Elite Syndie suit
/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite
	name = "elite syndicate hardsuit helmet"
	desc = "An elite version of the syndicate helmet, with improved armour and fireproofing. It is in EVA mode. Property of Gorlex Marauders."
	alt_desc = "An elite version of the syndicate helmet, with improved armour and fireproofing. It is in combat mode. Property of Gorlex Marauders."
	icon_state = "hardsuit0-syndielite"
	hardsuit_type = "syndielite"
	armor = list(MELEE = 60, BULLET = 60, LASER = 50, ENERGY = 25, BOMB = 55, BIO = 100, RAD = 70, FIRE = 100, ACID = 100, WOUND = 30)
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/debug

/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/debug/Initialize(mapload)
	. = ..()
	soundloop.volume = 0

/obj/item/clothing/suit/space/hardsuit/syndi/elite
	name = "Elite Syndicate Hardsuit"
	desc = "An elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in travel mode."
	alt_desc = "An elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in combat mode."
	icon_state = "hardsuit0-syndielite"
	tail_state = "syndicate-elite"
	hardsuit_type = "syndielite"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite
	armor = list(MELEE = 60, BULLET = 60, LASER = 50, ENERGY = 25, BOMB = 55, BIO = 100, RAD = 70, FIRE = 100, ACID = 100, WOUND = 30)
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC|STYLE_PAW_TAURIC

/obj/item/clothing/suit/space/hardsuit/syndi/elite/debug
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/debug
	slowdown = 0

/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/winter
	name = "Winter Elite Syndicate Hardsuit Helmet"
	desc = "An winter elite version of the syndicate helmet, with improved armour and fireproofing. It is in EVA mode. Property of Gorlex Marauders."
	alt_desc = "An elite version of the syndicate helmet, with improved armour and fireproofing. It is in combat mode. Property of Gorlex Marauders."
	icon_state = "hardsuit0-syndi-winter"
	hardsuit_type = "syndi-winter"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT // BLUEMOON ADD enabling hiding 'cause helmet sprite does not truly opening

/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter
	name = "Winter Elite Syndicate Hardsuit"
	desc = "An winter elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in travel mode."
	alt_desc = "An elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in combat mode."
	icon_state = "hardsuit0-syndi-winter"
	tail_state = "syndicate-winter"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/winter
	hardsuit_type = "syndi-winter"

/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/wintertas
	name = "Winter Elite Syndicate Hardsuit Helmet V2"
	desc = "An winter elite version of the syndicate helmet, with improved armour and fireproofing. It is in EVA mode. Property of Gorlex Marauders."
	alt_desc = "An elite version of the syndicate helmet, with improved armour and fireproofing. It is in combat mode. Property of Gorlex Marauders."
	icon_state = "hardsuit0-syndi-wintertas"
	hardsuit_type = "syndi-wintertas"

/obj/item/clothing/suit/space/hardsuit/syndi/elite/wintertas
	name = "Winter Elite Syndicate Hardsuit V2"
	desc = "An winter elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in travel mode."
	alt_desc = "An elite version of the syndicate hardsuit, with improved armour and fireproofing. It is in combat mode."
	icon_state = "hardsuit0-syndi-wintertas"
	tail_state = "syndicate-winter"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/wintertas
	hardsuit_type = "syndi-wintertas"

//The Owl Hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/syndi/owl
	name = "owl hardsuit helmet"
	desc = "A dual-mode advanced helmet designed for any crime-fighting situation. It is in travel mode."
	alt_desc = "A dual-mode advanced helmet designed for any crime-fighting situation. It is in combat mode."
	icon_state = "hardsuit1-owl"
	item_state = "s_helmet"
	hardsuit_type = "owl"
	visor_flags_inv = 0
	visor_flags = 0
	on = FALSE

/obj/item/clothing/suit/space/hardsuit/syndi/owl
	name = "owl hardsuit"
	desc = "A dual-mode advanced hardsuit designed for any crime-fighting situation. It is in travel mode."
	alt_desc = "A dual-mode advanced hardsuit designed for any crime-fighting situation. It is in combat mode."
	icon_state = "hardsuit1-owl"
	item_state = "s_suit"
	tail_state = "syndicate-winter"
	hardsuit_type = "owl"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/owl
	mutantrace_variation = STYLE_DIGITIGRADE

	//Wizard hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/wizard
	name = "gem-encrusted hardsuit helmet"
	desc = "A bizarre gem-encrusted helmet that radiates magical energies."
	icon_state = "hardsuit0-wiz"
	item_state = "wiz_helm"
	hardsuit_type = "wiz"
	resistance_flags = FIRE_PROOF | ACID_PROOF //No longer shall our kind be foiled by lone chemists with spray bottles!
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 35, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)
	var/magic_flags = SPELL_WIZARD_HAT|SPELL_CULT_HELMET

	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/head/helmet/space/hardsuit/wizard/ComponentInitialize()
	. = ..()
	if(magic_flags)
		AddElement(/datum/element/spellcasting, magic_flags, ITEM_SLOT_HEAD)

/obj/item/clothing/suit/space/hardsuit/wizard
	icon_state = "hardsuit-wiz"
	name = "gem-encrusted hardsuit"
	desc = "A bizarre gem-encrusted suit that radiates magical energies."
	item_state = "wiz_hardsuit"
	tail_state = "wizard"
	slowdown = -0.5
	w_class = WEIGHT_CLASS_NORMAL
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 35, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)
	allowed = list(/obj/item/teleportation_scroll, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/wizard
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
	var/magic_flags = SPELL_WIZARD_ROBE|SPELL_CULT_ARMOR

	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/suit/space/hardsuit/wizard/ComponentInitialize()
	. = ..()
	if(magic_flags)
		AddElement(/datum/element/spellcasting, magic_flags, ITEM_SLOT_OCLOTHING)

	//Medical hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/medical
	name = "medical hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Built with lightweight materials for extra comfort, but does not protect the eyes from intense light."
	icon_state = "hardsuit0-medical"
	item_state = "medical_helm"
	hardsuit_type = "medical"
	flash_protect = 0
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 60, FIRE = 60, ACID = 75, WOUND = 10)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS | SCAN_REAGENTS

/obj/item/clothing/head/helmet/space/hardsuit/medical/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		DHUD.add_hud_to(user)

/obj/item/clothing/head/helmet/space/hardsuit/medical/dropped(mob/living/carbon/human/user)
	..()
	if (user.head == src)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		DHUD.remove_hud_from(user)

/obj/item/clothing/suit/space/hardsuit/medical
	icon_state = "hardsuit-medical"
	name = "medical hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Built with lightweight materials for easier movement."
	item_state = "medical_hardsuit"
	tail_state = "syndicate-winter"
	slowdown = 0.5
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/storage/firstaid, /obj/item/healthanalyzer, /obj/item/stack/medical)
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 60, FIRE = 60, ACID = 75, WOUND = 15)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/medical
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

	//Research Director hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/rd
	name = "prototype hardsuit helmet"
	desc = "A prototype helmet designed for research in a hazardous, low pressure environment. Scientific data flashes across the visor."
	icon_state = "hardsuit0-rd"
	hardsuit_type = "rd"
	resistance_flags = ACID_PROOF | FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 100, BIO = 100, RAD = 60, FIRE = 60, ACID = 80, WOUND = 15)
	var/obj/machinery/doppler_array/integrated/bomb_radar
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS | SCAN_REAGENTS
	actions_types = list(/datum/action/item_action/toggle_helmet_light, /datum/action/item_action/toggle_research_scanner)

/obj/item/clothing/head/helmet/space/hardsuit/rd/Initialize(mapload)
	. = ..()
	bomb_radar = new /obj/machinery/doppler_array/integrated(src)

/obj/item/clothing/head/helmet/space/hardsuit/rd/Destroy()
	QDEL_NULL(bomb_radar)
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/rd/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
		DHUD.add_hud_to(user)

/obj/item/clothing/head/helmet/space/hardsuit/rd/dropped(mob/living/carbon/human/user)
	..()
	if (user.head == src)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
		DHUD.remove_hud_from(user)

/obj/item/clothing/suit/space/hardsuit/rd
	icon_state = "hardsuit-rd"
	name = "prototype hardsuit"
	desc = "A prototype suit that protects against hazardous, low pressure environments. Fitted with extensive plating for handling explosives and dangerous research materials."
	item_state = "hardsuit-rd"
	tail_state = "rd"
	resistance_flags = ACID_PROOF | FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT //Same as an emergency firesuit. Not ideal for extended exposure.
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/gun/energy/wormhole_projector,
	/obj/item/hand_tele, /obj/item/aicard)
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 100, BIO = 100, RAD = 60, FIRE = 60, ACID = 80, WOUND = 15)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/rd

	//Blue Shield hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/blue_shield
	name = "Blue Shield hardsuit helmet"
	desc = "A special helmet designed for light combat suit."
	icon_state = "hardsuit0-blueshield"
	item_state = "hardsuit0-blueshield"
	hardsuit_type = "blueshield"
	armor = list(MELEE = 40, BULLET = 35, LASER = 35, ENERGY = 45, BOMB = 25, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 30)

/obj/item/clothing/suit/space/hardsuit/blue_shield
	name = "Blue Shield hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Made from light matrials with layer of armor"
	icon_state = "hardsuit-blueshield"
	item_state = "hardsuit-blueshield"
	hardsuit_type = "blueshield"
	tail_state = "hos"
	slowdown = 0
	w_class = WEIGHT_CLASS_NORMAL
	jetpack = /obj/item/tank/jetpack/suit
	armor = list(MELEE = 40, BULLET = 35, LASER = 35, ENERGY = 45, BOMB = 25, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 30)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/blue_shield
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC

	//Security hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/security
	name = "security hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has an additional layer of armor."
	icon_state = "hardsuit0-sec"
	item_state = "sec_helm"
	hardsuit_type = "sec"
	armor = list(MELEE = 40, BULLET = 35, LASER = 35, ENERGY = 45, BOMB = 25, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 30)
	// BLUEMOON ADD START - RESKINS-ICON-FILE-ADDITION - ACRADORS - версия шлема для ушей акрадоров
	unique_reskin = list(
		"Acrador/Long-Eared" = list(
			RESKIN_ICON_STATE = "hardsuit0-sec_acrador",
			RESKIN_ITEM_STATE = "hardsuit0-sec_acrador",
			RESKIN_ICON_STATE_FILE = 'modular_bluemoon/icons/obj/clothing/hats.dmi',
			RESKIN_WORN_STATE_FILE = 'modular_bluemoon/icons/mob/clothing/hats.dmi',
			RESKIN_ANTHRO_WORN_STATE_FILE = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
		)
	)

/obj/item/clothing/head/helmet/space/hardsuit/security/reskin_obj(mob/user)
	if(current_skin == "Acrador/Long-Eared")
		hardsuit_type = "sec_acrador"
	//BLUEMOON ADD END

/obj/item/clothing/suit/space/hardsuit/security
	icon_state = "hardsuit-sec"
	name = "security hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has an additional layer of armor."
	item_state = "sec_hardsuit"
	tail_state = "sec"
	armor = list(MELEE = 40, BULLET = 35, LASER = 35, ENERGY = 45, BOMB = 25, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 30)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC
	//BLUEMOON ADD вариация хардсьюта сб
	unique_reskin = list(
		"Alt" = list(RESKIN_ICON_STATE = "hardsuit-sec2"),
		"Blue Variation" = list(RESKIN_ICON_STATE = "hardsuit-sec3")
	)

/obj/item/clothing/suit/space/hardsuit/security/reskin_obj(mob/user)
	if(current_skin == "Alt")
		mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
		tail_state = "sec2"
		if(helmet)
			var/obj/item/clothing/head/helmet/space/hardsuit/Helm = helmet
			Helm.hardsuit_type = "sec2"
			Helm.update_icon_state()
	if(current_skin == "Blue Variation")
		mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
		tail_state = "ert-commander"
		if(helmet)
			var/obj/item/clothing/head/helmet/space/hardsuit/Helm = helmet
			Helm.hardsuit_type = "sec3"
			Helm.update_icon_state()
	//BLUEMOON ADD END

/obj/item/clothing/suit/space/hardsuit/security/Initialize(mapload)
	. = ..()
	allowed = GLOB.security_hardsuit_allowed

	//Head of Security hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/security/hos
	name = "Head of Security's Hardsuit Helmet"
	desc = "A special bulky helmet designed for work in a hazardous, low pressure environment. Has an additional layer of armor."
	icon_state = "hardsuit0-hos"
	hardsuit_type = "hos"
	armor = list(MELEE = 45, BULLET = 50, LASER = 40, ENERGY = 50, BOMB = 25, BIO = 100, RAD = 50, FIRE = 95, ACID = 95, WOUND = 40)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/space/hardsuit/security/hos
	name = "Head of Security's Hardsuit"
	desc = "A special bulky suit that protects against hazardous, low pressure environments. Has an additional layer of armor."
	icon_state = "hardsuit-hos"
	tail_state = "hos"
	armor = list(MELEE = 45, BULLET = 50, LASER = 40, ENERGY = 50, BOMB = 25, BIO = 100, RAD = 50, FIRE = 95, ACID = 95, WOUND = 40)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/hos
	jetpack = /obj/item/tank/jetpack/suit
	unique_reskin = list(
		"Standart Variation" = list(RESKIN_ICON_STATE = "hardsuit-hos"),
		"OTA Variation" = list(RESKIN_ICON_STATE = "hardsuit-alliance")
	)

/obj/item/clothing/suit/space/hardsuit/security/hos/reskin_obj(mob/user)
	if(current_skin == "OTA Variation")
		mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
		tail_state = "syndicate-winter"
		if(helmet)
			var/obj/item/clothing/head/helmet/space/hardsuit/Helm = helmet
			Helm.hardsuit_type = "alliance"
			Helm.update_icon_state()
	if(current_skin == "Standart Variation")
		mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
		tail_state = "hos"
		if(helmet)
			var/obj/item/clothing/head/helmet/space/hardsuit/Helm = helmet
			Helm.hardsuit_type = "hos"
			Helm.update_icon_state()

	//Captain
/obj/item/clothing/head/helmet/space/hardsuit/captain
	name = "captain's hardsuit helmet"
	icon_state = "capspace"
	item_state = "capspacehelmet"
	desc = "A tactical SWAT helmet MK.II boasting better protection and a horrible fashion sense."
	armor = list(MELEE = 40, BULLET = 50, LASER = 50, ENERGY = 25, BOMB = 50, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR //we want to see the mask
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	actions_types = list()

/obj/item/clothing/head/helmet/space/hardsuit/captain/attack_self()
	return //Sprites required for flashlight

/obj/item/clothing/suit/space/hardsuit/captain
	name = "captain's SWAT suit"
	desc = "A MK.II SWAT suit with streamlined joints and armor made out of superior materials, insulated against intense heat. The most advanced tactical armor available Usually reserved for heavy hitter corporate security, this one has a regal finish in Nanotrasen company colors. Better not let the assistants get a hold of it."
	icon_state = "caparmor"
	item_state = "capspacesuit"
	tail_state = "captain"
	armor = list(MELEE = 40, BULLET = 50, LASER = 50, ENERGY = 25, BOMB = 50, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 25)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT //this needed to be added a long fucking time ago
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/captain

/obj/item/clothing/suit/space/hardsuit/captain/Initialize(mapload)
	. = ..()
	allowed = GLOB.security_hardsuit_allowed

	//Clown
/obj/item/clothing/head/helmet/space/hardsuit/clown
	name = "cosmohonk hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-humor environment. Has radiation shielding."
	icon_state = "hardsuit0-clown"
	item_state = "hardsuit0-clown"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 60, ACID = 30, WOUND = 15)
	hardsuit_type = "clown"

/obj/item/clothing/suit/space/hardsuit/clown
	name = "cosmohonk hardsuit"
	desc = "A special suit that protects against hazardous, low humor environments. Has radiation shielding. Only a true clown can wear it."
	icon_state = "hardsuit-clown"
	item_state = "clown_hardsuit"
	tail_state = "wizard"
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 10, BIO = 100, RAD = 75, FIRE = 60, ACID = 30, WOUND = 15)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/clown
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/space/hardsuit/clown/mob_can_equip(mob/M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(!..() || !ishuman(M))
		return FALSE
	if(M.mind && HAS_TRAIT(M.mind, TRAIT_CLOWN_MENTALITY))
		return TRUE
	else
		return FALSE

	//Old Prototype
/obj/item/clothing/head/helmet/space/hardsuit/ancient
	name = "prototype RIG hardsuit helmet"
	desc = "Early prototype RIG hardsuit helmet, designed to quickly shift over a user's head. Design constraints of the helmet mean it has no inbuilt cameras, thus it restricts the users visability."
	icon_state = "hardsuit0-ancient"
	item_state = "anc_helm"
	armor = list(MELEE = 30, BULLET = 5, LASER = 5, ENERGY = 0, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 75, WOUND = 15)
	hardsuit_type = "ancient"
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/space/hardsuit/ancient
	name = "prototype RIG hardsuit"
	desc = "Prototype powered RIG hardsuit. Provides excellent protection from the elements of space while being comfortable to move around in, thanks to the powered locomotives. Remains very bulky however."
	icon_state = "hardsuit-ancient"
	item_state = "anc_hardsuit"
	tail_state = "atmos"
	armor = list(MELEE = 30, BULLET = 5, LASER = 5, ENERGY = 0, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 75, WOUND = 15)
	slowdown = 2
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ancient
	resistance_flags = FIRE_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE
	var/footstep = 1
	var/mob/listeningTo

/obj/item/clothing/suit/space/hardsuit/ancient/mason
	name = "M.A.S.O.N RIG"
	desc = "The Multi-Augmented Severe Operations Networked Resource Integration Gear is an man-portable tank designed for extreme environmental situations. It is excessively bulky, but rated for all but the most atomic of hazards. The specialized armor is surprisingly weak to conventional weaponry. The exo slot can attach most storage bags on to the suit."
	icon_state = "hardsuit-ancient"
	item_state = "anc_hardsuit"
	tail_state = "atmos"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 45, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 15)
	slowdown = 4 //Slow
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/storage, /obj/item/construction/rcd, /obj/item/pipe_dispenser)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ancient/mason
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | IMMUTABLE_SLOW
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/item/clothing/head/helmet/space/hardsuit/ancient/mason
	name = "M.A.S.O.N RIG helmet"
	desc = "The M.A.S.O.N RIG helmet is complimentary to the rest of the armor. It features a very large, high powered flood lamp and robust flash protection."
	icon_state = "hardsuit0-ancient"
	item_state = "anc_helm"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 45, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 15)
	hardsuit_type = "ancient"
	brightness_on = 16
	flash_protect = 5 //We will not be flash by bombs
	tint = 1
	var/obj/machinery/doppler_array/integrated/bomb_radar
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS | SCAN_REAGENTS
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/item/clothing/head/helmet/space/hardsuit/ancient/mason/Initialize(mapload)
	. = ..()
	bomb_radar = new /obj/machinery/doppler_array/integrated(src)

/obj/item/clothing/head/helmet/space/hardsuit/ancient/mason/Destroy()
	QDEL_NULL(bomb_radar)
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/ancient/mason/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
		DHUD.add_hud_to(user)
		ADD_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "mason_hardsuit")

/obj/item/clothing/head/helmet/space/hardsuit/ancient/mason/dropped(mob/living/carbon/human/user)
	..()
	if (HAS_TRAIT_FROM(user, TRAIT_TESLA_SHOCKIMMUNE, "mason_hardsuit"))
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
		DHUD.remove_hud_from(user)
		REMOVE_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "mason_hardsuit")

/obj/item/clothing/suit/space/hardsuit/ancient/proc/on_mob_move()
	var/mob/living/carbon/human/H = loc
	if(!istype(H) || H.wear_suit != src)
		return
	if(footstep > 1)
		playsound(src, 'sound/effects/servostep.ogg', 100, 1)
		footstep = 0
	else
		footstep++

/obj/item/clothing/suit/space/hardsuit/ancient/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		if(listeningTo)
			UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		return
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_move))
	listeningTo = user

/obj/item/clothing/suit/space/hardsuit/ancient/dropped(mob/user)
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)

/obj/item/clothing/suit/space/hardsuit/ancient/Destroy()
	listeningTo = null
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/soviet
	name = "soviet hardhelmet"
	desc = "Crafted with the pride of the proletariat. The vengeful gaze of the visor roots out all fascists and capitalists."
	item_state = "rig0-soviet"
	hardsuit_type = "soviet"
	icon_state = "rig0-soviet"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 75, WOUND = 15)
	mutantrace_variation = STYLE_MUZZLE

/obj/item/clothing/suit/space/hardsuit/soviet
	name = "soviet hardsuit"
	desc = "Crafted with the pride of the proletariat. The last thing the enemy sees is the bottom of this armor's boot."
	item_state = "rig-soviet"
	icon_state = "rig-soviet"
	tail_state = "syndicate-blood" // Этот костюм вообще не используется на самом деле в игре, ну да ладно
	slowdown = 0.5
	armor = list(MELEE = 40, BULLET = 30, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 75, WOUND = 15)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/soviet
	mutantrace_variation = NONE

/obj/item/clothing/suit/space/hardsuit/soviet/Initialize(mapload)
	. = ..()
	allowed = GLOB.security_hardsuit_allowed

/////////////SHIELDED//////////////////////////////////

/obj/item/clothing/suit/space/hardsuit/shielded
	name = "shielded hardsuit"
	desc = "A hardsuit with built in energy shielding. Will rapidly recharge when not under fire."
	icon_state = "hardsuit-hos"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/hos
	allowed = null
	armor = list(MELEE = 30, BULLET = 15, LASER = 30, ENERGY = 10, BOMB = 10, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 20)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/max_charges = 3 //How many charges total the shielding has
	var/current_charges //if null, will default to max_chargs
	var/recharge_delay = 200 //How long after we've been shot before we can start recharging. 20 seconds here
	var/recharge_rate = 1 //How quickly the shield recharges once it starts charging
	var/shield_state = "shield-old"

/obj/item/clothing/suit/space/hardsuit/shielded/Initialize(mapload)
	. = ..()
	if(!allowed)
		allowed = GLOB.advanced_hardsuit_allowed

/obj/item/clothing/suit/space/hardsuit/shielded/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/shielded, current_charges, max_charges, recharge_delay, recharge_rate, ITEM_SLOT_OCLOTHING, shield_state)

/obj/item/clothing/head/helmet/space/hardsuit/shielded
	resistance_flags = FIRE_PROOF | ACID_PROOF

///////////////Capture the Flag////////////////////

/obj/item/clothing/suit/space/hardsuit/shielded/ctf
	name = "white shielded hardsuit"
	desc = "Standard issue hardsuit for playing capture the flag."
	icon_state = "ert_medical"
	item_state = "ert_medical"
	tail_state = "ert_medical"
	hardsuit_type = "ert_gmedical"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf
	armor = list(MELEE = 0, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 50, BIO = 100, RAD = 100, FIRE = 95, ACID = 95, WOUND = 30)
	slowdown = 0
	max_charges = 5

/obj/item/clothing/suit/space/hardsuit/shielded/ctf/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CAPTURE_THE_FLAG_TRAIT)

/obj/item/clothing/suit/space/hardsuit/shielded/ctf/red
	name = "red shielded hardsuit"
	icon_state = "ert_security"
	item_state = "ert_security"
	tail_state = "ert-alert"
	hardsuit_type = "ert_gsecurity"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf/red
	shield_state = "shield-red"

/obj/item/clothing/suit/space/hardsuit/shielded/ctf/blue
	name = "blue shielded hardsuit"
	desc = "Standard issue hardsuit for playing capture the flag."
	icon_state = "ert_command"
	item_state = "ert_command"
	tail_state = "ert-alert"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf/blue

/obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf
	name = "shielded hardsuit helmet"
	desc = "Standard issue hardsuit helmet for playing capture the flag."
	icon_state = "hardsuit0-ert_medical"
	item_state = "hardsuit0-ert_medical"
	hardsuit_type = "ert_medical"
	armor = list(MELEE = 0, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 50, BIO = 100, RAD = 100, FIRE = 95, ACID = 95, WOUND = 30)

/obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf/red
	icon_state = "hardsuit0-ert_security"
	item_state = "hardsuit0-ert_security"
	hardsuit_type = "ert_security"

/obj/item/clothing/head/helmet/space/hardsuit/shielded/ctf/blue
	name = "shielded hardsuit helmet"
	desc = "Standard issue hardsuit helmet for playing capture the flag."
	icon_state = "hardsuit0-ert_commander"
	item_state = "hardsuit0-ert_commander"
	hardsuit_type = "ert_commander"

//////Syndicate Version

/obj/item/clothing/suit/space/hardsuit/shielded/syndi
	name = "blood-red hardsuit"
	desc = "An advanced hardsuit with built in energy shielding."
	icon_state = "hardsuit1-syndi"
	item_state = "syndie_hardsuit"
	tail_state = "syndicate-blood"
	hardsuit_type = "syndi"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/syndi
	slowdown = 0
	max_charges = 4
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

/obj/item/clothing/suit/space/hardsuit/shielded/syndi/Initialize(mapload)
	jetpack = new /obj/item/tank/jetpack/suit(src)
	. = ..()

/obj/item/clothing/head/helmet/space/hardsuit/shielded/syndi
	name = "blood-red hardsuit helmet"
	desc = "An advanced hardsuit helmet with built in energy shielding."
	icon_state = "hardsuit1-syndi"
	item_state = "syndie_helm"
	hardsuit_type = "syndi"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)

///SWAT version
/obj/item/clothing/suit/space/hardsuit/shielded/swat
	name = "death commando spacesuit"
	desc = "An advanced hardsuit favored by commandos for use in special operations."
	icon_state = "deathsquad"
	item_state = "swat_suit"
	tail_state = "deathsquad"
	hardsuit_type = "syndi"
	max_charges = 4
	recharge_delay = 15
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 50, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/swat
	dog_fashion = /datum/dog_fashion/back/deathsquad

/obj/item/clothing/head/helmet/space/hardsuit/shielded/swat
	name = "death commando helmet"
	desc = "A tactical helmet with built in energy shielding."
	icon_state = "deathsquad"
	item_state = "deathsquad"
	hardsuit_type = "syndi"
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 50, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	actions_types = list()

/*
			CYDONIAN ARMOR THAT IS RGB AND STUFF WOOOOOOOOOO
*/

/obj/item/clothing/head/helmet/space/hardsuit/lavaknight
	name = "cydonian helmet"
	desc = "A helmet designed with both form and function in mind, it protects the user against physical trauma and hazardous conditions while also having polychromic light strips."
	icon_state = "hardsuit0-knight_cydonia"
	item_state = "knight_yellow"
	hardsuit_type = "knight_cydonia"
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	heat_protection = HEAD
	armor = list(melee = 50, bullet = 10, laser = 10, energy = 10, bomb = 50, bio = 100, rad = 50, fire = 100, acid = 100, WOUND = 30)
	brightness_on = 7
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator)
	var/energy_color = "#35FFF0"
	var/obj/item/clothing/suit/space/hardsuit/lavaknight/linkedsuit = null
	mutantrace_variation = NONE

/obj/item/clothing/head/helmet/space/hardsuit/lavaknight/Initialize(mapload)
	. = ..()
	if(istype(loc, /obj/item/clothing/suit/space/hardsuit/lavaknight))
		var/obj/item/clothing/suit/space/hardsuit/lavaknight/S = loc
		energy_color = S.energy_color
	update_icon()

/obj/item/clothing/head/helmet/space/hardsuit/lavaknight/attack_self(mob/user)
	on = !on

	if(on)
		set_light(brightness_on)
	else
		set_light(0)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtons()

/obj/item/clothing/head/helmet/space/hardsuit/lavaknight/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "knight_cydonia_overlay", color = energy_color)

/obj/item/clothing/head/helmet/space/hardsuit/lavaknight/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		var/mutable_appearance/energy_overlay = mutable_appearance(icon_file, "knight_cydonia_overlay", EMISSIVE_LAYER)
		energy_overlay.plane = EMISSIVE_PLANE
		energy_overlay.color = energy_color
		. += energy_overlay

/obj/item/clothing/suit/space/hardsuit/lavaknight
	icon_state = "knight_cydonia"
	name = "cydonian armor"
	desc = "A suit designed with both form and function in mind, it protects the user against physical trauma and hazardous conditions while also having polychromic light strips."
	item_state = "swat_suit"
	tail_state = "syndicate-winter"
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	armor = list(melee = 50, bullet = 10, laser = 10, energy = 10, bomb = 50, bio = 100, rad = 50, fire = 100, acid = 100, WOUND = 30)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/storage/bag/ore, /obj/item/pickaxe)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/lavaknight
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	var/energy_color = "#35FFF0"

/obj/item/clothing/suit/space/hardsuit/lavaknight/Initialize(mapload)
	. = ..()
	light_color = energy_color
	set_light(1)
	update_icon()

/obj/item/clothing/suit/space/hardsuit/lavaknight/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "knight_cydonia_overlay", color = energy_color)

/obj/item/clothing/suit/space/hardsuit/lavaknight/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		var/mutable_appearance/energy_overlay = mutable_appearance(icon_file, "knight_cydonia_overlay", EMISSIVE_LAYER)
		energy_overlay.plane = EMISSIVE_PLANE
		energy_overlay.color = energy_color
		. += energy_overlay

/obj/item/clothing/suit/space/hardsuit/lavaknight/AltClick(mob/living/user)
	. = ..()
	if(!in_range(src, user) || !istype(user))
		return
	if(user.incapacitated())
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return TRUE

	if(alert("Are you sure you want to recolor your armor stripes?", "Confirm Repaint", "Yes", "No") == "Yes")
		var/energy_color_input = input(usr,"","Choose Energy Color",energy_color) as color|null
		if(energy_color_input)
			energy_color = sanitize_hexcolor(energy_color_input, desired_format=6, include_crunch=1)
			user.update_inv_wear_suit()
			if(helmet)
				var/obj/item/clothing/head/helmet/space/hardsuit/lavaknight/H = helmet
				H.energy_color = energy_color
				user.update_inv_head()
				H.update_icon()
			update_icon()
			user.update_inv_wear_suit()
			light_color = energy_color
			update_light()
	return TRUE

/obj/item/clothing/suit/space/hardsuit/lavaknight/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click to recolor it.</span>"
