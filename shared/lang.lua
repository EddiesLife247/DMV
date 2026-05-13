--[[
    DMV – lang.lua
    All player-facing strings in one place.
    Edit here to translate or customise any message.
--]]

Lang = {}

-- ─────────────────────────────────────────────
--  GENERAL
-- ─────────────────────────────────────────────
Lang.already_in_test        = "You are already in a test!"
Lang.player_data_not_found  = "Player data not found."

-- ─────────────────────────────────────────────
--  LICENCE LABELS  (used in notifications + dialogs)
-- ─────────────────────────────────────────────
Lang.licenceLabels = {
    car        = "Car",
    bus_hgv    = "Bus / HGV",
    plane      = "Pilot (Fixed Wing)",
    helicopter = "Helicopter",
}

-- ─────────────────────────────────────────────
--  LICENCE MENU
-- ─────────────────────────────────────────────
Lang.menu_already_holds         = "✅ You already hold this licence"
Lang.menu_take_practical        = "🚗 Take Practical Test"
Lang.menu_practical_theory_done = "Your theory is on file – proceed to the practical"
Lang.menu_practical_no_theory   = "Theory not required on this server"
Lang.menu_practical_cost        = " – Cost: $%d"
Lang.menu_practical_free        = " – Free"
Lang.menu_theory_status_title   = "📋 Theory Status"
Lang.menu_theory_status_desc    = "✅ Theory passed – practical test available"
Lang.menu_take_theory           = "📝 Take Theory Test"
Lang.menu_theory_desc           = "15 questions – pass mark: %d/15"
Lang.menu_info_title            = "ℹ️  Licence Information"
Lang.menu_info_desc             = "Learn about the %s licence requirements"
Lang.menu_title                 = "DMV – %s Licence"

-- ─────────────────────────────────────────────
--  ELIGIBILITY – WARRANT & WEATHER
-- ─────────────────────────────────────────────
Lang.eligibility_warrant     = "You have an active warrant. You cannot sit a licence test until it is resolved."
Lang.weather_bad_header      = "❌ Test Unavailable – Poor Weather"
Lang.weather_bad_body        = "Current weather conditions (%s) are not suitable for a %s test. Please return when conditions improve."

-- ─────────────────────────────────────────────
--  LICENCE INFORMATION DIALOG
-- ─────────────────────────────────────────────
Lang.licenceInfo = {
    car        = "The Car licence allows you to operate standard passenger vehicles. You must pass a 15-question theory test (pass mark 12/15) then complete a practical driving route within the speed limit.",
    bus_hgv    = "The Bus/HGV licence allows you to operate heavy goods vehicles and buses. Theory test required (12/15) followed by a multi-stop driving practical.",
    plane      = "The Pilot licence allows you to fly fixed-wing aircraft. Theory test (12/15) then an airfield navigation practical.",
    helicopter = "The Helicopter licence permits rotary-wing operations. Theory test (12/15) then a multi-point hover and navigation practical.",
}
Lang.licence_info_header        = "Licence Information"
Lang.licence_info_none          = "No information available."

-- ─────────────────────────────────────────────
--  CHARGING
-- ─────────────────────────────────────────────
Lang.charge_insufficient        = "You need $%d cash to pay for the %s test."

-- ─────────────────────────────────────────────
--  ELIGIBILITY
-- ─────────────────────────────────────────────
Lang.eligibility_header         = "❌ Test Not Available"
Lang.eligibility_fallback       = "You are not eligible to take this test."
Lang.eligibility_suspended      = "Your %s licence is suspended for %d more minute(s).\nReason: %s"
Lang.eligibility_warrant        = "You have an active warrant. You cannot sit a licence test until it is resolved."

-- ─────────────────────────────────────────────
--  THEORY TEST
-- ─────────────────────────────────────────────
Lang.theory_starting            = "Theory test starting – %d questions. Good luck!"
Lang.theory_cancelled           = "You cancelled the theory test. You have failed."
Lang.theory_result_header       = "DMV Theory Test Result"
Lang.theory_result_passed       = "✅ PASSED"
Lang.theory_result_failed       = "❌ FAILED"
Lang.theory_result_body         = "Theory Test Complete!\nScore: %d / %d\nResult: %s"
Lang.theory_result_need_more    = "\n\nYou needed %d to pass. Please study and try again."
Lang.theory_pass_notify         = "Theory test passed! You may now take the practical test."
Lang.theory_fail_notify         = "Theory test failed. Score: %d/%d. Try again later."
Lang.theory_question_title      = "Question %d / %d"
Lang.theory_question_placeholder = "Select your answer…"

-- ─────────────────────────────────────────────
--  PRACTICAL TEST – GENERAL
-- ─────────────────────────────────────────────
Lang.practical_starting         = "🚗 Practical test starting! A test vehicle will be spawned."
Lang.practical_spawn_fail       = "Failed to spawn test vehicle. Please speak to the examiner again."
Lang.practical_vehicle_fail     = "Test vehicle failed to appear. Test cancelled."
Lang.practical_seatbelt_grace   = "⚠ You have 30 seconds to put your seatbelt on!"
Lang.practical_complete_pass    = "🎉 Test complete! Return to the examiner to collect your licence."
Lang.practical_complete_fail    = "Test complete. Return to the examiner for your result."

