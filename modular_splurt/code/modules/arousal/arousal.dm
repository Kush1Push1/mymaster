/mob/living/carbon/human/mob_climax_partner(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30, obj/item/organ/genital/Lgen = null, forced = FALSE, anonymous = FALSE)
	. = ..()
	L.receive_climax(src, Lgen, G, spillage, forced = forced)
	if(iswendigo(L))
		var/mob/living/carbon/wendigo/W = L
		if(W.pulling == src)
			W.slaves |= src
			to_chat(src, "<font color='red'> You are now [W]'s slave! Serve your master properly! </font>")

/mob/living/proc/receive_climax(mob/living/partner, obj/item/organ/genital/receiver, obj/item/organ/genital/source, spill, forced)

	if (istype(receiver, /obj/item/organ/genital/penis) || istype(receiver, /obj/item/organ/genital/vagina))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)
	else if (istype(receiver, /obj/item/organ/genital/anus))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_ASS, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)
	else if (istype(receiver, /obj/item/organ/stomach))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_MOUTH, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)

	//gregnancy...
	if(!spill && istype(source, /obj/item/organ/genital/penis) && \
		istype(receiver, /obj/item/organ/genital/vagina) && getorganslot(ORGAN_SLOT_WOMB))
		var/obj/item/organ/genital/penis/peenus = source
		if(!(locate(/obj/item/genital_equipment/condom) in peenus.contents))
			impregnate(partner)

	if(!receiver || spill || forced)
		return

	receiver.climax_modify_size(partner, source)

//handles impregnation, also prefs
/mob/living/proc/impregnate(mob/living/partner, obj/item/organ/W, baby_type = /mob/living/carbon/human)
	var/obj/item/organ/container = W

	if(!container)
		container = getorganslot(ORGAN_SLOT_WOMB)
	if(!container)
		return

	var/can_impregnate = 100
	if(partner?.client?.prefs)
		can_impregnate = partner.client.prefs.virility
	var/can_get_pregnant = (client?.prefs?.fertility && !is_type_in_typecache(src.type, GLOB.pregnancy_blocked_mob_typecache))
	if(!(can_impregnate && can_get_pregnant))
		return

	var/avg = (can_impregnate + client.prefs.fertility) / 2

	if(prob(avg))
		var/obj/item/oviposition_egg/eggo = new()
		eggo.forceMove(container)
		eggo.AddComponent(/datum/component/pregnancy, src, partner, baby_type)

