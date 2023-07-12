package e2e

import (
	"regexp"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExamplesBasic(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/basic", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		virtualMachineId, ok := output["test_virtual_machine_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/virtualMachines/.+"), virtualMachineId)
	})
}
