package com.productivityos.project

import java.util.UUID

class ProjectNotFoundException(projectId: UUID) : RuntimeException("Project not found: $projectId")
