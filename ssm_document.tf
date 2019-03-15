resource "aws_ssm_document" "ssm_enable_update_service" {
  name          = "AWL-EnableUpdateServices"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Sets Windows Update Service (wuauserv) to manual and starts service.",
  "parameters": {
    "Unused": {
      "type": "String",
      "description": "(Not Required)",
      "allowedValues": [
        "Unused",
        "Unused"
      ],
      "default": "False"
    }
  },
  "mainSteps": [
    {
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "action": "aws:runPowerShellScript",
      "name": "runPowerShellScript",
      "inputs": {
        "runCommand": [
          "# Enabled and starts Windows Update Service",
          "Set-Service -Name 'wuauserv' -StartupType Manual ",
          "Start-Service -Name 'wuauserv'"
        ],
        "workingDirectory": "",
        "timeoutSeconds": "30"
      }
    }
  ]
}
DOC
}
resource "aws_ssm_document" "ssm_disable_update_service" {
  name          = "AWL-DisableUpdateServices"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Sets Windows Update Service (wuauserv) to disable and stops service.",
  "parameters": {
    "Unused": {
      "type": "String",
      "description": "(Not Required)",
      "allowedValues": [
        "Unused",
        "Unused"
      ],
      "default": "False"
    }
  },
  "mainSteps": [
    {
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "action": "aws:runPowerShellScript",
      "name": "runPowerShellScript",
      "inputs": {
        "runCommand": [
          "# Enabled and starts Windows Update Service",
          "Stop-Service -Name 'wuauserv'",
          "Set-Service -Name 'wuauserv' -StartupType Disabled "
        ],
        "workingDirectory": "",
        "timeoutSeconds": "30"
      }
    }
  ]
}
DOC
}