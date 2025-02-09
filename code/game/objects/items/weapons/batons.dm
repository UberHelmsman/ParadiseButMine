/**
  * # Police Baton
  *
  * Knocks down the hit mob when not on harm intent and when [/obj/item/melee/classic_baton/on] is TRUE
  *
  * A non-lethal attack has a cooldown to avoid spamming
  */
/obj/item/melee/classic_baton
	name = "police baton"
	desc = "A wooden truncheon for beating criminal scum."
	icon_state = "baton"
	item_state = "classic_baton"
	slot_flags = ITEM_SLOT_BELT
	force = 12 //9 hit crit
	w_class = WEIGHT_CLASS_NORMAL
	// Settings
	/// Whether the baton can stun silicon mobs
	var/affect_silicon = FALSE
	/// The stun time (in seconds) for non-silicons
	var/stun_time = 2 SECONDS
	/// Stamina damage
	var/staminaforce = 15
	/// The stun time (in seconds) for silicons
	var/stun_time_silicon = 10 SECONDS
	/// Cooldown in deciseconds between two knockdowns
	var/cooldown = 2 SECONDS
	/// Sound to play when knocking someone down
	var/stun_sound = 'sound/effects/woodhit.ogg'
	// Variables
	/// Whether the baton is on cooldown
	var/on_cooldown = FALSE
	/// Whether the baton is toggled on (to allow attacking)
	var/on = TRUE

/obj/item/melee/classic_baton/attack(mob/living/target, mob/living/user)
	if(!on)
		return ..()

	add_fingerprint(user)
	if((CLUMSY in user.mutations) && prob(50))
		user.visible_message("<span class='danger'>[user] accidentally clubs [user.p_them()]self with [src]!</span>", \
							 "<span class='userdanger'>You accidentally club yourself with [src]!</span>")
		user.Weaken(stun_time)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(force * 2, BRUTE, BODY_ZONE_HEAD)
		else
			user.take_organ_damage(force * 2)
		return

	if(user.a_intent == INTENT_HARM)
		return ..()
	if(on_cooldown)
		return
	if(issilicon(target) && !affect_silicon)
		return ..()
	else
		stun(target, user)

/**
  * Called when a target is about to be hit non-lethally.
  *
  * Arguments:
  * * target - The mob about to be hit
  * * user - The attacking user
  */
/obj/item/melee/classic_baton/proc/stun(mob/living/target, mob/living/user)
	if(isbot(target))
		user.visible_message(span_danger("[user] pulses [target]'s sensors with [src]!"),\
							span_danger("You pulse [target]'s sensors with [src]!"))
		var/mob/living/simple_animal/bot/bot = target
		bot.disable(stun_time_silicon)

	else if(issilicon(target))
		user.visible_message(span_danger("[user] pulses [target]'s sensors with [src]!"),\
							 span_danger("You pulse [target]'s sensors with [src]!"))
		on_silicon_stun(target, user)

	else
		// Check for shield/countering
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			if(H.check_shields(src, 0, "[user]'s [name]", MELEE_ATTACK))
				return FALSE
			if(check_martial_counter(H, user))
				return FALSE
		user.visible_message(span_danger("[user] knocks down [target] with [src]!"),\
							 span_danger("You knock down [target] with [src]!"))
		on_non_silicon_stun(target, user)
	// Visuals and sound
	user.do_attack_animation(target)
	playsound(target, stun_sound, 75, TRUE, -1)
	add_attack_logs(user, target, "Stunned with [src]")
	// Hit 'em
	target.LAssailant = iscarbon(user) ? user : null
	target.adjustStaminaLoss(staminaforce)
	if(prob(75))
		target.Weaken(stun_time)
	else
		target.Weaken(stun_time + 2 SECONDS)
	on_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(cooldown_finished)), cooldown)
	return TRUE

/**
  * Called when a silicon has been stunned.
  *
  * Arguments:
  * * target - The hit mob
  * * user - The attacking user
  */
/obj/item/melee/classic_baton/proc/on_silicon_stun(mob/living/silicon/target, mob/living/user)
	target.flash_eyes(3, affect_silicon = TRUE)	// Yeah, it's just a "bash".
	target.Weaken(stun_time_silicon)

/**
  * Called when a non-silicon has been stunned.
  *
  * Arguments:
  * * target - The hit mob
  * * user - The attacking user
  */
/obj/item/melee/classic_baton/proc/on_non_silicon_stun(mob/living/target, mob/living/user)
	return

/**
  * Called some time after a non-lethal attack
  */
/obj/item/melee/classic_baton/proc/cooldown_finished()
	on_cooldown = FALSE

/**
  * # Fancy Cane
  */
/obj/item/melee/classic_baton/ntcane
	name = "fancy cane"
	desc = "A cane with special engraving on it. It seems well suited for fending off assailants..."
	icon_state = "cane_nt"
	item_state = "cane_nt"
	needs_permit = FALSE

/obj/item/melee/classic_baton/ntcane/is_crutch()
	return 2

/**
  * # Telescopic Baton
  */
/obj/item/melee/classic_baton/telescopic
	name = "telescopic baton"
	desc = "A compact yet robust personal defense weapon. Can be concealed when folded."
	item_state = null
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	needs_permit = FALSE
	on = FALSE
	/// Force when concealed
	var/force_off = 0
	/// Force when extended
	var/force_on = 10
	/// Item state when extended
	var/item_state_on = "nullrod"
	/// Icon state when concealed
	var/icon_state_off = "telebaton_0"
	/// Icon state when extended
	var/icon_state_on = "telebaton_1"
	/// Sound to play when concealing or extending
	var/extend_sound = 'sound/weapons/batonextend.ogg'
	/// Attack verbs when concealed (created on Initialize)
	var/static/list/attack_verb_off
	/// Attack verbs when extended (created on Initialize)
	var/static/list/attack_verb_on

/obj/item/melee/classic_baton/telescopic/Initialize(mapload)
	. = ..()
	if(!attack_verb_off)
		attack_verb_off = list("hit", "poked")
		attack_verb_on = list("smacked", "struck", "cracked", "beaten")
	update_icon(UPDATE_ICON_STATE)
	force = force_off
	attack_verb = on ? attack_verb_on : attack_verb_off


/obj/item/melee/classic_baton/telescopic/update_icon_state()
	icon_state = on ? icon_state_on : icon_state_off
	item_state = on ? item_state_on :  null //no sprite for concealment even when in hand


/obj/item/melee/classic_baton/telescopic/attack_self(mob/user)
	on = !on
	update_icon(UPDATE_ICON_STATE)
	if(on)
		to_chat(user, "<span class='warning'>You extend [src].</span>")
		w_class = WEIGHT_CLASS_BULKY //doesnt fit in backpack when its on for balance
		force = force_on //stunbaton damage
		attack_verb = attack_verb_on
	else
		to_chat(user, "<span class='notice'>You collapse [src].</span>")
		slot_flags = ITEM_SLOT_BELT
		w_class = WEIGHT_CLASS_SMALL
		force = force_off //not so robust now
		attack_verb = attack_verb_off
	// Update mob hand visuals
	update_equipped_item()
	playsound(loc, extend_sound, 50, TRUE)
	add_fingerprint(user)

