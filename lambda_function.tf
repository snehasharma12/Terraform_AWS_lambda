locals{
    lambda_zip_location = "output/get_backend.zip"
}

data "archive_file" "get_backend" {
  type        = "zip"
  source_file = "get_backend.js"
  output_path = "${local.lambda_zip_location}"
}



resource "aws_lambda_function" "test_lambda" {
  filename      = "${local.lambda_zip_location}"
  function_name = "get_backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "get_backend.handler"

 
  source_code_hash = "${filebase64sha256(local.lambda_zip_location)}"

  runtime = "nodejs14.x"

 
}