/obj/item/organ/genital/womb
	name = "womb"
	ru_name = "матка"
	ru_name_v = "матке"
	ru_name_capital = "Матка"
	desc = "A female reproductive organ."
	icon = 'icons/obj/genitals/vagina.dmi'
	icon_state = "womb"
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_WOMB
	genital_flags = GENITAL_INTERNAL|GENITAL_FUID_PRODUCTION|HAS_EQUIPMENT
	fluid_id = /datum/reagent/consumable/semen/femcum
	linked_organ_slot = ORGAN_SLOT_VAGINA

/obj/item/organ/genital/womb/get_features(mob/living/carbon/human/H)
	var/datum/dna/D = H.dna
	if(D.features["inert_eggs"])
		AddComponent(/datum/component/ovipositor)
