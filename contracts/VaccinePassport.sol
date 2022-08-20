// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract VaccinePassport is Ownable {
    struct Users {
        string userName;
        string idNumber;
        string birthDate;
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

    function createUserProfile(
        string memory _userName,
        string memory _idNumber,
        string memory _birthDate
    ) public {
        require(!users[msg.sender].isActive, "User already exists.");
        users[msg.sender].userName = _userName;
        users[msg.sender].idNumber = _idNumber;
        users[msg.sender].birthDate = _birthDate;
        users[msg.sender].numVaccinations = 0;
        users[msg.sender].isActive = true;
    }

    function isExistingUser() public view returns (bool) {
        return users[msg.sender].isActive;
    }

    function getUserProfile()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            bool,
            uint256
        )
    {
        return (
            users[msg.sender].userName,
            users[msg.sender].idNumber,
            users[msg.sender].birthDate,
            users[msg.sender].isActive,
            users[msg.sender].numVaccinations
        );
    }

    function isValidVaccine(string memory _vaccineType)
        private
        pure
        returns (bool)
    {
        string[2] memory vaccineList = ["CoronaVac", "Comirnaty"];
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
        user.vaccineRecordDetail[numVaccinations].timestamp = block.timestamp;
        user.numVaccinations++;
    }

    function getUserVaccineRecord()
        public
        view
        returns (
            string[] memory,
            string[] memory,
            uint256[] memory
        )
    {
        Users storage user = users[msg.sender];
        string[] memory mVaccineType = new string[](user.numVaccinations);
        string[] memory mLocation = new string[](user.numVaccinations);
        uint256[] memory mTimestamp = new uint256[](user.numVaccinations);
        for (uint256 i; i < user.numVaccinations; i++) {
            mVaccineType[i] = user.vaccineRecordDetail[i].vaccineType;
            mLocation[i] = user.vaccineRecordDetail[i].location;
            mTimestamp[i] = user.vaccineRecordDetail[i].timestamp;
        }

        return (mVaccineType, mLocation, mTimestamp);
    }

    function joinTheEvent() public returns (bool) {
        Users storage user = users[msg.sender];
        if (user.isActive) {
            return false;
        }
        user.isActive = true;
        return true;
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

}
