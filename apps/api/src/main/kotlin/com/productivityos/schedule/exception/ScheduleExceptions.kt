package com.productivityos.schedule.exception

class ScheduleNodeNotFoundException(message: String) : RuntimeException(message)

class AnchorDeletionNotAllowedException(message: String = "Anchor node deletion is not allowed") : RuntimeException(message)

class AnchorUpdateNotAllowedException(message: String = "Anchor node update is not allowed") : RuntimeException(message)
