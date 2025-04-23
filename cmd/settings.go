package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Settings struct {
	MqttConnectionString string
	MqttTopicPrefix      string
	UpdateInterval       int
	TflAppKey            string
	LineIds              []string
	GetApiInfo           bool
}

func getSettings() (Settings, error) {
	mqttConnectionString := os.Getenv("MQTT_CONNECTION_STRING")
	if len(mqttConnectionString) == 0 {
		mqttConnectionString = "tcp://0.0.0.0:1883"
	}

	mqttTopicPrefix := strings.TrimRight(os.Getenv("MQTT_TOPIC_PREFIX"), "/")
	if len(mqttTopicPrefix) == 0 {
		mqttTopicPrefix = "tfl"
	}

	updateIntervalStr := os.Getenv("UPDATE_INTERVAL")
	if len(updateIntervalStr) == 0 {
		updateIntervalStr = "0"
	}
	updateInterval, err := strconv.Atoi(updateIntervalStr)
	if err != nil {
		return Settings{}, fmt.Errorf("could not parse update interval as an integer: %w", err)
	}

	tflAppKey := os.Getenv("TFL_APP_KEY")

	lineIdsRaw := os.Getenv("LINE_IDS")
	lineIdsDirty := strings.Split(lineIdsRaw, ",")
	lineIdsClean := make([]string, 0)
	for _, id := range lineIdsDirty {
		clean := strings.TrimSpace(id)
		if id != "" {
			lineIdsClean = append(lineIdsClean, clean)
		}
	}

	getApiInfoRaw := os.Getenv("GET_API_INFO")
	getApiInfo := getApiInfoRaw != ""

	return Settings{
		MqttConnectionString: mqttConnectionString,
		MqttTopicPrefix:      mqttTopicPrefix,
		UpdateInterval:       updateInterval,
		TflAppKey:            tflAppKey,
		LineIds:              lineIdsClean,
		GetApiInfo:           getApiInfo,
	}, nil
}
