// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToDo {
    struct Task {
        uint256 id;
        string description;
        bool completed;
    }

    mapping(uint256 => Task) private tasks;
    uint256 private nextId;

    event TaskCreated(uint256 id, string description);
    event TaskCompleted(uint256 id);
    event TaskUpdated(uint256 id, string description);

    function createTask(string memory description) public {
        tasks[nextId] = Task(nextId, description, false);
        emit TaskCreated(nextId, description);
        nextId++;
    }

    function completeTask(uint256 id) public {
        require(tasks[id].id == id, "Task does not exist");
        tasks[id].completed = true;
        emit TaskCompleted(id);
    }

    function updateTask(uint256 id, string memory description) public {
        require(tasks[id].id == id, "Task does not exist");
        tasks[id].description = description;
        emit TaskUpdated(id, description);
    }

    function getTask(uint256 id) public view returns (Task memory) {
        require(tasks[id].id == id, "Task does not exist");
        return tasks[id];
    }
}
// This contract allows users to create, complete, and update tasks.
// Each task has an ID, description, and completion status.