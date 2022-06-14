variable "assume_role_policy" {
  type        = string
  description = "The assume role policy for the AWS IAM role.  If blank, allows CodeBuild to assume the role."
  default     = ""
}

variable "name" {
  type        = string
  description = "The name of the AWS IAM role."
}

variable "policy_description" {
  type        = string
  description = "The description of the AWS IAM policy. Defaults to \"The policy for [NAME]\"."
  default     = ""
}

variable "policy_name" {
  type        = string
  description = "The name of the AWS IAM policy.  Defaults to \"[NAME]-policy\"."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the AWS IAM role."
  default     = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ids of the VPC subnets used by CodeBuild.  Use [\"*\"] to allow all subnets."
}

variable "vpc_ids" {
  type        = list(string)
  description = "The ids of the VPCs used by CodeBuild.  Use [\"*\"] to allow all VPCs."
}
