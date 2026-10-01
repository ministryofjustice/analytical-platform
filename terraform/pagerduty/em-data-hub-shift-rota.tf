locals {
  em_members_by_key = {
    for member in local.users_em :
    member.key => member
  }

  # ---------------------------------------------------------------------------
  # Working patterns currently used by the team
  # ---------------------------------------------------------------------------

  em_working_patterns = {
    full_time = toset([
      "monday_am",
      "monday_pm",
      "tuesday_am",
      "tuesday_pm",
      "wednesday_am",
      "wednesday_pm",
      "thursday_am",
      "thursday_pm",
      "friday_am",
      "friday_pm",
    ])

    mon_thu = toset([
      "monday_am",
      "monday_pm",
      "tuesday_am",
      "tuesday_pm",
      "wednesday_am",
      "wednesday_pm",
      "thursday_am",
      "thursday_pm",
    ])
  }

  # ---------------------------------------------------------------------------
  # Business-hour shift slots
  # ---------------------------------------------------------------------------
  #
  # AM and PM are separate so half-day working patterns can be added later
  # without changing the schedule module.
  #
  # alternate_start_time and alternate_end_time are used for the normal
  # engineer Wednesday rotation when the G6 covers alternating Wednesdays.
  #

  em_business_hour_slots = {
    monday_am = {
      name                 = "Monday AM"
      day                  = "monday"
      rrule_day            = "MO"
      start_time           = "2026-10-05T09:00:00+01:00"
      end_time             = "2026-10-05T13:00:00+01:00"
      alternate_start_time = "2026-10-12T09:00:00+01:00"
      alternate_end_time   = "2026-10-12T13:00:00+01:00"
      rotation_offset      = 0
    }

    monday_pm = {
      name                 = "Monday PM"
      day                  = "monday"
      rrule_day            = "MO"
      start_time           = "2026-10-05T13:00:00+01:00"
      end_time             = "2026-10-05T17:00:00+01:00"
      alternate_start_time = "2026-10-12T13:00:00+01:00"
      alternate_end_time   = "2026-10-12T17:00:00+01:00"
      rotation_offset      = 0
    }

    tuesday_am = {
      name                 = "Tuesday AM"
      day                  = "tuesday"
      rrule_day            = "TU"
      start_time           = "2026-10-06T09:00:00+01:00"
      end_time             = "2026-10-06T13:00:00+01:00"
      alternate_start_time = "2026-10-13T09:00:00+01:00"
      alternate_end_time   = "2026-10-13T13:00:00+01:00"
      rotation_offset      = 1
    }

    tuesday_pm = {
      name                 = "Tuesday PM"
      day                  = "tuesday"
      rrule_day            = "TU"
      start_time           = "2026-10-06T13:00:00+01:00"
      end_time             = "2026-10-06T17:00:00+01:00"
      alternate_start_time = "2026-10-13T13:00:00+01:00"
      alternate_end_time   = "2026-10-13T17:00:00+01:00"
      rotation_offset      = 1
    }

    wednesday_am = {
      name                 = "Wednesday AM"
      day                  = "wednesday"
      rrule_day            = "WE"
      start_time           = "2026-10-07T09:00:00+01:00"
      end_time             = "2026-10-07T13:00:00+01:00"
      alternate_start_time = "2026-10-14T09:00:00+01:00"
      alternate_end_time   = "2026-10-14T13:00:00+01:00"
      rotation_offset      = 2
    }

    wednesday_pm = {
      name                 = "Wednesday PM"
      day                  = "wednesday"
      rrule_day            = "WE"
      start_time           = "2026-10-07T13:00:00+01:00"
      end_time             = "2026-10-07T17:00:00+01:00"
      alternate_start_time = "2026-10-14T13:00:00+01:00"
      alternate_end_time   = "2026-10-14T17:00:00+01:00"
      rotation_offset      = 2
    }

    thursday_am = {
      name                 = "Thursday AM"
      day                  = "thursday"
      rrule_day            = "TH"
      start_time           = "2026-10-08T09:00:00+01:00"
      end_time             = "2026-10-08T13:00:00+01:00"
      alternate_start_time = "2026-10-15T09:00:00+01:00"
      alternate_end_time   = "2026-10-15T13:00:00+01:00"
      rotation_offset      = 3
    }

    thursday_pm = {
      name                 = "Thursday PM"
      day                  = "thursday"
      rrule_day            = "TH"
      start_time           = "2026-10-08T13:00:00+01:00"
      end_time             = "2026-10-08T17:00:00+01:00"
      alternate_start_time = "2026-10-15T13:00:00+01:00"
      alternate_end_time   = "2026-10-15T17:00:00+01:00"
      rotation_offset      = 3
    }

    friday_am = {
      name                 = "Friday AM"
      day                  = "friday"
      rrule_day            = "FR"
      start_time           = "2026-10-09T09:00:00+01:00"
      end_time             = "2026-10-09T13:00:00+01:00"
      alternate_start_time = "2026-10-16T09:00:00+01:00"
      alternate_end_time   = "2026-10-16T13:00:00+01:00"
      rotation_offset      = 4
    }

    friday_pm = {
      name                 = "Friday PM"
      day                  = "friday"
      rrule_day            = "FR"
      start_time           = "2026-10-09T13:00:00+01:00"
      end_time             = "2026-10-09T17:00:00+01:00"
      alternate_start_time = "2026-10-16T13:00:00+01:00"
      alternate_end_time   = "2026-10-16T17:00:00+01:00"
      rotation_offset      = 4
    }
  }

  # ---------------------------------------------------------------------------
  # Primary rota phases
  # ---------------------------------------------------------------------------
  #
  # A new phase is created whenever somebody starts or stops primary cover,
  # returns from planned long-term leave, or begins an absence.
  #

  em_primary_boundaries_raw = concat(
    [local.em_shift_schedule_start],
    flatten([
      for member in local.users_em :
      member.rota.primary.enabled ? compact([
        member.rota.primary.from,
        member.rota.primary.until,
      ]) : []
    ]),
    flatten([
      for member in local.users_em : flatten([
        for absence in member.rota.absences : compact([
          absence.from,
          absence.until,
        ])
      ])
    ])
  )

  em_primary_boundaries = sort(distinct([
    for boundary in local.em_primary_boundaries_raw :
    boundary
    if timecmp(
      boundary,
      local.em_shift_schedule_start
    ) >= 0
  ]))

  em_primary_phases_base = [
    for phase_index, phase_start in local.em_primary_boundaries : {
      index = phase_index
      from  = phase_start

      until = (
        phase_index + 1 < length(local.em_primary_boundaries)
        ? local.em_primary_boundaries[phase_index + 1]
        : null
      )

      active_keys = [
        for member in local.users_em :
        member.key
        if(
          member.rota.primary.enabled
          && timecmp(
            phase_start,
            member.rota.primary.from
          ) >= 0
          && (
            member.rota.primary.until == null
            ? true
            : timecmp(
              phase_start,
              member.rota.primary.until
            ) < 0
          )
          && !anytrue([
            for absence in member.rota.absences :
            timecmp(
              phase_start,
              absence.from
            ) >= 0
            && (
              absence.until == null
              ? true
              : timecmp(
                phase_start,
                absence.until
              ) < 0
            )
          ])
        )
      ]
    }
  ]

  em_primary_phases = [
    for phase in local.em_primary_phases_base :
    merge(
      phase,
      {
        standard_keys = [
          for member_key in phase.active_keys :
          member_key
          if(
            local.em_members_by_key[
              member_key
            ].rota.primary.cadence == "standard"
          )
        ]

        fortnightly_keys = [
          for member_key in phase.active_keys :
          member_key
          if(
            local.em_members_by_key[
              member_key
            ].rota.primary.cadence == "fortnightly"
          )
        ]
      }
    )
  ]

  em_primary_phase_details = [
    for phase in local.em_primary_phases :
    merge(
      phase,
      {
        fortnightly_day = (
          length(phase.fortnightly_keys) == 1
          ? local.em_members_by_key[
            phase.fortnightly_keys[0]
          ].rota.primary.cadence_day
          : null
        )
      }
    )
  ]

  # ---------------------------------------------------------------------------
  # Standard primary rotation
  # ---------------------------------------------------------------------------

  em_standard_event_inputs = flatten([
    for phase in local.em_primary_phase_details : [
      for slot_key, slot in local.em_business_hour_slots : {
        phase_index = phase.index
        phase_from  = phase.from
        phase_until = phase.until

        slot_key   = slot_key
        slot_name  = slot.name
        slot_day   = slot.day
        rrule_day  = slot.rrule_day
        start_time = slot.start_time
        end_time   = slot.end_time

        alternate_start_time = slot.alternate_start_time
        alternate_end_time   = slot.alternate_end_time

        rotation_offset = slot.rotation_offset

        fortnightly_active = (
          phase.fortnightly_day == slot.day
        )

        eligible_keys = [
          for member_key in phase.standard_keys :
          member_key
          if contains(
            local.em_working_patterns[
              local.em_members_by_key[
                member_key
              ].rota.working_pattern
            ],
            slot_key
          )
        ]
      }
    ]
  ])

  em_standard_event_details = [
    for event in local.em_standard_event_inputs :
    merge(
      event,
      {
        event_start_time = (
          event.fortnightly_active
          ? event.alternate_start_time
          : event.start_time
        )

        event_end_time = (
          event.fortnightly_active
          ? event.alternate_end_time
          : event.end_time
        )

        rotated_keys = (
          length(event.eligible_keys) == 0
          ? []
          : concat(
            slice(
              event.eligible_keys,
              (
                event.rotation_offset
                + event.phase_index
              ) % length(event.eligible_keys),
              length(event.eligible_keys)
            ),
            slice(
              event.eligible_keys,
              0,
              (
                event.rotation_offset
                + event.phase_index
              ) % length(event.eligible_keys)
            )
          )
        )
      }
    )
  ]

  em_standard_primary_events = [
    for event in local.em_standard_event_details : {
      rotation_key = "primary-${event.slot_key}"

      name = format(
        "Primary %s - phase %d",
        event.slot_name,
        event.phase_index + 1
      )

      start_time = event.event_start_time
      end_time   = event.event_end_time

      effective_since = event.phase_from
      effective_until = event.phase_until

      recurrence = [
        event.fortnightly_active
        ? "RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=${event.rrule_day}"
        : "RRULE:FREQ=WEEKLY;BYDAY=${event.rrule_day}"
      ]

      assignment_type = "rotating_member_assignment_strategy"

      shifts_per_member = 1

      member_ids = [
        for member_key in event.rotated_keys :
        module.users_em[
          local.em_members_by_key[member_key].email
        ].id
      ]
    }
    if(
      length(event.rotated_keys) > 0
      && (
        event.phase_until == null
        ? true
        : timecmp(
          event.event_start_time,
          event.phase_until
        ) < 0
      )
    )
  ]

  # ---------------------------------------------------------------------------
  # Fortnightly G6 primary rotation
  # ---------------------------------------------------------------------------

  em_fortnightly_event_inputs = flatten([
    for phase in local.em_primary_phase_details :
    phase.fortnightly_day == null ? [] : [
      for slot_key, slot in local.em_business_hour_slots : {
        phase_index = phase.index
        phase_from  = phase.from
        phase_until = phase.until

        slot_key   = slot_key
        slot_name  = slot.name
        slot_day   = slot.day
        rrule_day  = slot.rrule_day
        start_time = slot.start_time
        end_time   = slot.end_time

        member_key = phase.fortnightly_keys[0]
      }
      if(
        slot.day == phase.fortnightly_day
        && contains(
          local.em_working_patterns[
            local.em_members_by_key[
              phase.fortnightly_keys[0]
            ].rota.working_pattern
          ],
          slot_key
        )
      )
    ]
  ])

  em_fortnightly_primary_events = [
    for event in local.em_fortnightly_event_inputs : {
      rotation_key = "fortnightly-primary-${event.slot_key}"

      name = format(
        "Fortnightly primary %s - phase %d",
        event.slot_name,
        event.phase_index + 1
      )

      start_time      = event.start_time
      end_time        = event.end_time
      effective_since = event.phase_from
      effective_until = event.phase_until

      recurrence = [
        "RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=${event.rrule_day}"
      ]

      assignment_type = "rotating_member_assignment_strategy"

      shifts_per_member = 1

      member_ids = [
        module.users_em[
          local.em_members_by_key[event.member_key].email
        ].id
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # Shadow rotation
  # ---------------------------------------------------------------------------
  #
  # Shadow shifts are separate from primary shifts so they do not affect
  # primary rota fairness.
  #

  em_shadow_event_inputs = flatten([
    for member in local.users_em :
    member.rota.shadow.enabled ? [
      for slot_key, slot in local.em_business_hour_slots : {
        member_key = member.key

        slot_key   = slot_key
        slot_name  = slot.name
        slot_day   = slot.day
        rrule_day  = slot.rrule_day
        start_time = slot.start_time
        end_time   = slot.end_time

        effective_since = member.rota.shadow.from
        effective_until = member.rota.shadow.until
      }
      if(
        contains(
          local.em_working_patterns[
            member.rota.working_pattern
          ],
          slot_key
        )
        && (
          length(member.rota.shadow.days) == 0
          || contains(
            member.rota.shadow.days,
            slot.day
          )
        )
      )
    ] : []
  ])

  em_shadow_events = [
    for event in local.em_shadow_event_inputs : {
      rotation_key = "shadow-${event.member_key}-${event.slot_key}"

      name = format(
        "Shadow %s - %s",
        event.member_key,
        event.slot_name
      )

      start_time      = event.start_time
      end_time        = event.end_time
      effective_since = event.effective_since
      effective_until = event.effective_until

      recurrence = [
        "RRULE:FREQ=WEEKLY;BYDAY=${event.rrule_day}"
      ]

      assignment_type = "every_member_assignment_strategy"

      shifts_per_member = null

      member_ids = [
        module.users_em[
          local.em_members_by_key[event.member_key].email
        ].id
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # Shift-based schedule rotations
  # ---------------------------------------------------------------------------
  #
  # PagerDuty does not allow overlapping event configurations within the same
  # rotation.
  #
  # Each business-hours slot therefore gets its own rotation.
  #
  # Example:
  #
  #   primary-monday_am
  #     phase 1
  #     phase 2
  #
  # The phases are sequential within that rotation.
  #
  # Shadow and fortnightly coverage use separate rotations, allowing them to
  # overlap primary coverage where required.
  #

  em_shift_events = concat(
    local.em_standard_primary_events,
    local.em_fortnightly_primary_events,
    local.em_shadow_events
  )

  em_shift_events_by_rotation = {
    for event in local.em_shift_events :
    event.rotation_key => event...
  }

  em_shift_rotation_keys = sort(
    keys(local.em_shift_events_by_rotation)
  )

  em_shift_rotations = [
    for rotation_key in local.em_shift_rotation_keys : {
      key = rotation_key

      events = [
        for event in local.em_shift_events_by_rotation[rotation_key] : {
          name              = event.name
          start_time        = event.start_time
          end_time          = event.end_time
          effective_since   = event.effective_since
          effective_until   = event.effective_until
          recurrence        = event.recurrence
          assignment_type   = event.assignment_type
          shifts_per_member = event.shifts_per_member
          member_ids        = event.member_ids
        }
      ]
    }
  ]
}

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

check "em_member_keys_are_unique" {
  assert {
    condition = length(distinct([
      for member in local.users_em :
      member.key
    ])) == length(local.users_em)

    error_message = "EM member keys must be unique."
  }
}

check "em_grades_are_supported" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      contains(
        ["g6", "g7", "seo", "heo"],
        member.grade
      )
    ])

    error_message = "EM grade must be g6, g7, seo or heo."
  }
}

check "em_g6_and_g7_are_managers" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      !contains(
        ["g6", "g7"],
        member.grade
      )
      || member.role == "manager"
    ])

    error_message = "G6 and G7 EM members must be PagerDuty managers."
  }
}

