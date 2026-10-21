variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/corvanta-practice.pub"
}