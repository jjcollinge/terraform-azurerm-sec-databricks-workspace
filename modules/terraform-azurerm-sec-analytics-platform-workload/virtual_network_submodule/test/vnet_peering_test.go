package vnet_peering_test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestVnetPeering(t *testing.T) {

  defer test_structure.RunTestStage(t, "destroy_testinfra", func() {
    TFDestroy(t, ".")
  })

  defer test_structure.RunTestStage(t, "destroy_vnet_peering", func() {
    TFDestroy(t, "..")
  })

  test_structure.RunTestStage(t, "deploy_testinfra", func() {
    TFDeploy(t, ".")
  })

  test_structure.RunTestStage(t, "deploy_vnet_peering", func() {
    TFDeploy(t, "vnet1")
  })

  test_structure.RunTestStage(t, "deploy_vnet_peering", func() {
    TFDeploy(t, "vnet2")
  })
}

func TFDeploy(t *testing.T, workingDir: string, configName: string, vars map[string]interface{}) {

  terraformOptions := &terraform.Options{
    TerraformDir: workingDir,
    Vars: vars,
  }

  configDir: string;
  configDir = "." + configName;

  os.Mkdir(configDir);
  test_structure.SaveTerraformOptions(t, configDir, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
}

func TFDestroy(t *testing.T, configName: string) {

  configDir: string;
  configDir = "." + configName;

  terraformOptions := test_structure.LoadTerraformOptions(t, configDir)
  terraform.Destroy(t, terraformOptions)
}


