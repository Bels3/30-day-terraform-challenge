package test

import (
	"fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestWebserverClusterIntegration(t *testing.T) {
	t.Parallel()

	uniqueID    := random.UniqueId()
	clusterName := fmt.Sprintf("day18-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Reconfigure:  true,
		Vars: map[string]interface{}{
			"cluster_name":  clusterName,
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
		},
		BackendConfig: map[string]interface{}{
			"bucket":       "terraform-state-beldine-2026",
			"key":          fmt.Sprintf("day18/test/%s/terraform.tfstate", clusterName),
			"region":       "eu-west-1",
			"encrypt":      true,
			"use_lockfile": true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	url        := fmt.Sprintf("http://%s", albDnsName)

	assert.NotEmpty(t, albDnsName, "ALB DNS name should not be empty")

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		30,
		10*time.Second,
		func(status int, body string) bool {
			return status == 200 && len(body) > 0
		},
	)
}
