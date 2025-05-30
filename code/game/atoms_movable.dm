/atom/movable
	layer = OBJ_LAYER
	glide_size = 8
	SET_APPEARANCE_FLAGS(TILE_BOUND | PIXEL_SCALE)
	var/last_move = null
	var/last_move_time = 0
	var/anchored = FALSE
	var/move_resist = MOVE_RESIST_DEFAULT
	var/move_force = MOVE_FORCE_DEFAULT
	var/pull_force = PULL_FORCE_DEFAULT
	var/datum/thrownthing/throwing = null
	var/throw_speed = 2 //How many tiles to move per ds when being thrown. Float values are fully supported
	var/throw_range = 7
	var/mob/pulledby = null
	/// What language holder type to init as
	var/initial_language_holder = /datum/language_holder
	/// Holds all languages this mob can speak and understand
	VAR_PRIVATE/datum/language_holder/language_holder

	var/verb_say = "says"
	var/verb_ask = "asks"
	var/verb_exclaim = "exclaims"
	var/verb_whisper = "whispers"
	var/verb_sing = "sings" // Skyrat edit
	var/verb_yell = "yells"
	var/speech_span
	var/inertia_dir = 0
	var/atom/inertia_last_loc
	var/inertia_moving = 0
	var/inertia_next_move = 0
	var/inertia_move_delay = 5
	/// Things we can pass through while moving. If any of this matches the thing we're trying to pass's [pass_flags_self], then we can pass through.
	var/pass_flags = NONE
	/// If false makes CanPass call CanPassThrough on this type instead of using default behaviour
	var/generic_canpass = TRUE
	var/moving_diagonally = 0 //0: not doing a diagonal move. 1 and 2: doing the first/second step of the diagonal move
	var/atom/movable/moving_from_pull		//attempt to resume grab after moving instead of before.
	///Holds information about any movement loops currently running/waiting to run on the movable. Lazy, will be null if nothing's going on
	var/datum/movement_packet/move_packet
	///contains every client mob corresponding to every client eye in this container. lazily updated by SSparallax and is sparse:
	///only the last container of a client eye has this list assuming no movement since SSparallax's last fire
	var/list/client_mobs_in_contents
	/// String representing the spatial grid groups we want to be held in.
	/// acts as a key to the list of spatial grid contents types we exist in via SSspatial_grid.spatial_grid_categories.
	/// We do it like this to prevent people trying to mutate them and to save memory on holding the lists ourselves
	var/spatial_grid_key
	var/list/acted_explosions	//for explosion dodging
	var/datum/forced_movement/force_moving = null	//handled soley by forced_movement.dm

	/**
	  * In case you have multiple types, you automatically use the most useful one.
	  * IE: Skating on ice, flippers on water, flying over chasm/space, etc.
	  * I reccomend you use the movetype_handler system and not modify this directly, especially for living mobs.
	  */
	var/movement_type = GROUND

	var/atom/movable/pulling
	var/grab_state = 0
	var/throwforce = 0
	var/datum/component/orbiter/orbiting
	/// Used for space ztransit stuff
	var/can_be_z_moved = TRUE
	///If we were without gravity and another animation happened, the bouncing will stop, and we need to restart it in next life().
	var/floating_need_update = FALSE

	var/zfalling = FALSE

	/// Either FALSE, [EMISSIVE_BLOCK_GENERIC], or [EMISSIVE_BLOCK_UNIQUE]
	var/blocks_emissive = FALSE
	///Internal holder for emissive blocker object, do not use directly use blocks_emissive
	var/atom/movable/emissive_blocker/em_block

	/// Should we use tooltips, if the thing does not have the code implemented `get_tooltip_data()`, it will default to examine(src)
	var/tooltips = FALSE
	/// How loudly we yell
	var/yell_power = 50
	/// last time we yelled
	var/last_yell = 0

	// Text-to-bark sounds
	var/sound/vocal_bark
	var/vocal_bark_id
	var/vocal_pitch = 1
	var/vocal_pitch_range = 0.2 //Actual pitch is (pitch - (vocal_pitch_range*0.5)) to (pitch + (vocal_pitch_range*0.5))
	var/vocal_volume = 70 //Baseline. This gets modified by yelling and other factors
	var/vocal_speed = 4 //Lower values are faster, higher values are slower

	var/vocal_current_bark //When barks are queued, this gets passed to the bark proc. If vocal_current_bark doesn't match the args passed to the bark proc (if passed at all), then the bark simply doesn't play. Basic curtailing of spam~

