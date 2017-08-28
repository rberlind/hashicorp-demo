disable_mlock = true

storage "file" {
  path = "/home/vagrant/vault/data"
}

listener "tcp" {
 address = "127.0.0.1:8200"
 tls_disable = 1
}