/mob/living/carbon/human/do_climax(datum/reagents/R, atom/target, obj/item/organ/genital/sender, spill, cover = FALSE, obj/item/organ/genital/receiver, anonymous = FALSE)
	if(!sender)
		return
	if(!target || !R)
		return
	if(SEND_SIGNAL(src, COMSIG_MOB_CLIMAX, R, target, sender, receiver, spill, anonymous))
		return

	var/cached_fluid
	if(isliving(target) && !spill)
		var/mob/living/L = target
		var/list/blacklist = L.client?.prefs.gfluid_blacklist
		if((sender.get_fluid_id() in blacklist) || ((/datum/reagent/blood in blacklist) && ispath(sender.get_fluid_id(), /datum/reagent/blood)))
			cached_fluid = sender.get_fluid_id()
			var/default = sender.get_default_fluid()
			sender.set_fluid_id(default)

	if(istype(sender, /obj/item/organ/genital/penis))
		var/obj/item/organ/genital/penis/bepis = sender
		if(locate(/obj/item/genital_equipment/sounding) in bepis.contents)
			spill = TRUE
			to_chat(src, "<span class='userlove'>Ты чувствуешь, как стержень выталкивается из твоей уретры вместе со струей оргазменной жидкости!</span>")
			var/obj/item/genital_equipment/sounding/rod = locate(/obj/item/genital_equipment/sounding) in bepis.contents
			rod.forceMove(get_turf(src))

	if(cover == TRUE)
		if(istype(sender, /obj/item/organ/genital/penis))
			var/obj/item/organ/genital/testicles/testicles = sender
			var/size = testicles.size
			var/balls_size_0 = list("cum_normal", "cum_normal_1", "cum_normal_2", "cum_normal_3", "cum_normal_4", "", "", "", "", "", "", "", "", "", "")
			var/balls_size_1 = list("cum_normal", "cum_normal_1", "cum_normal_2", "cum_normal_3", "cum_normal_4", "", "", "", "", "")
			var/balls_size_2 = list("cum_normal", "cum_normal_1", "cum_normal_2", "cum_normal_3", "cum_normal_4")
			var/balls_size_3 = list("cum_normal", "cum_normal_1", "cum_normal_2", "cum_normal_3", "cum_normal_4", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large")
			var/balls_size_4 = list("cum_normal", "cum_normal_1", "cum_normal_2", "cum_normal_3", "cum_normal_4", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large", "cum_large")
			switch(size)
				if(BALLS_SIZE_MIN)
					size = pick(balls_size_0)
				if(BALLS_SIZE_DEF)
					size = pick(balls_size_1)
				if(BALLS_SIZE_2)
					size = pick(balls_size_2)
				if(BALLS_SIZE_3)
					size = pick(balls_size_3)
				if(BALLS_SIZE_MAX)
					size = pick(balls_size_4)
			target.add_cum_overlay(size)

	. = ..()

	if(cached_fluid)
		sender.set_fluid_id(cached_fluid)

/mob/living/carbon/human/mob_fill_container(obj/item/organ/genital/G, obj/item/reagent_containers/container, mb_time, obj/item/sucking_machine/M)
	if(!M)
		return ..()

	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	var/main_fluid = lowertext(G.get_fluid_name())
	if(mb_time)
		visible_message("<span class='love'>You hear a strong suction sound coming from the [M.name] on [src]'s [G.name].</span>", \
							"<span class='userlove'>The [M.name] pumps faster, trying to get you over the edge.</span>", \
							"<span class='userlove'>Something vacuums your [G.name] with a quiet but powerfull vrrrr.</span>")
		if(!do_after(src, mb_time, target = src, timed_action_flags = (IGNORE_HELD_ITEM|IGNORE_INCAPACITATED)) || !in_range(src, container) || !G.climaxable(src, TRUE))
			return
	visible_message("<span class='love'>[src] twitches as [ru_ego()] [main_fluid] trickles into <b>[container]</b>.</span>", \
								"<span class='userlove'>[M] sucks out all the [main_fluid] you had been saving up into <b>[container]</b>.</span>", \
								"<span class='userlove'>You feel a vacuum sucking on your [G.name] as you climax!</span>")
	do_climax(fluid_source, container, G, FALSE, cover = TRUE)
	emote("moan")

/mob/living/carbon/human/proc/mob_climax_over(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30)
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time) //Skip warning if this is an instant climax.
		to_chat(src,"<span class='userlove'>You're about to climax over [L]!</span>")
		to_chat(L,"<span class='userlove'>[src] is about to climax over you!</span>")
		if(!do_after(src, mb_time, target = src) || !in_range(src, L) || !G.climaxable(src, TRUE))
			return
	to_chat(src,"<span class='userlove'>You climax all over [L] using your [G.name]!</span>")
	to_chat(L, "<span class='userlove'>[src] climaxes all over you using [ru_ego()] [G.name]!</span>")
	do_climax(fluid_source, L, G, spillage, cover = TRUE)

/mob/living/carbon/human
	var/covered_in_cum = FALSE

/atom/proc/add_cum_overlay(size = "cum_normal", cum_color = "#FFFFFF") //This can go in a better spot, for now its here.
	if(!istype(src, /mob/living/carbon/human))
		return
	if(initial(icon) && initial(icon_state))
		add_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', size, color = cum_color), ICON_MULTIPLY)
		var/mob/living/carbon/human/H = src
		H.covered_in_cum = TRUE
		to_chat(H, span_love("Кажется тебя немножко забрызгали~"))

/mob/living/carbon/human/proc/getPercentAroused()
    var/percentage = ((get_lust() / (get_lust_tolerance() * 3)) * 100)
    return percentage

/atom/proc/wash_cum()
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_normal"))
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_normal_1"))
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_normal_2"))
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_normal_3"))
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_normal_4"))
	cut_overlay(mutable_appearance('modular_splurt/icons/effects/cumoverlay.dmi', "cum_large"))
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		H.covered_in_cum = FALSE
	return TRUE

//arousal hud display

/atom/movable/screen/arousal
	name = "arousal"
	icon_state = "arousal0"
	icon = 'icons/obj/genitals/hud.dmi'
	screen_loc = ui_arousal

/atom/movable/screen/arousal/Initialize(mapload, mob/living/carbon/human/owner)
	. = ..()
	if(!istype(owner))
		return INITIALIZE_HINT_QDEL
	RegisterSignal(owner, COMSIG_MOB_LUST_UPDATED, PROC_REF(update_lust))

/atom/movable/screen/arousal/Click()
	if(!ishuman(usr))
		return FALSE
	if(!usr.client?.prefs.arousable)
		return
	var/mob/living/M = usr
	M.interact_with()

/atom/movable/screen/arousal/proc/update_lust(mob/living/carbon/human/source)
	SIGNAL_HANDLER

	if(!istype(source))
		return
	if(!source.client || !source.hud_used)
		return

	var/arousal_level = 0
	if(source.stat != DEAD)
		arousal_level = min(FLOOR(source.getPercentAroused(), 10),100)
	icon_state = "arousal[arousal_level]"