/atom/movable/Initialize(mapload)
	. = ..()
	switch(blocks_emissive)
		if(EMISSIVE_BLOCK_GENERIC)
			var/mutable_appearance/gen_emissive_blocker = mutable_appearance(icon, icon_state, plane = EMISSIVE_PLANE, alpha = src.alpha)
			gen_emissive_blocker.color = GLOB.em_block_color
			gen_emissive_blocker.dir = dir
			gen_emissive_blocker.appearance_flags |= appearance_flags
			add_overlay(list(gen_emissive_blocker))
		if(EMISSIVE_BLOCK_UNIQUE)
			render_target = ref(src)
			em_block = new(src, render_target)
			vis_contents += em_block


/atom/movable/Destroy(force)
	QDEL_NULL(proximity_monitor)
	QDEL_NULL(language_holder)
	QDEL_NULL(em_block)

	unbuckle_all_mobs(force = TRUE)

	if(loc)
		//Restore air flow if we were blocking it (movables with ATMOS_PASS_PROC will need to do this manually if necessary)
		if(((CanAtmosPass == ATMOS_PASS_DENSITY && density) || CanAtmosPass == ATMOS_PASS_NO) && isturf(loc))
			CanAtmosPass = ATMOS_PASS_YES
			air_update_turf(TRUE)
		loc.handle_atom_del(src)

	// if(opacity)
	// 	RemoveElement(/datum/element/light_blocking)

	invisibility = INVISIBILITY_ABSTRACT

	if(pulledby)
		pulledby.stop_pulling()

	if(orbiting)
		orbiting.end_orbit(src)
		orbiting = null

	. = ..()

	//We add ourselves to this list, best to clear it out
	// LAZYCLEARLIST(area_sensitive_contents)

	for(var/movable_content in contents)
		qdel(movable_content)

	moveToNullspace()

	vis_locs = null //clears this atom out of all viscontents
	vis_contents.Cut()

/atom/movable/proc/update_emissive_block()
	if(blocks_emissive != EMISSIVE_BLOCK_GENERIC)
		return
	else if (blocks_emissive == EMISSIVE_BLOCK_GENERIC)
		var/mutable_appearance/gen_emissive_blocker = mutable_appearance(icon, icon_state, plane = EMISSIVE_PLANE, alpha = src.alpha)
		gen_emissive_blocker.color = GLOB.em_block_color
		gen_emissive_blocker.dir = dir
		gen_emissive_blocker.appearance_flags |= appearance_flags
		return gen_emissive_blocker
	else if(blocks_emissive == EMISSIVE_BLOCK_UNIQUE)
		if(!em_block)
			render_target = ref(src)
			em_block = new(src, render_target)
		return em_block

/atom/movable/proc/can_zFall(turf/source, levels = 1, turf/target, direction)
	if(!direction)
		direction = DOWN
	if(!source)
		source = get_turf(src)
		if(!source)
			return FALSE
	if(!target)
		target = get_step_multiz(source, direction)
		if(!target)
			return FALSE
	return !(movement_type & FLYING) && has_gravity(source) && !throwing

/atom/movable/update_overlays()
	var/list/overlays = ..()
	var/emissive_block = update_emissive_block()
	if(emissive_block)
		// Emissive block should always go at the beginning of the list
		overlays.Insert(1, emissive_block)
	return overlays

/atom/movable/proc/onZImpact(turf/T, levels)
	var/atom/highest = T
	for(var/i in T.contents)
		var/atom/A = i
		if(!A.density)
			continue
		if(isobj(A) || ismob(A))
			if(A.layer > highest.layer)
				highest = A
	INVOKE_ASYNC(src, PROC_REF(SpinAnimation), 5, 2)
	throw_impact(highest)
	return TRUE

//For physical constraints to travelling up/down.
/atom/movable/proc/can_zTravel(turf/destination, direction)
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	if(!direction)
		if(!destination)
			return FALSE
		direction = get_dir(T, destination)
	if(direction != UP && direction != DOWN)
		return FALSE
	if(!destination)
		destination = get_step_multiz(src, direction)
		if(!destination)
			return FALSE
	return T.zPassOut(src, direction, destination) && destination.zPassIn(src, direction, T)

