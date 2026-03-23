variable "user_names" {
  description = "List of IAM usernames for count example"
  type        = list(string)
  default     = ["alice", "bob", "charlie"]
}

variable "users" {
  description = "Map of users with department and admin status"
  type = map(object({
    department = string
    admin      = bool
  }))
  default = {
    alice   = { department = "engineering", admin = true }
    bob     = { department = "marketing",   admin = false }
    charlie = { department = "devops",      admin = true }
  }
}

variable "enable_autoscaling" {
  description = "Enable autoscaling policy"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
