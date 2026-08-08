output "file_system_id" { value = aws_efs_file_system.this.id }
output "access_point_id" { value = aws_efs_access_point.this.id }
output "dns_name" { value = aws_efs_file_system.this.dns_name }
