package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// metadata request objects

type AllModesResponse []struct {
	ModeName string `json:"modeName"`
}

type AllSeveritiesResponse []struct {
	ModeName      string `json:"modeName"`
	SeverityLevel int    `json:"severityLevel"`
	Description   string `json:"description"`
}

type AllLinesForModeResponse []struct {
	ModeName string `json:"modeName"`
	LineId   string `json:"id"`
	LineName string `json:"name"`
}

type AllDisruptionCategoriesResponse []string

// detailed request objects

type LineStatusResponse []struct {
	LineId       string `json:"id"`
	ModeName     string `json:"modeName"`
	LineStatuses []struct {
		StatusSeverity            int    `json:"statusSeverity"`
		StatusSeverityDescription string `json:"statusSeverityDescription"`
		Reason                    string `json:"reason"`

		Disruption struct {
			Category            string `json:"category"`
			CategoryDescription string `json:"categoryDescription"`
			Description         string `json:"description"`
		} `json:"disruption"`

		ValidityPeriods []struct {
			FromDate string `json:"fromDate"`
			ToDate   string `json:"toDate"`
		} `json:"validityPeriods"`
	}
}

// requests

var httpClient = http.Client{}

func GetAllModes(settings Settings) (AllModesResponse, error) {
	var response AllModesResponse
	err := tflRequest("Line/Meta/Modes", settings, &response)
	if err != nil {
		return nil, err
	}

	return response, nil
}

func GetAllSeverities(settings Settings) (AllSeveritiesResponse, error) {
	var response AllSeveritiesResponse
	err := tflRequest("Line/Meta/Severity", settings, &response)
	if err != nil {
		return nil, err
	}

	return response, nil
}

func GetAllLinesForMode(settings Settings, mode string) (AllLinesForModeResponse, error) {
	var response AllLinesForModeResponse
	err := tflRequest(fmt.Sprintf("Line/Mode/%s", mode), settings, &response)
	if err != nil {
		return nil, err
	}

	return response, nil
}

func GetAllDisruptionCategories(settings Settings) (AllDisruptionCategoriesResponse, error) {
	var response AllDisruptionCategoriesResponse
	err := tflRequest("Line/Meta/DisruptionCategories", settings, &response)
	if err != nil {
		return nil, err
	}

	return response, nil
}

func GetLineStatuses(settings Settings, line string) (LineStatusResponse, error) {
	var response LineStatusResponse
	err := tflRequest(fmt.Sprintf("Line/%s/Status", line), settings, &response)
	if err != nil {
		return nil, err
	}

	return response, nil
}

func tflRequest[T any](path string, settings Settings, result *T) error {
	req, err := http.NewRequest("GET", fmt.Sprintf("https://api.tfl.gov.uk/%s?app_key=%s", path, settings.TflAppKey), nil)
	if err != nil {
		return fmt.Errorf("error building request: %w", err)
	}

	req.Header.Add("user-agent", "tfl-to-mqtt")
	req.Header.Add("accept", "application/json")

	res, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("error making request: %w", err)
	}

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("non-OK response from API: %d", res.StatusCode)
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("error reading response body: %w", err)
	}

	err = json.Unmarshal(body, &result)
	if err != nil {
		return fmt.Errorf("error parsing response body: %w", err)
	}

	return nil
}
