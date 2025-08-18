/datum/species/xeno
	mutant_organs = list(/obj/item/organ/alien/resinspinner/hybrids)
	inherent_traits = list(TRAIT_TRUE_NIGHT_VISION)
	exotic_blood = /datum/reagent/toxin/acid
	exotic_bloodtype = "X*"
	exotic_blood_color = BLOOD_COLOR_XENO
	typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/alien
	eye_type = ""
	nojumpsuit = TRUE
	damage_overlay_type = "xeno"
	disliked_food = null
	liked_food = GROSS | MEAT
	species_category = SPECIES_CATEGORY_ALIEN
	wings_icons = SPECIES_WINGS_DRAGON //most depictions of xenomorphs with wings are closest to this.
//	speedmod = -0.1 // Слегка быстрее человека
	burnmod = 1.5 // Лазер наносит 30 урона вместо 20
	heatmod = 1.5 // Горячая атмосфера в 1.5 раз опаснее, как и поджёг
	siemens_coeff = 1.5 // Урон от электризации шлюзов, молний и иного в 1.5 сильнее
	punchdamagelow = 10
	punchdamagehigh = 15
	punchstunthreshold = 15 // Роняют на пол с шансом 20%
	punchwoundbonus = 3 // Как у воксов
	disarm_bonus = 25 // Обычные толчки такие же эффективные, как и пуш в стену

/obj/item/organ/alien/resinspinner/hybrids
	name = "hybrids resin spinner"
	alien_powers = list(/obj/effect/proc_holder/alien/resin/hybrids)

/obj/effect/proc_holder/alien/resin/hybrids // Ослабленная версия
	desc = "Secrete tough malleable resin. Takes time to build and all structures are weak, but hey, it's free!"
	plasma_cost = 0
	structures = list(
		"resin wall" = /obj/structure/alien/resin/wall/weak,
		"resin membrane" = /obj/structure/alien/resin/membrane/weak,
		"resin nest" = /obj/structure/bed/nest/weak,
		"not-spreading glowing resin" = /obj/structure/alien/weeds/node/weak,
		"resin floor" = /obj/structure/alien/weeds/weak)
	var/busy = FALSE

/obj/effect/proc_holder/alien/resin/hybrids/fire(mob/living/carbon/user)
	if(locate(/obj/structure/alien/resin) in user.loc)
		to_chat(user, "<span class='danger'>There is already a resin structure there.</span>")
		return FALSE

	if(!check_vent_block(user))
		return FALSE

	var/choice = input("Choose what you wish to shape. TAKE NOTE - ALL STRUCTURES ARE WEAK FOR ANY DAMAGE!","Resin building") as null|anything in structures
	if(!choice)
		return FALSE
	if (!cost_check(check_turf,user))
		return FALSE
	to_chat(user, "<span class='notice'>You shape a [choice].</span>")
	user.visible_message("<span class='notice'>[user] vomits up a thick purple substance and begins to shape it.</span>")

	busy = TRUE
	if(!do_after(user, 20 SECONDS, target = get_turf(user)))
		busy = FALSE
		return
	busy = FALSE

	choice = structures[choice]
	new choice(user.loc)
	return TRUE

/obj/structure/alien/resin/wall/weak
	name = "weak resin wall"
	desc = "Thick resin solidified into a wall. Looks pretty weak."
	max_integrity = 50

/obj/structure/alien/resin/membrane/weak
	name = "weak resin membrane"
	desc = "Resin just thin enough to let light pass through. Looks pretty weak."
	max_integrity = 30

/obj/structure/bed/nest/weak
	name = "alien nest"
	desc = "It's a gruesome pile of thick, sticky resin shaped like a nest. Looks pretty weak."
	weak = TRUE
	max_integrity = 25

/obj/structure/alien/weeds/node/weak
	name = "weak glowing resin"
	desc = "Blue bioluminescence shines from beneath the surface. Seems like it doesn't expands and weed."
	icon_state = "weednode"
	weak = TRUE

/obj/structure/alien/weeds/weak
	max_integrity = 5
