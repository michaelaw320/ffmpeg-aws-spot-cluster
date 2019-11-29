variable "prefix" {
  description = "Prefix for all created resources"
}

variable "allowed_users" {
  type        = list(string)
  default     = []
  description = "Users allowed to assume the role"
}
