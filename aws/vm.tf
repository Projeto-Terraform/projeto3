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

  /*Usamos o remote exec para criar dois documentos, onde dentro do primeiro
  contém o AMI da nossa VM e no outro o private_ip*/
  provisioner "remote-exec" {
    inline = [
      "echo ami: ${self.ami} >> /tmp/ami.txt",
      "echo private_ip: ${self.private_ip} >> /tmp/private_ip.txt",
    ]
  }

  /*Usamos o CONTENT para criar um arquivo de texto dentro da
  nossa máquina virtual contendo o Public IP da VM*/
  provisioner "file" {
    content     = "public_ip: ${self.public_ip}"
    destination = "/tmp/public_ip.txt"
  }

  /*Usamos o SOURCE para COPIAR um arquivo que está na nossa máquina
  para dentro da nossa VM */
  provisioner "file" {
    source      = "./teste.txt"
    destination = "/tmp/exemploteste.txt"
  }

  #connection fora do bloco para funcionar nos 3 blocos anteriores
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