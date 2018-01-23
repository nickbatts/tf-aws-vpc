provider "aws" {
	region = "us-west-1"
}


#data "aws_subnet_ids" "private" {
#	vpc_id = "${aws_vpc.default.id}"
#}

# load availability zones
data "aws_availability_zones" "available" {}


resource "aws_vpc" "default" {
	cidr_block = "10.0.0.0/16"
	enable_dns_hostnames = true
	tags {
		Name = "MyCloud"
	}
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.default.id}"
}

## Public subnets

resource "aws_subnet" "public" {
	count 					= "${length(data.aws_availability_zones.available.names)}"
	vpc_id 					= "${aws_vpc.default.id}"
	cidr_block 				= "10.0.${count.index + 1}.0/24"
	availability_zone 		= "${element(data.aws_availability_zones.available.names, count.index)}"
	map_public_ip_on_launch = true

	tags {
		Name = "publicSN-${element(data.aws_availability_zones.available.names, count.index)}-${count.index + 1}"
		Description = "public subnets for VPC"
	}

}

## Public Subnets Routing Table

resource "aws_route_table" "public-routes" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.default.id}"
	}
}

resource "aws_route_table_association" "public" {
	count 			= "${length(aws_subnet.public.*.id)}"
	subnet_id 		= "${element(aws_subnet.public.*.id, count.index)}"
	route_table_id 	= "${aws_route_table.public-routes.id}"
}

## Private subnets

resource "aws_subnet" "private" {
	count 					= "${length(data.aws_availability_zones.available.names)}"
	vpc_id 					= "${aws_vpc.default.id}"
	cidr_block 				= "10.0.${count.index + aws_subnet.public.count + 1}.0/24"
	availability_zone 		= "${element(data.aws_availability_zones.available.names, count.index)}"
	map_public_ip_on_launch = false

	tags {
		Name = "privateSN-${element(data.aws_availability_zones.available.names, count.index)}-${count.index + 1}"
		Description = "private subnets for VPC"
	}

}

## EC2 Instances

resource "aws_instance" "bastion" {
	ami 				= "ami-79aeae19"
	availability_zone 	= "${element(data.aws_availability_zones.available.names, 0)}"
	instance_type 		= "t2.micro"
	key_name 			= "${var.key_name}"
	security_groups 	= ["${aws_security_group.bastion-sg.id}"]
	subnet_id 			= "${element(aws_subnet.public.*.id, 0)}"
	user_data			= <<-EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "updating system..."
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
apt-get update && apt-get dist-upgrade -y
reboot
                EOF

	tags {
		Name = "Bastion"
		Description = "public bastion for VPC"
	}

	depends_on = ["aws_subnet.public"]
}

## Bastion Security Group

resource "aws_security_group" "bastion-sg" {
	name 		= "bastion-sg"
	description = "Managed by Terraform - Allows SSH and icmp connections to bastion"
	vpc_id 		= "${aws_vpc.default.id}"

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = -1
		to_port = -1
		protocol = "icmp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["216.85.150.198/32","76.25.233.7/32"]
		self = true
	}
}



# outputs

output "Zones" {
  value = "${data.aws_availability_zones.available.names}"
}
output "Private Subnets" {
  value = ["${aws_subnet.private.*.cidr_block}"]
}
output "Public Subnets" {
  value = "${aws_subnet.public.*.cidr_block}"
}
output "Bastion dns" {
  value = "${aws_instance.bastion.public_dns}"
}