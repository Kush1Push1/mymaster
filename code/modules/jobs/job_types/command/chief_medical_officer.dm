/datum/job/cmo
	title = "Chief Medical Officer"
	flag = CMO_JF
	department_head = list("Captain")
	department_flag = MEDSCI
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD
	head_announce = list(RADIO_CHANNEL_MEDICAL)
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the captain"
	selection_color = "#509ed1"
	req_admin_notify = 1
	minimal_player_age = 35
	exp_requirements = 180
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_MEDICAL
	considered_combat_role = TRUE

	outfit = /datum/outfit/job/cmo
	departments = DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_COMMAND
	plasma_outfit = /datum/outfit/plasmaman/cmo

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_HEADS, ACCESS_MINERAL_STOREROOM,
			ACCESS_CHEMISTRY, ACCESS_VIROLOGY, ACCESS_CMO, ACCESS_SURGERY, ACCESS_RC_ANNOUNCE,
			ACCESS_KEYCARD_AUTH, ACCESS_SEC_DOORS, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_HEADS, ACCESS_MINERAL_STOREROOM,
			ACCESS_CHEMISTRY, ACCESS_VIROLOGY, ACCESS_CMO, ACCESS_SURGERY, ACCESS_RC_ANNOUNCE,
			ACCESS_KEYCARD_AUTH, ACCESS_SEC_DOORS, ACCESS_MAINT_TUNNELS)
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_MED
	bounty_types = CIV_JOB_MED

	mind_traits = list(TRAIT_REAGENT_EXPERT, TRAIT_QUICK_CARRY) //BLUEMOON ADD use TRAIT system for jobs

	display_order = JOB_DISPLAY_ORDER_CHIEF_MEDICAL_OFFICER
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/insanity, /datum/quirk/bluemoon_criminal)
	threat = 2

	starting_modifiers = list(/datum/skill_modifier/job/surgery, /datum/skill_modifier/job/affinity/surgery)

	family_heirlooms = list(
		/obj/item/storage/firstaid/ancient/heirloom,
		/obj/item/scalpel,
		/obj/item/hemostat,
		/obj/item/circular_saw,
		/obj/item/retractor,
		/obj/item/cautery
	)

	mail_goodies = list(
		/obj/effect/spawner/lootdrop/organ_spawner = 10,
//		/obj/effect/spawner/lootdrop/memeorgans = 8,
		/obj/effect/spawner/lootdrop/space/fancytool/advmedicalonly = 4,
		/obj/effect/spawner/lootdrop/space/fancytool/raremedicalonly = 1
	)

/datum/outfit/job/cmo
	name = "Chief Medical Officer"
	jobtype = /datum/job/cmo

	id = /obj/item/card/id/silver
	belt = /obj/item/pda/heads/cmo
	l_pocket = /obj/item/pinpointer/crew
	ears = /obj/item/radio/headset/heads/cmo
	uniform = /obj/item/clothing/under/rank/medical/chief_medical_officer
	shoes = /obj/item/clothing/shoes/sneakers/brown
	suit = /obj/item/clothing/suit/toggle/labcoat/cmo
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen/paramedic
	backpack_contents = list(/obj/item/modular_computer/tablet/preset/advanced=1)
	box = /obj/item/storage/box/survival/command
	accessory = /obj/item/clothing/accessory/permit/special/chief_medic

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med

	chameleon_extras = list(/obj/item/gun/syringe, /obj/item/stamp/cmo)


/datum/outfit/job/cmo/syndicate
	name = "Syndicate Chief Medical Officer"
	jobtype = /datum/job/cmo

	//belt = /obj/item/pda/syndicate/no_deto

	l_pocket = /obj/item/pinpointer/crew
	ears = /obj/item/radio/headset/heads/cmo
	uniform = /obj/item/clothing/under/rank/captain/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit = /obj/item/clothing/suit/toggle/labcoat/cmo
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen/paramedic
	neck = /obj/item/clothing/neck/cloak/syndiecap

	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/syndicate_uplink_high=1)
	accessory = /obj/item/clothing/accessory/permit/special/chief_medic

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med

/datum/outfit/job/cmo/hardsuit
	name = "Chief Medical Officer (Hardsuit)"

	mask = /obj/item/clothing/mask/breath
	suit = /obj/item/clothing/suit/space/hardsuit/medical
	suit_store = /obj/item/tank/internals/oxygen
	r_pocket = /obj/item/flashlight/pen

/datum/outfit/job/cmo/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	. = ..()
	ADD_TRAIT(H, TRAIT_SURGEON, TRAIT_GENERIC)
