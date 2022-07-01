// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaccinePassport is Ownable {
    struct Users {
        uint256 numVaccinations;
        mapping(uint256 => VaccineRecordDetail) vaccineRecordDetail;
    }

    struct VaccineRecordDetail {
        string username;
        string vaccineName;
        string location;
        uint256 timestamp;
    }

    struct VaccineRecordAccess {
        address accessAddress;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(address => Users) private users;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    VaccineRecordAccess[] public vaccineRecordAccessList;

    event VaccineRecordAdded(
        address indexed _userAddress,
        string _username,
        string _vaccineName,
        string _location,
        uint256 _timestamp
    );

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

    function isValidVaccine(string memory _vaccineName)
        private
        pure
        returns (bool)
    {
        string[2] memory vaccineList = ["AAA", "BBB"];
        for (uint256 i; i < vaccineList.length; i++) {
            if (
                keccak256(abi.encodePacked(_vaccineName)) ==
                keccak256(abi.encodePacked(vaccineList[i]))
            ) {
                return true;
            }
        }
        return false;
    }

    function addVaccineRecord(
        address _userAddress,
        string memory _username,
        string memory _vaccineName,
        string memory _location
    ) public onlyOwner {
        require(isValidVaccine(_vaccineName), "Invalid vaccine type.");
        Users storage user = users[_userAddress];
        uint256 numVaccinations = user.numVaccinations;
        user.vaccineRecordDetail[numVaccinations].username = _username;
        user.vaccineRecordDetail[numVaccinations].vaccineName = _vaccineName;
        user.vaccineRecordDetail[numVaccinations].location = _location;
        user.vaccineRecordDetail[numVaccinations].timestamp = block.timestamp;
        numVaccinations++;
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

    // read record
    function executeReadVaccineRecord(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        returns (
            string memory _username,
            string memory _vaccineName,
            string memory _location,
            uint256 _timestamp
        )
    {
        VaccineRecordAccess
            storage vaccineRecordAccess = vaccineRecordAccessList[_txIndex];
        require(vaccineRecordAccess.numConfirmations == 2, "cannot execute tx");
        vaccineRecordAccess.executed = true;
        _username = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .username;
        _vaccineName = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .vaccineName;
        _location = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .location;
        _timestamp = users[vaccineRecordAccess.accessAddress]
            .vaccineRecordDetail[_txIndex]
            .timestamp;
        emit VaccineRecordAdded(
            vaccineRecordAccess.accessAddress,
            _username,
            _vaccineName,
            _location,
            _timestamp
        );
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

    //get vaccineRecordAccessList length
    function getVaccineRecordAccessListLength() public view returns (uint256) {
        return vaccineRecordAccessList.length;
    }

    // greeting
    function greeting() public pure returns (string memory) {
        return "Hello, World!";
    }
}
