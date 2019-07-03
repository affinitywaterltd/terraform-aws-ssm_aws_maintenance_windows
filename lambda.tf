

### Snapshot Cleanup

resource "aws_lambda_function" "auto_daily_mw_snapshot_cleanup" {
  function_name = "auto_daily_mw_snapshot_cleanup"
  filename      = "${path.module}/auto_daily_mw_snapshot_cleanup.zip"

  role             = "${aws_iam_role.lambda_snapshot_cleanup_role.arn}" 
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
  rule = "${aws_cloudwatch_event_rule.schedule_daily.arn}"
}

resource "aws_cloudwatch_event_rule" "schedule_daily" {
  name        = "schedule_daily"
  description = "Runs daily"
  schedule_expression = "cron(0 1 * * ? *)"
  
}

# IAM role
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_snapshot_cleanup_role" {
  name = "lambda-snapshot-cleanup-role"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_readonly_policy_attach" {
  role       = "${aws_iam_role.lambda_snapshot_cleanup_role.name}"
  policy_arn = "${aws_iam_policy.ec2_cleanup_snapshot.arn}"
}

resource "aws_iam_policy" "ec2_cleanup_snapshot" {
  name = "ec2-cleanup-snapshot"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot",
                "ec2:ModifySnapshotAttribute",
                "ec2:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}