/atom/movable/vv_edit_var(var_name, var_value, massedit)
	var/static/list/banned_edits = list("step_x" = TRUE, "step_y" = TRUE, "step_size" = TRUE, "bounds" = TRUE)
	var/static/list/careful_edits = list("bound_x" = TRUE, "bound_y" = TRUE, "bound_width" = TRUE, "bound_height" = TRUE)
	if(banned_edits[var_name])
		return FALSE	//PLEASE no.
	if((careful_edits[var_name]) && (var_value % world.icon_size) != 0)
		return FALSE

	switch(var_name)
		if(NAMEOF(src, x))
			var/turf/T = locate(var_value, y, z)
			if(T)
				admin_teleport(T, !massedit)
				return TRUE
			return FALSE
		if(NAMEOF(src, y))
			var/turf/T = locate(x, var_value, z)
			if(T)
				admin_teleport(T, !massedit)
				return TRUE
			return FALSE
		if(NAMEOF(src, z))
			var/turf/T = locate(x, y, var_value)
			if(T)
				admin_teleport(T, !massedit)
				return TRUE
			return FALSE
		if(NAMEOF(src, loc))
			if(isatom(var_value) || isnull(var_value))
				admin_teleport(var_value, !massedit)
				return TRUE
			return FALSE
		if(NAMEOF(src, anchored))
			set_anchored(var_value)
			. = TRUE
		if(NAMEOF(src, pulledby))
			set_pulledby(var_value)
			. = TRUE
		if(NAMEOF(src, glide_size))
			set_glide_size(var_value)
			. = TRUE
		if(NAMEOF(src, vocal_bark))
			if(isfile(var_value))
				vocal_bark = sound(var_value) //bark() expects vocal_bark to already be a sound datum, for performance reasons. adminbus QoL!
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	return ..()

/atom/movable/proc/start_pulling(atom/movable/AM, state, force = move_force, supress_message = FALSE)
	if(QDELETED(AM))
		return FALSE
	if(!(AM.can_be_pulled(src, state, force)))
		return FALSE

	// If we're pulling something then drop what we're currently pulling and pull this instead.
	if(pulling)
		if(state == 0)
			stop_pulling()
			return FALSE
		// Are we trying to pull something we are already pulling? Then enter grab cycle and end.
		if(AM == pulling)
			setGrabState(state)
			if(istype(AM,/mob/living))
				var/mob/living/AMob = AM
				AMob.grabbedby(src)
			return TRUE
		stop_pulling()

	// SEND_SIGNAL(src, COMSIG_ATOM_START_PULL, AM, state, force)

	if(AM.pulledby)
		log_combat(AM, AM.pulledby, "pulled from", src)
		AM.pulledby.stop_pulling() //an object can't be pulled by two mobs at once.
	pulling = AM
	AM.set_pulledby(src)
	setGrabState(state)
	if(ismob(AM))
		var/mob/M = AM
		log_combat(src, M, "grabbed", addition="passive grab")
		if(!supress_message)
			M.visible_message("<span class='warning'>[src] grabs [M] passively.</span>", \
				"<span class='danger'>[src] grabs you passively.</span>")
	return TRUE

/atom/movable/proc/stop_pulling()
	if(!pulling)
		return
	pulling.set_pulledby(null)
	var/mob/living/ex_pulled = pulling
	setGrabState(GRAB_PASSIVE)
	pulling = null
	if(isliving(ex_pulled))
		var/mob/living/L = ex_pulled
		L.update_mobility()// mob gets up if it was lyng down in a chokehold

///Reports the event of the change in value of the pulledby variable.
/atom/movable/proc/set_pulledby(new_pulledby)
	if(new_pulledby == pulledby)
		return FALSE //null signals there was a change, be sure to return FALSE if none happened here.
	. = pulledby
	pulledby = new_pulledby

/atom/movable/proc/Move_Pulled(atom/A)
	if(!pulling)
		return FALSE
	if(pulling.anchored || pulling.move_resist > move_force || !pulling.Adjacent(src))
		stop_pulling()
		return FALSE
	if(isliving(pulling))
		var/mob/living/L = pulling
		if(L.buckled && L.buckled.buckle_prevents_pull) //if they're buckled to something that disallows pulling, prevent it
			stop_pulling()
			return FALSE
	if(A == loc && pulling.density)
		return FALSE
	var/move_dir = get_dir(pulling.loc, A)
	if(!Process_Spacemove(move_dir))
		return FALSE
	pulling.Move(get_step(pulling.loc, move_dir), move_dir, glide_size)
	return TRUE

