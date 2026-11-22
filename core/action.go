package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"unicode/utf8"

	"core/toolbox"

	"github.com/metacubex/mihomo/component/age"
)

type Action struct {
	Id     string      `json:"id"`
	Method Method      `json:"method"`
	Data   interface{} `json:"data"`
}

type ActionResult struct {
	Id     string      `json:"id"`
	Method Method      `json:"method"`
	Data   interface{} `json:"data"`
	Code   int         `json:"code"`
	Port   int64
}

type actionResultHeader struct {
	Id     string `json:"id"`
	Method Method `json:"method"`
	Code   int    `json:"code"`
	Raw    bool   `json:"raw,omitempty"`
}

func (result ActionResult) Json() ([]byte, error) {
	data := result.Data
	if err, ok := data.(error); ok {
		data = err.Error()
	}
	text, raw := data.(string)
	raw = raw && utf8.ValidString(text) && strings.IndexByte(text, 0) < 0
	var payload []byte
	if !raw {
		var err error
		if payload, err = json.Marshal(data); err != nil {
			return nil, err
		}
	}
	header, err := json.Marshal(actionResultHeader{
		Id:     result.Id,
		Method: result.Method,
		Code:   result.Code,
		Raw:    raw,
	})
	if err != nil {
		return nil, err
	}
	frame := make([]byte, 0, len(header)+1+len(text)+len(payload))
	frame = append(frame, header...)
	frame = append(frame, '\n')
	if raw {
		return append(frame, text...), nil
	}
	return append(frame, payload...), nil
}

func (result ActionResult) success(data interface{}) {
	result.Code = 0
	result.Data = data
	result.send()
}

func (result ActionResult) error(data interface{}) {
	result.Code = -1
	result.Data = data
	result.send()
}

