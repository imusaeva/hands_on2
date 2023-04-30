variable "sg_name" {}
variable "vpc_id" {}

variable "rules" {
    type = map(any)
}

