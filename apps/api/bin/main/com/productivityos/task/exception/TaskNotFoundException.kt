package com.productivityos.task.exception

import java.util.UUID

class TaskNotFoundException(taskId: UUID) : RuntimeException("Task not found: $taskId")