/**
 * Recursively set glide size for atom's pulled things
 */
/atom/movable/proc/recursive_pulled_glidesize_update()
	var/list/ran = list()
	var/atom/movable/updating = pulling
	while(updating)
		if(ran[updating])
			return
		updating.set_glide_size(glide_size, FALSE)
		ran[updating] = TRUE
		updating = updating.pulling

/atom/movable/proc/check_pulling()
	if(pulling)
		var/atom/movable/pullee = pulling
		if(pullee && get_dist(src, pullee) > 1)
			stop_pulling()
			return
		if(!isturf(loc))
			stop_pulling()
			return
		if(pullee && !isturf(pullee.loc) && pullee.loc != loc) //to be removed once all code that changes an object's loc uses forceMove().
			log_game("DEBUG:[src]'s pull on [pullee] wasn't broken despite [pullee] being in [pullee.loc]. Pull stopped manually.")
			stop_pulling()
			return
		if(pulling.anchored || pulling.move_resist > move_force)
			stop_pulling()
			return
	if(pulledby && moving_diagonally != FIRST_DIAG_STEP && get_dist(src, pulledby) > 1)		//separated from our puller and not in the middle of a diagonal move.
		pulledby.stop_pulling()

/atom/movable/proc/set_glide_size(target = 8)
#ifdef SMOOTH_MOVEMENT
	SEND_SIGNAL(src, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE, target)
	glide_size = target

	for(var/mob/buckled_mob as anything in buckled_mobs)
		buckled_mob.set_glide_size(target)
#else
	return
#endif

///Sets the anchored var and returns if it was sucessfully changed or not.
/atom/movable/proc/set_anchored(anchorvalue)
	SHOULD_CALL_PARENT(TRUE)
	if(anchored == anchorvalue)
		return
	. = anchored
	anchored = anchorvalue
	SEND_SIGNAL(src, COMSIG_OBJ_SETANCHORED, anchorvalue)
	// SEND_SIGNAL(src, COMSIG_MOVABLE_SET_ANCHORED, anchorvalue)

/atom/movable/proc/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	set waitfor = FALSE
	var/hitpush = TRUE
	var/impact_signal = SEND_SIGNAL(src, COMSIG_MOVABLE_IMPACT, hit_atom, throwingdatum)
	if(impact_signal & COMPONENT_MOVABLE_IMPACT_FLIP_HITPUSH)
		hitpush = FALSE // hacky, tie this to something else or a proper workaround later

	if(!(impact_signal && (impact_signal & COMPONENT_MOVABLE_IMPACT_NEVERMIND))) // in case a signal interceptor broke or deleted the thing before we could process our hit
		return hit_atom.hitby(src, throwingdatum=throwingdatum, hitpush=hitpush)

/atom/movable/hitby(atom/movable/hitting_atom, skipcatch, hitpush = TRUE, blocked, datum/thrownthing/throwingdatum)
	if(!anchored && hitpush && (!throwingdatum || (throwingdatum.force >= (move_resist * MOVE_FORCE_PUSH_RATIO))))
		step(src, hitting_atom.dir)
	return ..()

/atom/movable/proc/safe_throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE)
	if((force < (move_resist * MOVE_FORCE_THROW_RATIO)) || (move_resist == INFINITY))
		return
	return throw_at(target, range, speed, thrower, spin, diagonals_first, callback, force, gentle)

