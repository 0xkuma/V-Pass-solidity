const Migrations = artifacts.require('VaccinePassport');
const fs = require('fs');

module.exports = function (deployer) {
  deployer.deploy(Migrations).then(() => {
    console.log('Migrations deployed');
    const abi = Migrations.abi;
    const bytecode = Migrations.bytecode;
    const contractAddress = Migrations.address;
    const contractName = Migrations.contractName;
    const contract = {
      abi,
      bytecode,
      contractAddress,
      contractName,
    };
    fs.writeFileSync('./contract.json', JSON.stringify(contract, null, 2));
    return contract;
  });
};
