package com.productivityos.goal.exception

import java.util.UUID

class GoalNotFoundException(goalId: UUID) : RuntimeException("Goal not found: $goalId")
