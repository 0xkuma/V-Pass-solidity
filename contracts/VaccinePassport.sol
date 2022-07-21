// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract VaccinePassport is Ownable {
    struct Users {
        string userName;
        bool isActive;
        uint256 numVaccinations;
        mapping(uint256 => VaccineRecordDetail) vaccineRecordDetail;
    }

    struct VaccineRecordDetail {
        string vaccineType;
        string location;
        uint256 timestamp;
    }

    struct VaccineRecordAccess {
        address accessAddress;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(address => Users) private users;

    function createUserProfile(string memory _userName) public {
        require(!users[msg.sender].isActive, "User already exists.");
        users[msg.sender].userName = _userName;
        users[msg.sender].numVaccinations = 0;
        users[msg.sender].isActive = true;
    }

    function isValidVaccine(string memory _vaccineType)
        private
        pure
        returns (bool)
    {
        string[2] memory vaccineList = ["AAA", "BBB"];
        for (uint256 i; i < vaccineList.length; i++) {
            if (
                keccak256(abi.encodePacked(_vaccineType)) ==
                keccak256(abi.encodePacked(vaccineList[i]))
            ) {
                return true;
            }
        }
        return false;
    }

    function addVaccineRecord(
        address _userAddress,
        string memory _vaccineType,
        string memory _location
    ) public onlyOwner {
        require(isValidVaccine(_vaccineType), "Invalid vaccine type.");
        Users storage user = users[_userAddress];
        uint256 numVaccinations = user.numVaccinations;
        user.vaccineRecordDetail[numVaccinations].vaccineType = _vaccineType;
        user.vaccineRecordDetail[numVaccinations].location = _location;
        user.numVaccinations++;
    }

    VaccineRecordAccess[] public vaccineRecordAccessList;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier isAccessAddress(uint256 _txIndex) {
        require(
            msg.sender == vaccineRecordAccessList[_txIndex].accessAddress ||
                msg.sender == Ownable.owner(),
            "Not access permission."
        );
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < vaccineRecordAccessList.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(
            !vaccineRecordAccessList[_txIndex].executed,
            "tx already executed"
        );
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // create request to read to record
    function createReadVaccineRecord() public returns (uint256 _txIndex) {
        vaccineRecordAccessList.push(
            VaccineRecordAccess({
                accessAddress: msg.sender,
                executed: false,
                numConfirmations: 0
            })
        );
        return vaccineRecordAccessList.length - 1;
    }

    // confirm to read record
    function confirmReadVaccineRecord(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        isAccessAddress(_txIndex)
    {
        VaccineRecordAccess
            storage vaccineRecordAccess = vaccineRecordAccessList[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;
        vaccineRecordAccess.numConfirmations += 1;
    }

    function getConfirmNumber(uint256 _txIndex) public view returns (uint256) {
        return vaccineRecordAccessList[_txIndex].numConfirmations;
    }

    event VaccineRecordEvent(
        address indexed _userAddress,
        string _userName,
        string _vaccineType,
        string _location,
        uint256 _timestamp
    );

    // read record
    function executeReadVaccineRecord(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        returns (
            string memory _userName,
            string memory _vaccineType,
            string memory _location,
            uint256 _timestamp
        )
    {
        VaccineRecordAccess
            storage vaccineRecordAccess = vaccineRecordAccessList[_txIndex];
        require(vaccineRecordAccess.numConfirmations == 2, "cannot execute tx");
        vaccineRecordAccess.executed = true;
        _userName = users[vaccineRecordAccess.accessAddress].userName;
        _vaccineType = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .vaccineType;
        _location = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .location;
        _timestamp = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .timestamp;
        emit VaccineRecordEvent(
            vaccineRecordAccess.accessAddress,
            _userName,
            _vaccineType,
            _location,
            _timestamp
        );
        return (_userName, _vaccineType, _location, _timestamp);
        // VaccineRecordDetail memory vaccineRecordDetail = users[vaccineRecordAccess.accessAddress].vaccineRecordDetail[0];
        // return vaccineRecordDetail;
    }

    function getExecuteStatus(uint256 _txIndex) public view returns (bool) {
        return vaccineRecordAccessList[_txIndex].executed;
    }

    // revoke Confrim
    function revokeReadVaccineRecord(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        isAccessAddress(_txIndex)
    {
        VaccineRecordAccess
            memory vaccineRecordAccess = vaccineRecordAccessList[_txIndex];
        isConfirmed[_txIndex][msg.sender] = false;
        vaccineRecordAccess.numConfirmations--;
    }

    // get vaccineReadRecord length
    function getVaccineReadRecordLength() public view returns (uint256) {
        return vaccineRecordAccessList.length;
    }

    //greeting
    function greeting() public pure returns (string memory) {
        return "Hello, world!";
    }

    struct test {
        uint256 num;
        string name;
    }
    test[] public testList;

    event TestEvent(uint256 indexed _num, string _name);

    function addTest(uint256 num, string memory name) public {
        testList.push(test({num: num, name: name}));
        emit TestEvent(num, name);
    }

    // get vaccineReadRecord length
    function getVaccineRecord(uint256 _txIndex, address _userAddress)
        public
        view
        returns (
            string memory _userName,
            string memory _vaccineType,
            string memory _location,
            uint256 _timestamp
        )
    {
        _userName = users[_userAddress].userName;
        _vaccineType = users[_userAddress]
            .vaccineRecordDetail[_txIndex]
            .vaccineType;
        _location = users[_userAddress].vaccineRecordDetail[_txIndex].location;
        _timestamp = users[_userAddress]
            .vaccineRecordDetail[_txIndex]
            .timestamp;
        return (_userName, _vaccineType, _location, _timestamp);
    }
}
