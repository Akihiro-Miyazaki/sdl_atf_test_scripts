---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: Main Flow
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [OnVehicleData] As a hmi sends notificarion about VI paramter change
--  but mobile app is not subscribed for this parameter
--
-- Description:
-- In case:
-- 1) Hmi sends valid OnVehicleData notification to SDL
--    but mobile app is not subscribed for this parameter
-- SDL must:
-- Ignore this request and do not forward it to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local rpc1 = {
  name = "SubscribeVehicleData",
  params = {
    engineOilLife = true
  }
}

local rpc2 = {
  name = "OnVehicleData",
  params = {
    engineOilLife = 50.3
  }
}

local rpc3 = {
  name = "UnsubscribeVehicleData",
  params = {
    engineOilLife = true
  }
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc1.name, rpc1.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        {engineOilLife = {dataType = "VEHICLEDATA_ENGINEOILLIFE", resultCode = "SUCCESS"}})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    engineOilLife = {dataType = "VEHICLEDATA_ENGINEOILLIFE", resultCode = "SUCCESS"} })
end

local function processRPCUnsubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc3.name, rpc3.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc3.name, rpc3.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        {engineOilLife = {dataType = "VEHICLEDATA_ENGINEOILLIFE", resultCode = "SUCCESS"}})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    engineOilLife = {dataType = "VEHICLEDATA_ENGINEOILLIFE", resultCode = "SUCCESS"} })
end

local function checkNotificationSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  self.hmiConnection:SendNotification("VehicleInfo." .. rpc2.name, rpc2.params)
  mobileSession:ExpectNotification("OnVehicleData", rpc2.params)
end

local function checkNotificationIgnored(self)
  local mobileSession = common.getMobileSession(self, 1)
  self.hmiConnection:SendNotification("VehicleInfo." .. rpc2.name, rpc2.params)
  mobileSession:ExpectNotification("OnVehicleData", rpc2.params):Times(0)
  commonTestCases:DelayedExp(common.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc1.name, processRPCSubscribeSuccess)
runner.Step("RPC " .. rpc2.name .. " forwarded to mobile", checkNotificationSuccess)
runner.Step("RPC " .. rpc3.name, processRPCUnsubscribeSuccess)
runner.Step("RPC " .. rpc2.name .. " not forwarded to mobile", checkNotificationIgnored)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
