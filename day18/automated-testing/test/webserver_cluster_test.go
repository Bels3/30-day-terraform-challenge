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

func TestFullStackEndToEnd(t *testing.T) {

	uniqueID    := random.UniqueId()
	clusterName := fmt.Sprintf("day18-e2e-%s", uniqueID)

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
			"key":          fmt.Sprintf("day18/e2e/%s/terraform.tfstate", clusterName),
			"region":       "eu-west-1",
			"encrypt":      true,
			"use_lockfile": true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Layer 1: ALB serves HTTP traffic
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

	// Layer 2: ASG is named correctly
	asgName := terraform.Output(t, terraformOptions, "asg_name")
	assert.Contains(t, asgName, clusterName, "ASG name should contain the cluster name")

	// Layer 3: Security groups are provisioned
	albSgID      := terraform.Output(t, terraformOptions, "alb_security_group_id")
	instanceSgID := terraform.Output(t, terraformOptions, "instance_security_group_id")
	assert.NotEmpty(t, albSgID,      "ALB security group ID should not be empty")
	assert.NotEmpty(t, instanceSgID, "Instance security group ID should not be empty")

	// Layer 4: SNS alerting topic exists
	snsTopicArn := terraform.Output(t, terraformOptions, "sns_topic_arn")
	assert.Contains(t, snsTopicArn, clusterName, "SNS topic ARN should contain the cluster name")

	// Layer 5: CloudWatch log group is provisioned
	logGroupName := terraform.Output(t, terraformOptions, "log_group_name")
	assert.Contains(t, logGroupName, clusterName, "CloudWatch log group should contain the cluster name")
}