///If this returns FALSE then callback will not be called.
/atom/movable/proc/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE, quickstart = TRUE)
	. = FALSE

	if(QDELETED(src))
		CRASH("Qdeleted thing being thrown around.")

	if (!target || speed <= 0)
		return

	if(SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_THROW, args) & COMPONENT_CANCEL_THROW)
		return

	if (pulledby)
		pulledby.stop_pulling()

	//They are moving! Wouldn't it be cool if we calculated their momentum and added it to the throw?
	if (thrower && thrower.last_move && thrower.client && thrower.client.move_delay >= world.time + world.tick_lag*2)
		var/user_momentum = thrower.movement_delay() //cached_multiplicative_slowdown
		if (!user_momentum) //no movement_delay, this means they move once per byond tick, lets calculate from that instead.
			user_momentum = world.tick_lag

		user_momentum = 1 / user_momentum // convert from ds to the tiles per ds that throw_at uses.

		if (get_dir(thrower, target) & last_move)
			user_momentum = user_momentum //basically a noop, but needed
		else if (get_dir(target, thrower) & last_move)
			user_momentum = -user_momentum //we are moving away from the target, lets slowdown the throw accordingly
		else
			user_momentum = 0


		if (user_momentum)
			//first lets add that momentum to range.
			range *= (user_momentum / speed) + 1
			//then lets add it to speed
			speed += user_momentum
			if (speed <= 0)
				return//no throw speed, the user was moving too fast.

	. = TRUE // No failure conditions past this point.

	var/target_zone
	if(QDELETED(thrower))
		thrower = null //Let's not pass a qdeleting reference if any.
	else
		target_zone = thrower.zone_selected

	var/datum/thrownthing/TT = new(src, target, get_dir(src, target), range, speed, thrower, diagonals_first, force, gentle, callback, target_zone)

	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)
	var/dx = (target.x > src.x) ? EAST : WEST
	var/dy = (target.y > src.y) ? NORTH : SOUTH

	if (dist_x == dist_y)
		TT.pure_diagonal = 1

	else if(dist_x <= dist_y)
		var/olddist_x = dist_x
		var/olddx = dx
		dist_x = dist_y
		dist_y = olddist_x
		dx = dy
		dy = olddx
	TT.dist_x = dist_x
	TT.dist_y = dist_y
	TT.dx = dx
	TT.dy = dy
	TT.diagonal_error = dist_x/2 - dist_y
	TT.start_time = world.time

	if(pulledby)
		pulledby.stop_pulling()

	throwing = TT
	if(spin)
		SpinAnimation(5, 1)

	SEND_SIGNAL(src, COMSIG_MOVABLE_POST_THROW, TT, spin)
	SSthrowing.processing[src] = TT
	if (SSthrowing.state == SS_PAUSED && length(SSthrowing.currentrun))
		SSthrowing.currentrun[src] = TT
	if (quickstart)
		TT.tick()

/atom/movable/proc/force_pushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/proc/force_push(atom/movable/AM, force = move_force, direction, silent = FALSE)
	. = AM.force_pushed(src, force, direction)
	if(!silent && .)
		visible_message("<span class='warning'>[src] forcefully pushes against [AM]!</span>", "<span class='warning'>You forcefully push against [AM]!</span>")

/atom/movable/proc/move_crush(atom/movable/AM, force = move_force, direction, silent = FALSE)
	. = AM.move_crushed(src, force, direction)
	if(!silent && .)
		visible_message("<span class='danger'>[src] crushes past [AM]!</span>", "<span class='danger'>You crush [AM]!</span>")

/atom/movable/proc/move_crushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(mover in buckled_mobs)
		return TRUE

/// Returns true or false to allow src to move through the blocker, mover has final say
/atom/movable/proc/CanPassThrough(atom/blocker, turf/target, blocker_opinion)
	SHOULD_CALL_PARENT(TRUE)
	return blocker_opinion

/// called when this atom is removed from a storage item, which is passed on as S. The loc variable is already set to the new destination before this is called.
/atom/movable/proc/on_exit_storage(datum/component/storage/concrete/S) // rename S to master_storage
	// SEND_SIGNAL(src, COMSIG_STORAGE_EXITED, master_storage)

/// called when this atom is added into a storage item, which is passed on as S. The loc variable is already set to the storage item.
/atom/movable/proc/on_enter_storage(datum/component/storage/concrete/S)
	// SEND_SIGNAL(src, COMSIG_STORAGE_ENTERED, master_storage)

/atom/movable/proc/get_spacemove_backup()
	var/atom/movable/dense_object_backup
	for(var/A in orange(1, get_turf(src)))
		if(isarea(A))
			continue
		else if(isturf(A))
			var/turf/turf = A
			if(!turf.density)
				continue
			return turf
		else
			var/atom/movable/AM = A
			if(!AM.CanPass(src) || AM.density)
				if(AM.anchored)
					return AM
				dense_object_backup = AM
				break
	. = dense_object_backup

//called when a mob resists while inside a container that is itself inside something.
/atom/movable/proc/relay_container_resist(mob/living/user, obj/O)
	return


