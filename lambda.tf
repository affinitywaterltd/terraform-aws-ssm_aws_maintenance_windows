/*

### Snapshot Cleanup

resource "aws_lambda_function" "auto_daily_mw_snapshot_cleanup" {
  function_name = "auto_daily_mw_snapshot_cleanup"
  filename      = "${path.module}/auto_daily_mw_snapshot_cleanup.zip"

  role             = "${data.terraform_remote_state.core.lambda_snapshot_cleanup_role}" 
  source_code_hash = "${base64sha256(file("${path.module}/auto_daily_mw_snapshot_cleanup.zip"))}"
  handler          = "auto_daily_mw_snapshot_cleanup.lambda_handler"
  runtime          = "python3.6"

  description = "Deletes snapshots older than 14 tags if tagged with MaintenanceWindow"

  tags = "${local.base_tags}"

  memory_size = 128
  timeout     = 300
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.auto_daily_mw_snapshot_cleanup.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.schedule_daily.arn}"
}

# Attach Cloudwatch event to lambda function
resource "aws_cloudwatch_event_target" "auto_daily_mw_snapshot_cleanup" {
  target_id = "auto_daily_mw_snapshot_cleanup"
  arn = "${aws_lambda_function.auto_daily_mw_snapshot_cleanup.arn}"
  rule = "${aws_cloudwatch_event_rule.schedule_daily.name}"
}

resource "aws_cloudwatch_event_rule" "schedule_daily" {
  name        = "schedule_daily"
  description = "Runs daily"
  schedule_expression = "cron(0 1 * * ? *)"
  
}

*/