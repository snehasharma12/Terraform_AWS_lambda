locals{
    lambda_zip_location = "output/get_backend.zip"
    lambda_zip = "output/backend.zip"
}

#archiving the data for get_backend file
data "archive_file" "get_backend" {
  type        = "zip"
  source_file = "get_backend.js"
  output_path = "${local.lambda_zip_location}"
}

#archiving the data for backend file
data "archive_file" "backend" {
  type        = "zip"
  source_file = "backend.js"
  output_path = "${local.lambda_zip}"
}

#creating lambda function for get method
resource "aws_lambda_function" "get_lambda" {
  filename      = "${local.lambda_zip_location}"
  function_name = "get_backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "get_backend.handler"
  source_code_hash = "${filebase64sha256(local.lambda_zip_location)}"
  runtime = "nodejs14.x"
}


#creating lambda function for post method
resource "aws_lambda_function" "post" {
  filename      = "${local.lambda_zip}"
  function_name = "backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "backend.handler"
  source_code_hash = "${filebase64sha256(local.lambda_zip)}"
  runtime = "nodejs14.x"
}





#The API needs one "endpoint" or "resource" in AWS
#The resource will be /contactme
resource "aws_api_gateway_resource" "contactme" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.contactme_api.root_resource_id}"
  path_part   = "{contactme+}"
  
}

#now resource is created!
#a HTTP method has to be set up
#created GET method for /contactme for get lambda function trigering
resource "aws_api_gateway_method" "contactme_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "GET"
  authorization = "NONE"

}

#integrate the get method with lambda function
resource "aws_api_gateway_integration" "get_backend" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_method.contactme_get.resource_id}"
  http_method = "${aws_api_gateway_method.contactme_get.http_method}"
  type = "AWS"

  integration_http_method = "POST"
  
  uri  = "${aws_lambda_function.get_lambda.invoke_arn}"
}


#created GET method for /contactme for get lambda function trigering
resource "aws_api_gateway_method" "contactme_post" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "POST"
  authorization = "NONE"

}

#integrate the get method with lambda function
resource "aws_api_gateway_integration" "backend" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_method.contactme_post.resource_id}"
  http_method = "${aws_api_gateway_method.contactme_post.http_method}"
  type = "AWS"

  integration_http_method = "POST"
  
  uri  = "${aws_lambda_function.post.invoke_arn}"
}





#module "contactme_get" {
 #   source = "./api_method"
  #  rest_api_id = aws_api_gateway_rest_api.contactme_api.id
   # resource_id = aws_api_gateway_resource.contactme_api_res_contactme.id
   # method = "GET"
   # path = aws_api_gateway_resource.contactme_api_res_contactme.path
   # lambda = "get_backend"
    
   # request_parameters = {
   # "method.request.path.proxy" = true
 # }
#}

#module "contactme_post" {
  #  source = "./api_method"
  #  rest_api_id = aws_api_gateway_rest_api.contactme_api.id
  #  resource_id = aws_api_gateway_resource.contactme_api_res_contactme.id
  #  method = "POST"
  #  path = aws_api_gateway_resource.contactme_api_res_contactme.path
  #  lambda = "backend"
    
  #  request_parameters = {
  #  "method.request.path.proxy" = true
  #}
#}





#invoke the lambda function
resource "aws_lambda_permission" "allow_api_gateway_for_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:824843761711:${aws_api_gateway_rest_api.contactme_api.id}/*/${aws_api_gateway_method.contactme_get.http_method}${aws_api_gateway_resource.contactme.path}"

}

resource "aws_lambda_permission" "allow_api_gateway_for_post" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:824843761711:${aws_api_gateway_rest_api.contactme_api.id}/*/${aws_api_gateway_method.contactme_post.http_method}${aws_api_gateway_resource.contactme.path}"
}

resource "aws_api_gateway_deployment" "contactme_api_deployment" {
    rest_api_id = aws_api_gateway_rest_api.contactme_api.id
    stage_name = "website"
    description = "deploy website"
}