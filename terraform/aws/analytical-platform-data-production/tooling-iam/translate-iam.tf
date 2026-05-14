resource "aws_iam_role_policy_attachment" "translate_service_access_attachment" {
  for_each = toset(local.transcribe_users)

  policy_arn = "arn:aws:iam::aws:policy/TranslateFullAccess"
  role       = each.value
}
