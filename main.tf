resource "aws_ssm_maintenance_window" "default" {
  count    = "${var.weeks}"
  name     = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00"
  schedule = "cron(00 ${var.hour} ? 1/3 ${var.day}#${count.index+1} *)"
  duration = "${var.mw_duration}"
  cutoff   = "${var.mw_cutoff}"
  schedule_timezone = "Europe/London"
}


resource "aws_ssm_maintenance_window_target" "default" {
  count         = "${var.weeks}"
  window_id     = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  
  resource_type = "INSTANCE"
  

  targets {
    key    = "tag:ssmMaintenanceWindow"
    values = ["${var.type}_week-${count.index+1}_${var.day}_${var.hour}00"]
  }
  depends_on = ["${aws_ssm_maintenance_window.default[count.index]}"]
}


resource "aws_ssm_maintenance_window_task" "default_task1" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "AWS-ConfigureAWSPackage"
  description      = "Installs AwsVssComponents for snapshotting"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-ConfigureAWSPackage"
  priority         = 10
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "action"
    values = ["Install"]
  }
  task_parameters {
    name   = "name"
    values = ["AwsVssComponents"]
  }

  lifecycle {
    ignore_changes = ["task_parameters"]
  }
}


resource "aws_ssm_maintenance_window_task" "default_task2" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "AWSEC2-CreateVssSnapshot"
  description      = "Take Snapshot of instance"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWSEC2-CreateVssSnapshot"
  priority         = 20
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "ExcludeBootVolume"
    values = ["False"]
  }
  task_parameters {
    name   = "NoWriters"
    values = ["False"]
  }
  task_parameters {
    name   = "CopyOnly"
    values = ["False"]
  }
  task_parameters {
    name   = "tags"
    values = ["Key=Name,Value=SSM_Patching_Snapshot-${element(aws_ssm_maintenance_window.default.*.name, count.index)}"]
  }

  lifecycle {
    ignore_changes = ["task_parameters"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_task3" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "AWS-UpdateSSMAgent"
  description      = "Update SSM Agent"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-UpdateSSMAgent"
  priority         = 30
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "allowDowngrade"
    values = ["false"]
  }

  lifecycle {
    ignore_changes = ["task_parameters"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_task4" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "AWS-InstallWindowsUpdates"
  description      = "Install Windows Updates"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-InstallWindowsUpdates"
  priority         = 40
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "Action"
    values = ["Install"]
  }
  task_parameters {
    name   = "AllowReboot"
    values = ["True"]
  }
  task_parameters {
    name   = "Categories"
    values = ["CriticalUpdates,DefinitionUpdates,FeaturePacks,Microsoft,SecurityUpdates,Tools,UpdateRollups,Updates"]
  }
  task_parameters {
    name   = "SeverityLevels"
    values = ["Critical,Important,Low,Moderate,Unspecified"]
  }
  task_parameters {
    name   = "PublishedDaysOld"
    values = ["7"]
  }

  lifecycle {
    ignore_changes = ["task_parameters"]
  }
}