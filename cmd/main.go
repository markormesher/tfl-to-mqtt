package main

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"
)

var jsonHandler = slog.NewJSONHandler(os.Stdout, nil)
var l = slog.New(jsonHandler)

var maxStatuses = 5

func publishApiInfo(settings Settings, mqttClient *MqttClientWrapper) {
	// severity, grouped by mode

	severities, err := GetAllSeverities(settings)
	if err != nil {
		l.Error("error getting severities from API", "error", err)
		os.Exit(1)
	}

	modeToSeverities := make(map[string][]string, 0)

	for _, severity := range severities {
		_, ok := modeToSeverities[severity.ModeName]
		if !ok {
			modeToSeverities[severity.ModeName] = []string{severity.Description}
		} else {
			modeToSeverities[severity.ModeName] = append(modeToSeverities[severity.ModeName], severity.Description)
		}
	}

	for mode, severities := range modeToSeverities {
		mqttClient.publish(fmt.Sprintf("api_info/modes/%s/severities", mode), strings.Join(severities, ","))
	}

	// lines, grouped by mode

	modes, err := GetAllModes(settings)
	if err != nil {
		l.Error("error getting modes from API", "error", err)
		os.Exit(1)
	}

	for _, mode := range modes {
		lines, err := GetAllLinesForMode(settings, mode.ModeName)
		if err != nil {
			l.Error("error getting lines from API", "error", err)
			os.Exit(1)
		}

		lineIds := make([]string, len(lines))
		for i := range lines {
			lineIds[i] = lines[i].LineId
		}

		mqttClient.publish(fmt.Sprintf("api_info/modes/%s/lines", mode.ModeName), strings.Join(lineIds, ","))
	}

	// disruption categories (no grouping)

	disruptionCategories, err := GetAllDisruptionCategories(settings)
	if err != nil {
		l.Error("error getting disruption categories from API", "error", err)
		os.Exit(1)
	}

	mqttClient.publish("api_info/disruption_categories", strings.Join(disruptionCategories, ","))
}

func doUpdate(settings Settings, mqttClient *MqttClientWrapper) {
	now := time.Now()

	for _, line := range settings.LineIds {
		statusReports, err := GetLineStatuses(settings, line)
		if err != nil {
			l.Error("error getting line status from API", "error", err)
			os.Exit(1)
		}

		publishCount := 0

		if len(statusReports) > 0 {
			statusReport := statusReports[0]
			for _, status := range statusReport.LineStatuses {
				if publishCount >= maxStatuses {
					break
				}

				isValid := false
				for _, validityPeriod := range status.ValidityPeriods {
					from, err := time.Parse(time.RFC3339, validityPeriod.FromDate)
					if err != nil {
						l.Error("error parsing status validity period", "error", err)
						os.Exit(1)
					}

					to, err := time.Parse(time.RFC3339, validityPeriod.ToDate)
					if err != nil {
						l.Error("error parsing status validity period", "error", err)
						os.Exit(1)
					}

					if from.Compare(now) <= 0 && to.Compare(now) >= 0 {
						isValid = true
						break
					}
				}

				if !isValid {
					continue
				}

				publishCount++
				mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/severity", line, publishCount), status.StatusSeverityDescription)
				mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/reason", line, publishCount), status.Reason)
				mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/disruption_category", line, publishCount), status.Disruption.Category)
				mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/disruption_description", line, publishCount), status.Disruption.Description)
			}
		}

		if publishCount == 0 {
			l.Warn("line has no active statuses", "line", line)
		}

		for i := publishCount + 1; i <= maxStatuses; i++ {
			l.Debug("clearing unused slot", "slot", i)
			mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/severity", line, i), "")
			mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/reason", line, i), "")
			mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/disruption_category", line, i), "")
			mqttClient.publish(fmt.Sprintf("state/lines/%s/status_%d/disruption_description", line, i), "")
		}
	}

	mqttClient.publish("_meta/last_seen", now.Format(time.RFC3339))
}

func main() {
	settings, err := getSettings()
	if err != nil {
		l.Error("error getting settings", "error", err)
		os.Exit(1)
	}

	mqttClient, err := setupMqttClient(settings)
	if err != nil {
		l.Error("error setting up MQTT client", "error", err)
		os.Exit(1)
	}

	if settings.GetApiInfo {
		publishApiInfo(settings, mqttClient)
		l.Info("API info has been published. Use it to gather the line IDs you care about, configure them via the LINE_IDS enviroment variable, then remove the GET_API_INFO and re-run this tool")
	} else {
		if settings.UpdateInterval <= 0 {
			l.Info("Running once then exiting because update interval is <= 0")
			doUpdate(settings, mqttClient)
		} else {
			l.Info("Running forever", "interval", settings.UpdateInterval)
			for {
				doUpdate(settings, mqttClient)
				time.Sleep(time.Duration(settings.UpdateInterval * int(time.Second)))
			}
		}
	}
}
