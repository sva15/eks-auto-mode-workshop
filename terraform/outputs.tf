# Output the EFS ID
output "efs_id" {
  value = aws_efs_file_system.wordpress_efs.id
}

output "efs_access_point_id" {
  value = aws_efs_access_point.wordpress_ap.id
}

output "efs_volume_handle" {
  value = "${aws_efs_file_system.wordpress_efs.id}::${aws_efs_access_point.wordpress_ap.id}"
}

output "aurora_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}