data "external" "test_client_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}
