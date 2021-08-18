# Define variables
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

#**************************************************************************************************************

#creating lambda function for get method
resource "aws_lambda_function" "get_lambda" {
  filename      = "${local.lambda_zip_location}"
  function_name = "get_backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "get_backend.handler"
  source_code_hash = "${filebase64sha256(local.lambda_zip_location)}"
  runtime = "nodejs14.x"
}

#************************************************************************************************************

#creating lambda function for post method
resource "aws_lambda_function" "post" {
  filename      = "${local.lambda_zip}"
  function_name = "backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "backend.handler"
  source_code_hash = "${filebase64sha256(local.lambda_zip)}"
  runtime = "nodejs14.x"
}

##############################################################################################################

#We need API to expose the functions publically
resource "aws_api_gateway_rest_api" "contactme_api" {
  name = "ContactMeAPI"
  description = "created with terraform"
}


#The API needs one "endpoint" or "resource" in AWS
#The resource will be /contactme
resource "aws_api_gateway_resource" "contactme" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.contactme_api.root_resource_id}"
  path_part   = "contactme"
  
}

#***********************************************************************************************************

#now resource is created!
#a HTTP GET method has to be set up

#created GET method for method request
resource "aws_api_gateway_method" "request_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "GET"
  authorization = "NONE"
}

#integrate the get method with lambda function (integration request)
resource "aws_api_gateway_integration" "request_method_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_resource.contactme.id}"
  http_method = "${aws_api_gateway_method.request_method.http_method}"
  type = "AWS"
  integration_http_method = "POST"
  uri  = "${aws_lambda_function.get_lambda.invoke_arn}"
}

#create GET method Response
resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "${aws_api_gateway_integration.request_method_integration.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

#Created the integrated response for GET
resource "aws_api_gateway_integration_response" "response_method_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_resource.contactme.id}"
  http_method = "${aws_api_gateway_method_response.response_method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method.status_code}"
  response_templates = {
    "application/json" = ""
  }
}

#*********************************************************************************************************************


#created POST method for method request
resource "aws_api_gateway_method" "request_method_post" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
      "method.request.path.proxy" = true
  }
}

##integrate the post method with lambda function (integration request)
resource "aws_api_gateway_integration" "request_method_integration_post" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_resource.contactme.id}"
  http_method = "${aws_api_gateway_method.request_method_post.http_method}"
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri  = "${aws_lambda_function.post.invoke_arn}"
}

#create POST method Response
resource "aws_api_gateway_method_response" "response_method_post" {
  rest_api_id   = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id   = "${aws_api_gateway_resource.contactme.id}"
  http_method   = "${aws_api_gateway_integration.request_method_integration_post.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

#Created the integrated response for POST
resource "aws_api_gateway_integration_response" "response_method_integration_post" {
  rest_api_id = "${aws_api_gateway_rest_api.contactme_api.id}"
  resource_id = "${aws_api_gateway_resource.contactme.id}"
  http_method = "${aws_api_gateway_method_response.response_method_post.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method_post.status_code}"
  response_templates = {
    "application/json" = ""
  }
}

#******************************************************************************************************************

#invoke the lambda function
resource "aws_lambda_permission" "allow_api_gateway_for_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-2:824843761711:${aws_api_gateway_rest_api.contactme_api.id}/*/${aws_api_gateway_method.request_method.http_method}${aws_api_gateway_resource.contactme.path}"

}

resource "aws_lambda_permission" "allow_api_gateway_for_post" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-2:824843761711:${aws_api_gateway_rest_api.contactme_api.id}/*/${aws_api_gateway_method.request_method_post.http_method}${aws_api_gateway_resource.contactme.path}"
}

#*****************************************************************************************************************

resource "aws_api_gateway_deployment" "contactme_api_deployment" {
    rest_api_id = aws_api_gateway_rest_api.contactme_api.id
    stage_name = "website"
    description = "deploy website"
}