/atom/movable/proc/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && (visual_effect_icon || used_item))
		do_item_attack_animation(A, visual_effect_icon, used_item)

	if(A == src)
		return //don't do an animation if attacking self
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/turn_dir = 1

	var/direction = get_dir(src, A)
	if(direction & NORTH)
		pixel_y_diff = 8
		turn_dir = prob(50) ? -1 : 1
	else if(direction & SOUTH)
		pixel_y_diff = -8
		turn_dir = prob(50) ? -1 : 1

	if(direction & EAST)
		pixel_x_diff = 8
	else if(direction & WEST)
		pixel_x_diff = -8
		turn_dir = -1

	var/matrix/initial_transform = matrix(transform)
	var/matrix/rotated_transform = transform.Turn(15 * turn_dir)
	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, transform=rotated_transform, time = 1, easing=BACK_EASING|EASE_IN)
	animate(pixel_x = pixel_x - pixel_x_diff, pixel_y = pixel_y - pixel_y_diff, transform=initial_transform, time = 2, easing=SINE_EASING)

/atom/movable/proc/do_item_attack_animation(atom/A, visual_effect_icon, obj/item/used_item)
	var/image/I
	if(visual_effect_icon)
		I = image('icons/effects/effects.dmi', A, visual_effect_icon, A.layer + 0.1)
	else if(used_item)
		I = image(icon = used_item, loc = A, layer = A.layer + 0.1)
		I.plane = GAME_PLANE

		// Scale the icon.
		I.transform *= 0.4
		// The icon should not rotate.
		I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

		// Set the direction of the icon animation.
		var/direction = get_dir(src, A)
		if(direction & NORTH)
			I.pixel_y = -12
		else if(direction & SOUTH)
			I.pixel_y = 12

		if(direction & EAST)
			I.pixel_x = -14
		else if(direction & WEST)
			I.pixel_x = 14

		if(!direction) // Attacked self?!
			I.pixel_z = 16

	if(!I)
		return

	flick_overlay(I, GLOB.clients, 10)

	// And animate the attack!
	animate(I, alpha = 175, transform = matrix() * 0.75, pixel_x = 0, pixel_y = 0, pixel_z = 0, time = 3)
	animate(time = 1)
	animate(alpha = 0, time = 3, easing = CIRCULAR_EASING|EASE_OUT)

/// Common proc used by painting tools like spraycans and palettes that can access the entire 24 bits color space.
/obj/item/proc/pick_painting_tool_color(mob/user, default_color)
	var/chosen_color = input(user,"Pick new color", "[src]", default_color) as color|null
	if(!chosen_color || QDELETED(src) || IS_DEAD_OR_INCAP(user) || !user.is_holding(src))
		return
	set_painting_tool_color(chosen_color)

/obj/item/proc/set_painting_tool_color(chosen_color)
	SEND_SIGNAL(src, COMSIG_PAINTING_TOOL_SET_COLOR, chosen_color)

/**
 * Returns null if this object cannot be used to interact with physical writing mediums such as paper.
 * Returns a list of key attributes for this object interacting with paper otherwise.
 */
/obj/item/proc/get_writing_implement_details()
	return null

/atom/movable/vv_get_dropdown()
	. = ..()
	. += "<option value='?_src_=holder;[HrefToken()];adminplayerobservefollow=[REF(src)]'>Follow</option>"
	. += "<option value='?_src_=holder;[HrefToken()];admingetmovable=[REF(src)]'>Get</option>"

/atom/movable/proc/ex_check(ex_id)
	if(!ex_id)
		return TRUE
	LAZYINITLIST(acted_explosions)
	if(ex_id in acted_explosions)
		return FALSE
	acted_explosions += ex_id
	return TRUE

//TODO: Better floating
/atom/movable/proc/float(on, throw_override)
	if(throwing && !throw_override)
		return
	if(on && !(movement_type & FLOATING))
		animate(src, pixel_z = 2, time = 10, loop = -1, flags = ANIMATION_RELATIVE)
		animate(pixel_z = -4, time = 10, loop = -1, flags = ANIMATION_RELATIVE)
		setMovetype(movement_type | FLOATING)
	else if (!on && (movement_type & FLOATING))
		animate(src, pixel_z = initial(pixel_y), time = 10)
		setMovetype(movement_type & ~FLOATING)
	floating_need_update = FALSE // assume it's done

/* 	Language procs
*	Unless you are doing something very specific, these are the ones you want to use.
*/

