package service

import (
	"strings"

	"github.com/QuantumNous/new-api/common"
	"github.com/QuantumNous/new-api/model"
	"github.com/QuantumNous/new-api/setting/ratio_setting"
)

// EnsureModelRatios ensures every model in the list has a ratio set.
// Missing ratios will be filled with defaultRatio and persisted to options.
func EnsureModelRatios(models []string, defaultRatio float64) (bool, []string, error) {
	if len(models) == 0 {
		return false, nil, nil
	}

	current := ratio_setting.GetModelRatioCopy()
	added := make([]string, 0)
	changed := false

	for _, modelName := range models {
		modelName = strings.TrimSpace(modelName)
		if modelName == "" {
			continue
		}
		normalized := ratio_setting.FormatMatchingModelName(modelName)
		if _, exists := current[normalized]; exists {
			continue
		}
		current[normalized] = defaultRatio
		added = append(added, normalized)
		changed = true
	}

	if !changed {
		return false, nil, nil
	}

	jsonBytes, err := common.Marshal(current)
	if err != nil {
		return false, nil, err
	}

	if err := model.UpdateOption("ModelRatio", string(jsonBytes)); err != nil {
		return false, nil, err
	}

	return true, added, nil
}
