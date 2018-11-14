data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners      = ["099720109477"]
  most_recent = true
}

resource "aws_key_pair" "deployer" {
  key_name = "chef-key"
  public_key = "${file(var.my_public_key_path)}"
}


resource "aws_security_group" "sg" {
  name = "gmlp-ssh"

  // SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "chef_server" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.medium"
  key_name               = "${aws_key_pair.deployer.key_name}"
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]

}

resource "null_resource" "install_chef" {
  triggers {
    instace_id = "${aws_instance.chef_server.id}"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("${var.my_private_key_path}")}"
    }

    inline = [
      "sudo apt update",
      "sudo apt install -y wget",
      "wget https://packages.chef.io/files/stable/chef-server/12.18.14/ubuntu/16.04/chef-server-core_12.18.14-1_amd64.deb",
    ]
  }
}


output "chef-ip" {
  value = "${aws_instance.chef_server.public_ip}"
}