func handleAction(action *Action, result ActionResult) {
	defer func() {
		if r := recover(); r != nil {
			result.error(fmt.Sprintf("panic: %v", r))
		}
	}()
	// stringData returns the action's string payload, which most actions
	// carry. A type mismatch is reported as a regular error reply instead
	// of panicking into the recover above (AM-07/T283).
	stringData := func() (string, bool) {
		data, ok := action.Data.(string)
		if !ok {
			result.error(fmt.Sprintf("invalid data for action %s: string payload expected", action.Method))
		}
		return data, ok
	}
	switch action.Method {
	case initClashMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		result.success(handleInitClash(paramsString))
		return
	case getIsInitMethod:
		result.success(handleGetIsInit())
		return
	case forceGcMethod:
		var forceFreeOSMemory, purge bool
		if action.Data != nil {
			if strVal, ok := action.Data.(string); ok {
				forceFreeOSMemory = strVal == "true" || strVal == "free"
				purge = strVal == "true"
			} else if boolVal, ok := action.Data.(bool); ok {
				forceFreeOSMemory = boolVal
				purge = boolVal
			}
		}
		handleForceGc(forceFreeOSMemory, purge)
		result.success(true)
		return
	case shutdownMethod:
		result.success(handleShutdown())
		return
	case validateConfigMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		var params ValidateConfigParams
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			params.Data = paramsString
		}
		result.success(handleValidateConfig(&params))
		return
	case importProfileMethod:
		var params ImportProfileParams
		paramsString, ok := stringData()
		if !ok {
			return
		}
		if err := json.Unmarshal([]byte(paramsString), &params); err != nil {
			result.success(err.Error())
			return
		}
		result.success(handleImportProfile(&params))
		return
	case decryptAgeConfigMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		var params DecryptAgeConfigParams
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			params.Data = paramsString
		}
		result.success(handleDecryptAgeConfig(&params))
		return
	case updateConfigMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(handleUpdateConfig([]byte(data)))
		return
	case setupConfigMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(handleSetupConfig([]byte(data)))
		return
	case getModeMethod:
		result.success(handleGetMode())
		return
	case getProxiesMethod:
		result.success(handleGetProxies())
		return
	case changeProxyMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		handleChangeProxy(data, func(value string) {
			result.success(value)
		})
		return
	case getTrafficMethod:
		result.success(handleGetTraffic())
		return
	case getTrafficSnapshotMethod:
		result.success(handleGetTrafficSnapshot())
		return
	case resetTrafficMethod:
		handleResetTraffic()
		result.success(true)
		return
	case asyncTestDelayMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		handleAsyncTestDelay(data, func(value string) {
			result.success(value)
		})
		return
	case asyncTestDelaysMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		handleAsyncTestDelays(data, func(value string) {
			result.success(value)
		})
		return
	case setForegroundMethod:
		value, _ := action.Data.(string)
		handleSetForeground(value == "true")
		result.success(true)
		return
	case startSpeedTestMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStartSpeedTest(data))
		return
	case probeSpeedTestMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleProbeSpeedTest(data))
		return
	case getSpeedTestServersMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleSpeedTestServers(data))
		return
	case cancelSpeedTestMethod:
		result.success(toolbox.HandleCancelSpeedTest())
		return
	case startStunTestMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStartStunTest(data))
		return
	case cancelStunTestMethod:
		result.success(toolbox.HandleCancelStunTest())
		return
	case startIperfServerMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStartIperfServer(data))
		return
	case stopIperfServerMethod:
		result.success(toolbox.HandleStopIperfServer())
		return
	case startIperfClientMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStartIperfClient(data))
		return
	case cancelIperfClientMethod:
		result.success(toolbox.HandleCancelIperfClient())
		return
	case startLocalPingMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStartLocalPing(data))
		return
	case cancelLocalPingMethod:
		result.success(toolbox.HandleCancelLocalPing())
		return
	case routeTraceMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleRouteTrace(data))
		return
	case dnsQueryMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleDnsQuery(data))
		return
	case mrsPrepareMethod:
		result.success(toolbox.HandleMrsPrepare())
		return
	case mrsLookupMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleMrsLookup(data))
		return
	case mrsDumpMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleMrsDump(data))
		return
	case cancelMrsLookupMethod:
		result.success(toolbox.HandleCancelMrsLookup())
		return
	case getTrafficStatsMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleGetTrafficStats(data))
		return
	case clearTrafficStatsMethod:
		result.success(toolbox.HandleClearTrafficStats())
		return
	case storeGetMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStoreGet(data))
		return
	case storeSetMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStoreSet(data))
		return
	case storeListMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStoreList(data))
		return
	case storeClearMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleStoreClear(data))
		return
	case startToolProxyMethod:
		result.success(toolbox.HandleStartToolProxy())
		return
	case stopToolProxyMethod:
		toolbox.HandleStopToolProxy()
		result.success("true")
		return
	case ageCryptMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		result.success(toolbox.HandleAgeCrypt(data))
		return
	case getConnectionsMethod:
		result.success(handleGetConnections())
		return
	case getConnectionsSummaryMethod:
		result.success(handleGetConnectionsSummary())
		return
	case closeConnectionsMethod:
		result.success(handleCloseConnections())
		return
	case resetConnectionsMethod:
		result.success(handleResetConnections())
		return
	case getRequestsMethod:
		result.success(handleGetRequests())
		return
	case startTrackRequestsMethod:
		result.success(handleStartTrackRequests())
		return
	case stopTrackRequestsMethod:
		result.success(handleStopTrackRequests())
		return
	case clearRequestsMethod:
		result.success(handleClearRequests())
		return
	case getLogsMethod:
		result.success(handleGetLogs())
		return
	case clearLogsMethod:
		result.success(handleClearLogs())
		return
	case exportConfigMethod:
		var params ExportConfigParams
		paramsString, ok := stringData()
		if !ok {
			return
		}
		if err := json.Unmarshal([]byte(paramsString), &params); err != nil {
			result.error(err)
			return
		}
		if err := handleExportConfig(&params); err != nil {
			result.error(err)
			return
		}
		result.success("")
		return
	case mergeProfilesMethod:
		var params MergeProfilesParams
		paramsString, ok := stringData()
		if !ok {
			return
		}
		if err := json.Unmarshal([]byte(paramsString), &params); err != nil {
			result.error(err)
			return
		}
		report, err := handleMergeProfiles(&params)
		if err != nil {
			result.error(err)
			return
		}
		result.success(report)
		return
	case getRuntimeConfigMethod:
		params := defaultSetupParams()
		paramsString, ok := stringData()
		if !ok {
			return
		}
		if err := UnmarshalJson([]byte(paramsString), params); err != nil {
			result.error(err)
			return
		}
		content, err := handleGetRuntimeConfig(params)
		if err != nil {
			result.error(err)
			return
		}
		result.success(content)
		return
	case getConfigMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		var params GetConfigParams
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			params.Path = paramsString
		}
		config, err := handleGetConfig(&params)
		if err != nil {
			result.error(err)
			return
		}
		result.success(config)
		return
	case closeConnectionMethod:
		id, ok := stringData()
		if !ok {
			return
		}
		result.success(handleCloseConnection(id))
		return
	case closeGroupConnectionsMethod:
		groupName, ok := stringData()
		if !ok {
			return
		}
		result.success(handleCloseGroupConnections(groupName))
		return
	case getExternalProvidersMethod:
		result.success(handleGetExternalProviders())
		return
	case getExternalProviderMethod:
		externalProviderName, ok := stringData()
		if !ok {
			return
		}
		result.success(handleGetExternalProvider(externalProviderName))
	case updateGeoDataMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		var params = map[string]string{}
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			result.success(err.Error())
			return
		}
		geoType := params["geo-type"]
		geoName := params["geo-name"]
		handleUpdateGeoData(geoType, geoName, func(value string) {
			result.success(value)
		})
		return
	case updateExternalProviderMethod:
		providerName, ok := stringData()
		if !ok {
			return
		}
		handleUpdateExternalProvider(providerName, func(value string) {
			result.success(value)
		})
		return
	case sideLoadExternalProviderMethod:
		paramsString, ok := stringData()
		if !ok {
			return
		}
		var params = map[string]string{}
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			result.success(err.Error())
			return
		}
		providerName := params["providerName"]
		data := params["data"]
		handleSideLoadExternalProvider(providerName, []byte(data), func(value string) {
			result.success(value)
		})
		return
	case parseExternalProviderContentMethod:
		providerName, ok := stringData()
		if !ok {
			return
		}
		handleParseExternalProviderContent(providerName, func(value string) {
			result.success(value)
		})
		return
	case startLogMethod:
		handleStartLog()
		result.success(true)
		return
	case stopLogMethod:
		handleStopLog()
		result.success(true)
		return
	case startListenerMethod:
		result.success(handleStartListener())
		return
	case stopListenerMethod:
		result.success(handleStopListener())
		return
	case getCountryCodeMethod:
		ip, ok := stringData()
		if !ok {
			return
		}
		handleGetCountryCode(ip, func(value string) {
			result.success(value)
		})
		return
	case getIpGeoMethod:
		ip, ok := stringData()
		if !ok {
			return
		}
		handleGetIpGeo(ip, func(value string) {
			result.success(value)
		})
		return
	case getMemoryMethod:
		handleGetMemory(func(value string) {
			result.success(value)
		})
		return
	case getCoreStatusMethod:
		handleGetCoreStatus(func(value string) {
			result.success(value)
		})
		return
	case setStateMethod:
		data, ok := stringData()
		if !ok {
			return
		}
		handleSetState(data)
		result.success(true)
	case flushFakeIPMethod:
		result.success(handleFlushFakeIP())
		return
	case flushDnsCacheMethod:
		handleFlushDnsCache()
		result.success(true)
		return
	case generateAgeKeyPairMethod:
		generate := age.GenX25519KeyPair
		if kind, _ := action.Data.(string); kind == "mlkem768x25519" {
			generate = age.GenHybridKeyPair
		}
		secretKey, publicKey, err := generate()
		if err != nil {
			result.error(err.Error())
			return
		}
		result.success(map[string]string{
			"secret-key": secretKey,
			"public-key": publicKey,
		})
		return
	case convertAgeSecretKeyToPublicKeyMethod:
		secretKey, ok := stringData()
		if !ok {
			return
		}
		publicKeys, err := age.ToPublicKeys(secretKey)
		if err != nil {
			result.error(err.Error())
			return
		}
		if len(publicKeys) == 0 {
			result.error("no public keys found")
			return
		}
		result.success(publicKeys[0])
		return
	case crashMethod:
		result.success(true)
		handleCrash()
	default:
		nextHandle(action, result)
	}
}
