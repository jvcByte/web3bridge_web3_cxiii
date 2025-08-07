// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {EventContract} from "../src/EventContract.sol";

contract Event is Test {

    EventContract public eventContract;

    function setUp () public {
        eventContract = new EventContract();
    }

    function testCreateEvent() public {
        
        uint256 countBefore = eventContract.eventCount();

        eventContract.createEvent(
            "Test Event",
            "description here",
            88765544333124,
            98766554232455,
            100,
            "https://example.com/banner.png",
            EventContract.EventType.Paid,
            1000,
            EventContract.EventStatus.Upcoming
        );

        uint256 countAfter = eventContract.eventCount();

        assert(countAfter > countBefore);

    }
}