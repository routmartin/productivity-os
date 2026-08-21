package com.productivityos.project.exception

import java.util.UUID

class ProjectNotFoundException(projectId: UUID) : RuntimeException("Project not found: $projectId")
