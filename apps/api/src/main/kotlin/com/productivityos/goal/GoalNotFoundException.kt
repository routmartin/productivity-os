package com.productivityos.goal

import java.util.UUID

class GoalNotFoundException(goalId: UUID) : RuntimeException("Goal not found: $goalId")
