variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}


variable "aws_instance_type" {}
variable "aws_ami" {}
variable "keyname"  {}
variable "key_name" {}
variable "elb_healthy_threshold" {}
variable "elb_unhealthy_threshold" {}
variable "elb_timeout" {}
variable "elb_interval" {}


variable "aws_tags" {
  type = "map"
  default = {
    "webserver1" = "MW-TW-Web-1"
	"webserver2" = "MW-TW-Web-2"
    "dbserver" = "MWTWDB" 
  }
}
