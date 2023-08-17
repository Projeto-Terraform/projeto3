# colocar o comando abaixo no terminal para gerar as chaves localmente:
# ssh-keygen -f key-vm

resource "aws_key_pair" "key" {
  key_name   = "aws-key"
  public_key = file("./aws-key.pub")
}

resource "aws_instance" "vm" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.key_name
  subnet_id                   = data.terraform_remote_state.vpc.outputs.subnet_id_aws
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.security_group_id_aws]
  associate_public_ip_address = true

  # salvar o IP da máquina dentro do arquivo
  # self é usado para referenciar um recurso dentro dele mesmo, no caso ele está
  # referenciando um atributo dentro do próprio bloco que está criando a VPC
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> public_ip.txt"
  }

  provisioner "file" {
    content     = "public_ip: ${self.public_ip}"
    destination = "/tmp/public_ip.txt"
  }

  provisioner "file" {
    source      = "./teste.txt"
    destination = "/tmp/exemploteste.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ami: ${self.ami} >> /tmp/ami.txt",
      "echo private_ip: ${self.private_ip} >> /tmp/private_ip.txt",
    ]
  }

  #connection fora do bloco para funcionar nos 3
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./aws-key")
    host        = self.public_ip
  }

  tags = {
    "Name" = "vm-terraform"
  }
}