check "em_working_patterns_exist" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      contains(
        keys(local.em_working_patterns),
        member.rota.working_pattern
      )
    ])

    error_message = "Every EM member must use a known working pattern."
  }
}

check "em_primary_windows_are_valid" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      !member.rota.primary.enabled
      ? true
      : (
        member.rota.primary.until == null
        ? true
        : timecmp(
          member.rota.primary.from,
          member.rota.primary.until
        ) < 0
      )
    ])

    error_message = "Primary rota end times must be after their start times."
  }
}

check "em_absence_windows_are_valid" {
  assert {
    condition = alltrue(flatten([
      for member in local.users_em : [
        for absence in member.rota.absences :
        absence.until == null
        ? true
        : timecmp(
          absence.from,
          absence.until
        ) < 0
      ]
    ]))

    error_message = "Planned absence end times must be after start times."
  }
}

check "em_shadow_windows_are_valid" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      !member.rota.shadow.enabled
      ? true
      : (
        member.rota.shadow.from == null
        || member.rota.shadow.until == null
        ? false
        : timecmp(
          member.rota.shadow.from,
          member.rota.shadow.until
        ) < 0
      )
    ])

    error_message = "Shadow rota periods need valid start and end times."
  }
}

check "em_shadow_days_are_valid" {
  assert {
    condition = alltrue(flatten([
      for member in local.users_em : [
        for day in member.rota.shadow.days :
        contains(
          [
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
          ],
          day
        )
      ]
    ]))

    error_message = "Shadow days must be weekdays."
  }
}

