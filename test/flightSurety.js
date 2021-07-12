
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var Web3 = require('web3')
var url = 'HTTP://127.0.0.1:7545';
var web3 = new Web3(url);

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
  
  it('contract owner is registered as an airline when contract is deployed', async () => {
    let airlinesCount = await config.flightSuretyData.airlinesCount.call(); 
    let isAirline = await config.flightSuretyData.isAirline.call(accounts[0]); 
    assert.equal(isAirline, true, "First airline should be registired when contact is deployed.");
  });

it("(airline) needs 50% votes to register an Airline using registerAirline() once there are 4 or more airlines registered", async () => {

    try {
        await config.flightSuretyApp.registerAirline(accounts[2], "dimeji airline", {from: accounts[0]});
        await config.flightSuretyApp.registerAirline(accounts[3], "arik air", {from: accounts[0]});
        await config.flightSuretyApp.registerAirline(accounts[4], "air peace", {from: accounts[0]});
    }
    catch(e) {
      console.log(e);
    }
    let result = await config.flightSuretyData.isAirline.call(accounts[4]);
    let airlinesCount = await config.flightSuretyData.airlinesCount.call(); 

    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided adequate funding");
    
  });

   it('(airline) can register a flight using registerFlight()', async () => {
    flightTimestamp = Math.floor(Date.now() / 1000);
    try {
        await config.flightSuretyApp.registerFlight("air101", "Nigeria", flightTimestamp, {from: config.firstAirline});
    }
    catch(e) {
      console.log(e);
    }
  });

});
