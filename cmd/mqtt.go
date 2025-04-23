package main

import (
	"encoding/json"
	"fmt"
	"os"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type MqttClientWrapper struct {
	client      mqtt.Client
	topicPrefix string
}

func setupMqttClient(settings Settings) (*MqttClientWrapper, error) {
	l.Info("Connecting to MQTT server...")
	mqttOpts := mqtt.NewClientOptions()
	mqttOpts.AddBroker(settings.MqttConnectionString)

	mqttClient := mqtt.NewClient(mqttOpts)
	if token := mqttClient.Connect(); token.Wait() && token.Error() != nil {
		return nil, token.Error()
	}

	return &MqttClientWrapper{
		client:      mqttClient,
		topicPrefix: settings.MqttTopicPrefix,
	}, nil
}

func (w *MqttClientWrapper) publish(topic string, payload any) {
	if w.client == nil || !w.client.IsConnected() {
		l.Error("publish() called but MQTT client is not set up or is not connected")
		os.Exit(1)
	}

	var realPayload string
	switch payload := payload.(type) {
	case string:
		realPayload = payload

	default:
		jsonString, err := json.Marshal(payload)
		if err != nil {
			l.Error("error marshalling MQTT payload", "error", err)
			os.Exit(1)
		}
		realPayload = string(jsonString)
	}

	topic = fmt.Sprintf("%s/%s", w.topicPrefix, topic)
	l.Debug("Publishing message", "topic", topic, "payload", realPayload)
	if token := w.client.Publish(topic, 0, false, realPayload); token.Wait() && token.Error() != nil {
		l.Error("error publishing MQTT message", "error", token.Error())
		os.Exit(1)
	}
}
