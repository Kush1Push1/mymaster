
/mob/living/brain/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	handle_emp_damage()

/mob/living/brain/update_stat()
	if(status_flags & GODMODE)
		return
	if(health <= HEALTH_THRESHOLD_DEAD)
		if(stat != DEAD)
			death()
		var/obj/item/organ/brain/BR
		if(container && container.brain)
			BR = container.brain
		else if(istype(loc, /obj/item/organ/brain))
			BR = loc
		if(BR)
			BR.brain_death = TRUE
	..()

/mob/living/brain/proc/handle_emp_damage()
	if(emp_damage)
		if(stat == DEAD)
			emp_damage = 0
		else
			emp_damage = max(emp_damage-1, 0)

/mob/living/brain/handle_traits()
	return