/// Gets or creates the relevant language holder. For mindless atoms, gets the local one. For atom with mind, gets the mind one.
/atom/movable/proc/get_language_holder(get_minds = TRUE)
	RETURN_TYPE(/datum/language_holder)
	if(QDELING(src))
		CRASH("get_language_holder() called on a QDELing atom, \
			this will try to re-instantiate the language holder that's about to be deleted, which is bad.")

	if(!language_holder)
		language_holder = new initial_language_holder(src)
	return language_holder

/// Grants the supplied language and sets omnitongue true.
/atom/movable/proc/grant_language(language, language_flags = ALL, source = LANGUAGE_ATOM)
	return get_language_holder().grant_language(language, language_flags, source)

/// Grants every language.
/atom/movable/proc/grant_all_languages(language_flags = ALL, grant_omnitongue = TRUE, source = LANGUAGE_MIND)
	return get_language_holder().grant_all_languages(language_flags, grant_omnitongue, source)

/// Removes a single language.
/atom/movable/proc/remove_language(language, language_flags = ALL, source = LANGUAGE_ALL)
	return get_language_holder().remove_language(language, language_flags, source)

/// Removes every language and sets omnitongue false.
/atom/movable/proc/remove_all_languages(source = LANGUAGE_ALL, remove_omnitongue = FALSE)
	return get_language_holder().remove_all_languages(source, remove_omnitongue)

/// Adds a language to the blocked language list. Use this over remove_language in cases where you will give languages back later.
/atom/movable/proc/add_blocked_language(language, source = LANGUAGE_ATOM)
	return get_language_holder().add_blocked_language(language, source)

/// Removes a language from the blocked language list.
/atom/movable/proc/remove_blocked_language(language, source = LANGUAGE_ATOM)
	return get_language_holder().remove_blocked_language(language, source)

/// Checks if atom has the language. If spoken is true, only checks if atom can speak the language.
/atom/movable/proc/has_language(language, flags_to_check)
	return get_language_holder().has_language(language, flags_to_check)

/// Checks if atom can speak the language.
/atom/movable/proc/can_speak_language(language)
	return get_language_holder().can_speak_language(language)

/// Returns the result of tongue specific limitations on spoken languages.
/atom/movable/proc/could_speak_language(language)
	return TRUE

/// Returns selected language, if it can be spoken, or finds, sets and returns a new selected language if possible.
/atom/movable/proc/get_selected_language()
	return get_language_holder().get_selected_language()

/// Gets a random understood language, useful for hallucinations and such.
/atom/movable/proc/get_random_understood_language()
	return get_language_holder().get_random_understood_language()

/// Gets a random spoken language, useful for forced speech and such.
/atom/movable/proc/get_random_spoken_language()
	return get_language_holder().get_random_spoken_language()

/// Copies all languages into the supplied atom/language holder. Source should be overridden when you
/// do not want the language overwritten by later atom updates or want to avoid blocked languages.
/atom/movable/proc/copy_languages(datum/language_holder/from_holder, source_override)
	if(ismovable(from_holder))
		var/atom/movable/thing = from_holder
		from_holder = thing.get_language_holder()

	return get_language_holder().copy_languages(from_holder, source_override)

/// Sets the passed path as the active language
/// Returns the currently selected language if successful, if the language was not valid, returns null
/atom/movable/proc/set_active_language(language_path)
	var/datum/language_holder/our_holder = get_language_holder()
	our_holder.selected_language = language_path

	return our_holder.get_selected_language() // verifies its validity, returns it if successful.

/// Sets the vocal bark for the atom, using the bark's ID
/atom/movable/proc/set_bark(id)
	if(!id)
		return FALSE
	var/datum/bark/B = GLOB.bark_list[id]
	if(!B)
		return FALSE
	vocal_bark = sound(initial(B.soundpath))
	vocal_bark_id = id
	return vocal_bark

/* End language procs */


/atom/movable/proc/ConveyorMove(movedir)
	set waitfor = FALSE
	if(!anchored && has_gravity())
		step(src, movedir)

//Returns an atom's power cell, if it has one. Overload for individual items.
/atom/movable/proc/get_cell()
	return

/atom/movable/proc/can_be_pulled(user, grab_state, force)
	if(src == user || !isturf(loc))
		return FALSE
	if(anchored || throwing)
		return FALSE
	if(force < (move_resist * MOVE_FORCE_PULL_RATIO))
		return FALSE
	return TRUE

/**
 * Updates the grab state of the movable
 *
 * This exists to act as a hook for behaviour
 */
