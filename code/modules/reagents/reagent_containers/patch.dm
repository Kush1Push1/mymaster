/obj/item/reagent_containers/pill/patch
	name = "chemical patch"
	desc = "A chemical patch for touch based applications."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bandaid"
	item_state = "patch1" //bandaid replaced by BM
	possible_transfer_amounts = list()
	volume = 40
	apply_type = PATCH
	apply_method = "apply"
	self_delay = 30		// three seconds
	dissolvable = FALSE

/obj/item/reagent_containers/pill/patch/attack(mob/living/L, mob/user)
	if(ishuman(L))
		var/obj/item/bodypart/affecting = L.get_bodypart(check_zone(user.zone_selected))
		if(!affecting)
			to_chat(user, "<span class='warning'>The limb is missing!</span>")
			return
		if(!L.can_inject(user, TRUE, user.zone_selected, FALSE, TRUE)) //stopped by clothing, not by species immunity.
			return
		if(!affecting.is_organic_limb())
			to_chat(user, "<span class='notice'>Medicine won't work on a robotic limb!</span>")
		else if(!affecting.is_organic_limb(FALSE))
			to_chat(user, "<span class='notice'>Medical patches won't work on a biomechanical limb!</span>")
			return
	..()

/obj/item/reagent_containers/pill/patch/canconsume(mob/eater, mob/user)
	if(!iscarbon(eater))
		return FALSE
	return TRUE // Masks were stopping people from "eating" patches. Thanks, inheritance.

/obj/item/reagent_containers/pill/patch/styptic
	name = "brute patch"
	desc = "Helps with brute injuries."
	list_reagents = list(/datum/reagent/medicine/styptic_powder = 20)
	icon_state = "patch2" //bandaid_brute replaced by BM

/obj/item/reagent_containers/pill/patch/silver_sulf
	name = "burn patch"
	desc = "Helps with burn injuries."
	list_reagents = list(/datum/reagent/medicine/silver_sulfadiazine = 20)
	icon_state = "patch3" //bandaid_burn replaced by BM

/obj/item/reagent_containers/pill/patch/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")
