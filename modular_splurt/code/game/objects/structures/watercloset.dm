/obj/machinery/shower/wash_mob(mob/living/L)
	. = ..()
	L.wash_cum()
	/* BLUEMOON REMOVAL START - смывание текста с частей тела теперь производится с помощью мыла
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		for(var/obj/item/bodypart/BP in H.bodyparts)
			BP.writtentext = ""
		for(var/obj/item/organ/genital/G in H.internal_organs)
			if(istype(G) && G.is_exposed())
				G.writtentext = ""
	/ BLUEMOON REMOVAL END */

/obj/machinery/shower/wash_obj(obj/O)
	. = ..()
	if(!O)
		return
	. = O.wash_cum()
