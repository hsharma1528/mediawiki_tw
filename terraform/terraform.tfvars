aws_profile = "himandevops"
aws_region  = "us-east-2"
vpc_cidr    = "10.0.0.0/16"
cidrs       = {
   web1 = "10.0.1.0/24"
   web2 = "10.0.2.0/24"
   db = "10.0.3.0/24"

} 
 aws_instance_type = "t2.micro"
 aws_ami = "ami-0986c2ac7"
 key_name = "ironman"
 elb_healthy_threshold = "2"
 elb_unhealthy_threshold = "2"
 elb_timeout = "3"
 elb_interval = "30"
 keyname = "mwkey"

