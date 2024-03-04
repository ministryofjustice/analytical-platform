resource "aws_transfer_ssh_key" "ssh_key" {
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.user.user_name
  body      = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBMzzvEd8KCDG8lp9O6/D2tHK8aKZKIQiPWbcoPxr0I9CmDhr+DNVH8MnevXFrMx+aVreuK0lHEHWKInJBrxHXaK8OnsJjZwYjzAQSG4oBZYmHFW8r7xDkbKelOby0gNDzh=="
}
