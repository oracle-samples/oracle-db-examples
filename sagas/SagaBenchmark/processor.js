// Make sure we don't use the original faker library that has been sabatoged by its original creator.
const { faker } = require('@faker-js/faker');
const fs = require('fs');
const PropertiesReader = require('properties-reader');
const properties = PropertiesReader('src/main/resources/application.properties');

// TODO: We could randomize the entire payload here instead of just fields. That would allow us to have a random number of guests, randomly choose flight and/or car, etc..
function generateData(requestParams, ctx, ee, next) {
  let numFlightsToCreate = properties.get("numOfFlightsToCreate");
  const flightId = []
  for(let i=0;i<numFlightsToCreate;i++){
    flightId[i] = 200 + i;
  }
  generateFlightData(ctx, flightId);
  generateCarRentalData(ctx);
  return next();
}

function generateFlightData(ctx, flightId) {
  const maxCustomers = properties.get("maxCustomersPerFlight");
  const numberOfCustomers = Math.floor(Math.random() * maxCustomers) + 1;
  let a = [];
  for (let i = 0; i < numberOfCustomers; ++i) {
    a.push({
      firstName: faker.name.firstName(),
      lastName: faker.name.lastName(),
      birthdate: faker.date.birthdate().toISOString().split("T")[0],
      gender: faker.name.gender(true).substring(0, 1),
      email: faker.internet.email(),
      phonePrimary: faker.phone.number('###-###-####'),
      flightId: selectRandomFlightId(flightId),
      seatType: selectRandomSeatType(),
      seatNumber: generateRandomSeat()
    });
  }

  ctx.vars["passengers"] = a;
}

function generateRandomSeat() {
  const alphabet = "abcdefghijklmnopqrstuvwxyz"
  const randomCharacter = alphabet[Math.floor(Math.random() * alphabet.length)];

  return (Math.floor(Math.random() * 99) + 1) + randomCharacter;
}

function selectRandomSeatType() {
  const seatType = [
    "ECONOMY_SEATS",
    "BUSINESS_SEATS",
    "FIRSTCLASS_SEATS"
  ];

  return seatType[Math.floor(Math.random() * seatType.length)];
}


/**
 * Reads the sagabenchmark.properties file and gets the numOfFlightsToCreate count from the file.
 * @param {*} requestParams 
 * @param {*} ctx 
 * @param {*} ee 
 * @param {*} next 
 * @returns 
 */
function getNumOfFlightsToCreate(requestParams, ctx, ee, next) {
  let numFlightsToCreate = properties.get("numOfFlightsToCreate");
  console.log(`numFlightsToCreate: ${numFlightsToCreate}`);
  ctx.vars["numOfFlightsToCreate"] = numFlightsToCreate;
  return next();
}

function selectRandomFlightId(flightId) {
  return flightId[Math.floor(Math.random() * flightId.length)];
}

function generateCarRentalData(ctx) {
  ctx.vars["carCustomer"] = faker.name.findName();
  ctx.vars["carCustBirthDate"] = faker.date.birthdate().toISOString().split("T")[0];
  ctx.vars["carCustPhone"] = faker.phone.number('###-###-####');
  ctx.vars["startDate"] = faker.date.soon().toISOString().split("T")[0];
  ctx.vars["endDate"] = faker.date.soon(faker.random.numeric()).toISOString().split("T")[0];
  ctx.vars["carType"] = selectRandomCarType();
  ctx.vars["diversLicense"] = generateRandomDriverLicense();
}

function selectRandomCarType() {
  const carType = [
    "COMPACT",
    "SUV",
    "VAN",
    "TRUCK",
    "LUXURY"
  ];

  return carType[Math.floor(Math.random() * carType.length)];
}

function generateRandomDriverLicense() {
  return faker.random.alpha(1) + faker.random.numeric(7);
}

/**
 * Set the status code from the get /status/:id request that will be used in the transactionState method.
 * 
 * @param {*} requestParams 
 * @param {*} response 
 * @param {*} context 
 * @param {*} ee 
 * @param {*} next 
 * @returns 
 */
function setStatusCode(requestParams, response, context, ee, next) {
  context.vars["statusCode"] = response.statusCode;
  return next();
}

/**
 * Reads the test.json file and gets the vusers.created count from the file.
 * @param {*} requestParams 
 * @param {*} ctx 
 * @param {*} ee 
 * @param {*} next 
 * @returns 
 */
function getVuserCount(requestParams, ctx, ee, next) {
  let rawdata = fs.readFileSync('test.json');
  let artilleryOutput = JSON.parse(rawdata);
  let countersInfo = artilleryOutput.aggregate.counters;
  ctx.vars["vusersCount"] = countersInfo['vusers.created'];
  return next();
}

/**
 * Checks the status code from the the get /status/:id request to continue the loop until a non 202 status code is returned.
 * 
 * @param {*} context 
 * @param {*} next 
 * @returns 
 */
function transactionState(context, next) {
  const continueLooping = context.vars.statusCode == 202;
  // While `continueLooping` is true, the `next` function will
  // continue the loop in the test scenario.
  return next(continueLooping);
}

function printSeatValidationResponse(requestParams, response, context, ee, next) {
  console.log(`Seat Validation Response: ${response.body}`);
  return next();
}

function printPersistentQueueValidationResponse(requestParams, response, context, ee, next) {
  console.log(`Persistent Queue Validation Response: ${response.body}`);
  return next();
}

module.exports = {
  generateData,
  setStatusCode,
  transactionState,
  printSeatValidationResponse,
  printPersistentQueueValidationResponse,
  getVuserCount,
  getNumOfFlightsToCreate
};
