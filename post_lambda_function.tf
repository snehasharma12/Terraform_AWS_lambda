locals{
    lambda_zip = "output/backend.zip"
}

data "archive_file" "backend" {
  type        = "zip"
  source_file = "backend.js"
  output_path = "${local.lambda_zip}"
}



resource "aws_lambda_function" "post" {
  filename      = "${local.lambda_zip}"
  function_name = "backend"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "backend.handler"

 
  #source_code_hash = "${filebase64sha256(local.lambda_zip)}"

  runtime = "nodejs14.x"

 
}