resource "auth0_role" "access_dashboard" {
  name        = "access:dashboard"
  description = "Allows user to access dashboard service"
}
