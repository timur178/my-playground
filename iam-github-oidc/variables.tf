variable "url" { type = string }
variable "project" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "oidc_role_name" { type = string }
variable "create" {
  type    = bool
  default = false
}
