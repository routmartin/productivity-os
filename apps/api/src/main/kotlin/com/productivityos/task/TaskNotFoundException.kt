package com.productivityos.task

import java.util.UUID

class TaskNotFoundException(taskId: UUID) : RuntimeException("Task not found: $taskId")
