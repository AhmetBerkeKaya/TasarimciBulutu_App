// lib/data/models/enums.dart

// users.role
enum UserRole {
  admin,      // admin rolünü de ekleyelim
  freelancer,
  client,     // 'company' yerine 'client' olarak güncelledik
}

// projects.status
enum ProjectStatus {
  open,
  inProgress,
  completed,
  cancelled,
}

// applications.status
enum ApplicationStatus {
  pending,
  accepted,
  rejected,
}