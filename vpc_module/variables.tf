variable "cidr_block" {
  default = "10.0.0.0/24"
  type = string
}

variable "vpc_tag" {
  type = string
  default = "vpc"
}