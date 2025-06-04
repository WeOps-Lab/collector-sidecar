package daemon

import (
	"github.com/Graylog2/collector-sidecar/backends"
	"github.com/Graylog2/collector-sidecar/common/rest"
	"github.com/Graylog2/collector-sidecar/context"
	"github.com/Graylog2/collector-sidecar/system"
	"net/http"
)

type ResponseCollectorEnvConfiguration struct {
	ConfigurationId string            `json:"id"`
	EnvConfig       map[string]string `json:"env_config"`
}

func RequestEnvConfiguration(
	httpClient *http.Client,
	configurationId string,
	ctx *context.Ctx) (ResponseCollectorEnvConfiguration, error) {
	c := rest.NewClient(httpClient, ctx)
	c.BaseURL = ctx.ServerUrl

	r, err := c.NewRequest("GET", "/sidecar/env_config/"+ctx.NodeId+"/"+configurationId, nil, nil)
	if err != nil {
		msg := "Can not initialize REST request"
		system.GlobalStatus.Set(backends.StatusError, msg)
		log.Errorf("[RequestEnvConfiguration] %s", msg)
		return ResponseCollectorEnvConfiguration{}, err
	}

	envconfigurationResponse := ResponseCollectorEnvConfiguration{}
	resp, err := c.Do(r, &envconfigurationResponse)
	if err != nil && resp == nil {
		msg := "Fetching Envconfiguration failed"
		system.GlobalStatus.Set(backends.StatusError, msg+": "+err.Error())
		log.Errorf("[RequestEnvConfiguration] %s: %v", msg, err)
		return ResponseCollectorEnvConfiguration{}, err
	}

	return envconfigurationResponse, nil
}
