#We need API to expose the functions publically
resource "aws_api_gateway_rest_api" "contactme_api" {
  name = "ContactMeAPI"
  description = "created with terraform"
}