-- ─────────────────────────────────────────────
--  PRACTICAL TEST – FAIL REASONS
-- ─────────────────────────────────────────────
Lang.fail_left_vehicle          = "You left the test vehicle."
Lang.fail_seatbelt              = "You removed your seatbelt during the test."
Lang.fail_speed                 = "You exceeded the speed limit of %d mph (you were doing %.0f mph)."
Lang.fail_timeout               = "You ran out of time to reach: %s"
Lang.fail_no_stop               = "You did not come to a complete stop, turn off the engine, and exit in time."
Lang.fail_exit_early            = "You exited the vehicle before coming to a complete stop with the engine off."
Lang.fail_conditions            = "Waypoint conditions not met."

Lang.warn_speed    = "⚠ Speed warning! Limit: %d mph, you were doing %.0f mph. Warnings remaining: %d"
Lang.warn_seatbelt = "⚠ Seatbelt warning! Put it on. Warnings remaining: %d"

-- ─────────────────────────────────────────────
--  PRACTICAL TEST – HUD
-- ─────────────────────────────────────────────
Lang.hud_waypoint               = "🗺  %s"
Lang.hud_timer                  = "⏱  Time remaining: %ds"
Lang.hud_condition_warning      = "⚠  %s"
Lang.hud_final_title            = "🅿  %s"
Lang.hud_final_timer            = "⏱  %ds remaining"
Lang.hud_stop_needed            = "🚫  Bring the vehicle to a stop"
Lang.hud_stop_done              = "✅  Vehicle stopped"
Lang.hud_engine_needed          = "🚫  Turn off the engine"
Lang.hud_engine_done            = "✅  Engine off"
Lang.hud_exit_needed            = "🚫  Exit the vehicle to complete"
Lang.hud_speed_over             = "⚠ OVER LIMIT: %.0f / %d MPH"

-- ─────────────────────────────────────────────
--  PRACTICAL TEST – CHECKPOINTS
-- ─────────────────────────────────────────────
Lang.checkpoint_reached         = "✅ Checkpoint %d reached!"
Lang.final_stop_instruction     = "🅿  Come to a complete stop, turn off the engine, then exit the vehicle."

-- ─────────────────────────────────────────────
--  EXAMINER RESULT DIALOGS
-- ─────────────────────────────────────────────
Lang.result_pass_header         = "🎉 Practical Test – PASSED"
Lang.result_pass_body           = "Congratulations! The examiner is pleased to inform you that you have passed your %s practical test.\n\nYour licence has been issued. Drive safely!"
Lang.result_fail_header         = "❌ Practical Test – FAILED"
Lang.result_fail_body           = "The examiner regrets to inform you that you did not pass your %s practical test.\n\nReason: %s\n\nYou will need to retake both the theory and practical tests."
Lang.result_fail_reason_default = "General failure"

-- ─────────────────────────────────────────────
--  LICENCE GRANTED
-- ─────────────────────────────────────────────
Lang.licence_granted            = "🎉 Congratulations! You have been awarded your %s licence!"

-- ─────────────────────────────────────────────
--  SUSPENSION / UNSUSPENSION  (shown to the player)
-- ─────────────────────────────────────────────
Lang.suspended_notify           = "Your %s licence has been suspended for %d minute(s).\nReason: %s"
Lang.unsuspended_notify         = "Your %s licence suspension has been lifted."

-- ─────────────────────────────────────────────
--  ADMIN / POLICE COMMAND FEEDBACK  (shown to the officer)
-- ─────────────────────────────────────────────
Lang.admin_no_permission        = "You do not have permission to use this command."
Lang.admin_granted_theory       = "An admin has granted you a theory pass for: %s"
Lang.admin_grant_confirm        = "Granted %s %s to player %d"
Lang.suspend_confirm            = "Suspended %s licence for player %d for %d minute(s)."
Lang.unsuspend_confirm          = "Suspension lifted for player %d (%s licence)."
Lang.cmd_invalid_type           = "Invalid licence type. Use: car, bus_hgv, plane, helicopter"
Lang.cmd_invalid_stage          = "Invalid stage. Use: theory, practical, both"
Lang.cmd_player_not_found       = "Player %d not found or not loaded."

-- ─────────────────────────────────────────────
--  CONDITION CHECKER MESSAGES
-- ─────────────────────────────────────────────
Lang.cond_min_height            = "You must be at least %.0f ft altitude at this checkpoint."
Lang.cond_max_height            = "You must be below %.0f ft altitude at this checkpoint."
Lang.cond_min_speed             = "You must be travelling at least %d mph at this checkpoint."
Lang.cond_max_speed             = "You must be doing no more than %d mph at this checkpoint (you were doing %.0f mph)."
Lang.cond_must_land             = "You must be fully landed and stationary at this checkpoint."
Lang.cond_must_airborne         = "You must be airborne at this checkpoint."
Lang.cond_heading               = "Incorrect heading at this checkpoint. Required: %d° (±%d°)."