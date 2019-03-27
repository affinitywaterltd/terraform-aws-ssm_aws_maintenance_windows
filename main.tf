
resource "aws_ssm_maintenance_window" "pre" {
  count    = "${var.weeks}"
  #name     = "pre_${var.type}_week-${count.index+1}_${var.day}_${var.hour}00_testval${var.testval}"
  name = "${var.weeks > 1 ? "pre_${var.type}_week-${count.index+1}_${var.day}_${var.hour}00" : "pre_${var.type}_week-${var.week}_${var.day}_${var.hour}00"}"
  #schedule = "cron(00 ${var.hour} ? 1/3 ${var.day}#${count.index+1} *)"
  schedule = "${var.weeks > 1 ? "cron(00 ${var.hour} ? 1/3 ${var.day}#${count.index+1} *)" : "cron(00 ${var.hour} ? 1/3 ${var.day}#${var.week} *)"}"
  duration = "${var.mw_duration}"
  cutoff   = "${var.mw_cutoff}"
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "pre" {
  count         = "${var.weeks}"
  window_id     = "${element(aws_ssm_maintenance_window.pre.*.id, count.index)}"
  
  resource_type = "INSTANCE"
  
  targets {
    key    = "tag:ssmMaintenanceWindow"
    values = ["${var.type}_week-${count.index+1}_${var.day}_${var.hour}00"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_pre_task_enable" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.pre.*.id, count.index)}"
  name             = "enable_wsus"
  description      = "Enable Windows Update Service"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 10
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.pre.*.id, count.index)}"]
  }

  task_parameters {
    name   = "commands"
    values = ["Set-Service -Name 'wuauserv' -StartupType Manual","Start-Service -Name 'wuauserv'"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_pre_task_powershell" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.pre.*.id, count.index)}"
  name             = "install_powershell_v3"
  description      = "Installs Powershell v3 Update Package"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 20
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.pre.*.id, count.index)}"]
  }

  task_parameters {
    name   = "commands"
    values = ["wusa.exe  /i ${var.powershell_package_file} ${var.powershell_package_patameters}"]
  }
}


#
#
# Update Window - 30mins past
#
#


resource "aws_ssm_maintenance_window" "default" {
  count    = "${var.weeks}"
  name     = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00"
  schedule = "cron(30 ${var.hour} ? 1/3 ${var.day}#${count.index+1} *)"
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
}

resource "aws_ssm_maintenance_window_task" "default_task_aws_tools_install" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "install_aws_tools_for_windows"
  description      = "Install AWS Tools for Windows"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-InstallApplication"
  priority         = 5
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }


  task_parameters {
    name   = "source"
    values = ["${var.powershell_package_file_before}"]
  } 
  task_parameters {
    name   = "parameters"
    values = ["${var.powershell_package_patameters_before}"]
  } 

}

resource "aws_ssm_maintenance_window_task" "default_task_enable" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "reset_wsus"
  description      = "Reset Windows Update Service"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 10
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "commands"
    values = ["Stop-Service -Name 'wuauserv'","Remove-Item -Path 'C:\\Windows\\SoftwareDistribution' -Recurse","Set-Service -Name 'wuauserv' -StartupType Manual","Start-Service -Name 'wuauserv'"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_vss_install" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "install_aws_vss"
  description      = "Installs AwsVssComponents for snapshotting"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-ConfigureAWSPackage"
  priority         = 20
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
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


resource "aws_ssm_maintenance_window_task" "default_task_snapshot" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "take_aws_snapshot"
  description      = "Take Snapshot of instance"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWL-TakeAWSVssSnapshot"
  priority         = 30
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
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

resource "aws_ssm_maintenance_window_task" "default_task_ssmagent" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "update_ssm_agent"
  description      = "Update SSM Agent"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-UpdateSSMAgent"
  priority         = 40
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
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

resource "aws_ssm_maintenance_window_task" "default_task_updates" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "install_windows_updates"
  description      = "Install Windows Updates"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWL-InstallWindowsUpdates"
  priority         = 50
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
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

resource "aws_ssm_maintenance_window_task" "default_task_disble" {
  count            = "${var.weeks}"
  window_id        = "${element(aws_ssm_maintenance_window.default.*.id, count.index)}"
  name             = "disable_wsus"
  description      = "Reset Windows Update Service"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 60
  service_role_arn = "${var.role}"
  max_concurrency  = "${var.mw_concurrency}"
  max_errors       = "${var.mw_error_rate}"

  logging_info {
      s3_bucket_name = "${var.s3_bucket}"
      s3_region = "${var.region}"
      s3_bucket_prefix = "${var.type}_week-${count.index+1}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
  }

  targets {
    key    = "WindowTargetIds"
    values = ["${element(aws_ssm_maintenance_window_target.default.*.id, count.index)}"]
  }

  task_parameters {
    name   = "commands"
    values = ["Stop-Service -Name 'wuauserv'","Set-Service -Name 'wuauserv' -StartupType Disabled"]
  }
}