resource "aws_transfer_ssh_key" "example" {
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.user.user_name
  body      = "... SSH key ..."
}
