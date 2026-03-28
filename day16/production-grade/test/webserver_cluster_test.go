package test

import (
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestWebserverCluster(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":  "test-cluster",
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
		},
		BackendConfig: map[string]interface{}{
			"bucket":       "terraform-state-beldine-2026",
			"key":          "day16/test/terraform.tfstate",
			"region":       "eu-west-1",
			"encrypt":      true,
			"use_lockfile": true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	url := "http://" + albDnsName

	http_helper.HttpGetWithRetry(
		t,
		url,
		nil,
		200,
		"Hello from test-cluster",
		30,
		10*time.Second,
	)
}
