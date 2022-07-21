const VaccinePassport = artifacts.require('VaccinePassport');

contract('VaccinePassport', (accounts) => {
  let contract;
  const staff = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];

  it('should deploy', async () => {
    contract = await VaccinePassport.new({ from: staff });
    assert.ok(contract.address);
  });
  it('should add record', async () => {
    const result = await contract.addVaccineRecord(
      '0xBcD924481B87062AC3E5db7D5CaF9B6c75D0D563',
      'user001',
      'AAA',
      'HK',
      { from: staff },
    );
    assert.ok(result);
  });
  it('should not add record', async () => {
    const result = await contract.addVaccineRecord(
      '0xBcD924481B87062AC3E5db7D5CaF9B6c75D0D563',
      'user001',
      'AAA',
      'HK',
      { from: user1 },
    );
    assert.ok(!result);
  });
  // it('should user create comfirm record', async () => {
  //   const result = await contract.createReadVaccineRecord({ from: user1 });
  //   console.log(result);
  //   assert.ok(result);
  // });
  // it('should user comfirm to read record', async () => {
  //   const result = await contract.confirmReadVaccineRecord(0, { from: user1 });
  //   assert.ok(result);
  // });
  // it('should staff comfirm to read record', async () => {
  //   const result = await contract.confirmReadVaccineRecord(0, { from: staff });
  //   assert.ok(result);
  // });
  // it('should confirm number equal 2', async () => {
  //   const result = await contract.getConfirmNumber(0, { from: user1 });
  //   assert.equal(result, 2);
  // });
  // it('should staff execute to read record', async () => {
  //   const result = await contract.executeReadVaccineRecord(0, { from: staff });
  //   console.log(result.toString());
  //   assert.ok(result);
  // });
  // it('should read record execute to be ture', async () => {
  //   const result = await contract.getExecuteStatus(0, { from: staff });
  //   assert.equal(result, true);
  // });
});