check "em_fortnightly_member_limit" {
  assert {
    condition = alltrue([
      for phase in local.em_primary_phase_details :
      length(phase.fortnightly_keys) <= 1
    ])

    error_message = "Only one fortnightly primary member is supported per phase."
  }
}

check "em_fortnightly_days_are_valid" {
  assert {
    condition = alltrue([
      for member in local.users_em :
      member.rota.primary.cadence != "fortnightly"
      ? true
      : (
        member.rota.primary.cadence_day == null
        ? false
        : contains(
          [
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
          ],
          member.rota.primary.cadence_day
        )
      )
    ])

    error_message = "Fortnightly primary members need a valid weekday."
  }
}

check "em_primary_slots_have_cover" {
  assert {
    condition = alltrue([
      for event in local.em_standard_event_inputs :
      length(event.eligible_keys) > 0
    ])

    error_message = "Every primary business-hours slot needs standard cover."
  }
}

# -----------------------------------------------------------------------------
# Shift-based PagerDuty schedule
# -----------------------------------------------------------------------------

module "em_shift_schedule" {
  source = "./modules/schedule_em"

  name = "EM Data Hub Rota - Shift Based"

  description = (
    "EM Data Hub business-hours primary and shadow support rota"
  )

  team_id   = module.teams_em["EM Data Hub Engineers"].id
  time_zone = "Europe/London"

  rotations = [
    for rotation in local.em_shift_rotations :
    rotation
    if length(rotation.events) > 0
  ]

  depends_on = [module.teams_em]
}

output "em_data_hub_shift_schedule_id" {
  value = module.em_shift_schedule.id
}