/atom/movable/proc/setGrabState(newstate)
	if(newstate == grab_state)
		return
	// SEND_SIGNAL(src, COMSIG_MOVABLE_SET_GRAB_STATE, newstate)
	. = grab_state
	grab_state = newstate
	// switch(grab_state) // Current state.
	// 	if(GRAB_PASSIVE)
	// 		REMOVE_TRAIT(pulling, TRAIT_IMMOBILIZED, CHOKEHOLD_TRAIT)
	// 		REMOVE_TRAIT(pulling, TRAIT_HANDS_BLOCKED, CHOKEHOLD_TRAIT)
	// 		if(. >= GRAB_NECK) // Previous state was a a neck-grab or higher.
	// 			REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
	// 	if(GRAB_AGGRESSIVE)
	// 		if(. >= GRAB_NECK) // Grab got downgraded.
	// 			REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
	// 		else // Grab got upgraded from a passive one.
	// 			ADD_TRAIT(pulling, TRAIT_IMMOBILIZED, CHOKEHOLD_TRAIT)
	// 			ADD_TRAIT(pulling, TRAIT_HANDS_BLOCKED, CHOKEHOLD_TRAIT)
	// 	if(GRAB_NECK, GRAB_KILL)
	// 		if(. <= GRAB_AGGRESSIVE)
	// 			ADD_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)

/obj/item/proc/do_pickup_animation(atom/target)
	set waitfor = FALSE
	if(!istype(loc, /turf))
		return
	var/image/I = image(icon = src, loc = loc, layer = layer + 0.1)
	I.plane = GAME_PLANE
	I.transform *= 0.75
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	var/turf/T = get_turf(src)
	var/direction
	var/to_x = initial(target.pixel_x)
	var/to_y = initial(target.pixel_y)

	if(!QDELETED(T) && !QDELETED(target))
		direction = get_dir(T, target)
	if(direction & NORTH)
		to_y += 32
	else if(direction & SOUTH)
		to_y -= 32
	if(direction & EAST)
		to_x += 32
	else if(direction & WEST)
		to_x -= 32
	if(!direction)
		to_y += 16
	flick_overlay(I, GLOB.clients, 6)
	var/matrix/M = new
	M.Turn(pick(-30, 30))
	animate(I, alpha = 175, pixel_x = to_x, pixel_y = to_y, time = 3, transform = M, easing = CUBIC_EASING)
	sleep(1)
	animate(I, alpha = 0, transform = matrix(), time = 1, flags = ANIMATION_PARALLEL)

/**
 * Called when a movable changes z-levels.
 *
 * Arguments:
 * * old_turf - The previous turf they were on before.
 * * new_turf - The turf they have now entered.
 * * same_z_layer - If their old and new z levels are on the same level of plane offsets or not
 * * notify_contents - Whether or not to notify the movable's contents that their z-level has changed. NOTE, IF YOU SET THIS, YOU NEED TO MANUALLY SET PLANE OF THE CONTENTS LATER
 */
/atom/movable/proc/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents = TRUE)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, old_turf, new_turf, same_z_layer)

	// If our turfs are on different z "layers", recalc our planes
	if(!same_z_layer && !QDELETED(src))
		SET_PLANE(src, PLANE_TO_TRUE(src.plane), new_turf)
		// a TON of overlays use planes, and thus require offsets
		// so we do this. sucks to suck
		update_appearance()

		if(update_on_z)
			// I so much wish this could be somewhere else. alas, no.
			for(var/image/update in update_on_z)
				SET_PLANE(update, PLANE_TO_TRUE(update.plane), new_turf)
		if(update_overlays_on_z)
			// This EVEN more so
			cut_overlay(update_overlays_on_z)
			// This even more so
			for(var/mutable_appearance/update in update_overlays_on_z)
				SET_PLANE(update, PLANE_TO_TRUE(update.plane), new_turf)
			add_overlay(update_overlays_on_z)

	if(!notify_contents)
		return

	for (var/atom/movable/content as anything in src) // Notify contents of Z-transition.
		content.on_changed_z_level(old_turf, new_turf, same_z_layer)

/**
* A wrapper for setDir that should only be able to fail by living mobs.
*
* Called from [/atom/movable/proc/keyLoop], this exists to be overwritten by living mobs with a check to see if we're actually alive enough to change directions
*/
/atom/movable/proc/keybind_face_direction(direction)
	setDir(direction)
