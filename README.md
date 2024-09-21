# Aura iOS Agent

## Description
Aura is an iOS payload designed to interact with a Mythic C2 (command and control) server and was developed over the [2024 Microsoft Global Hackathon](https://microsoft.sharepoint.com/sites/MicrosoftGlobalHackathon2024). To fit within the time constraint of one week:
* The agent communicates over plain text HTTP channels
* Mythic will manage and initate the agent builds per-usual, but the actual compilation and configuration of the agent will take place remotely on macOS w/iOS SDK outside of Docker.
* A limited number of commands will be implemented.

### Requirements
* iOS 12.5.7+

## Operator commands
| Description | Implemented Command |
| - | - |
| Take a screenshot | `take_screenshot` |
| Execute a shell command | `shell_execution [args]` |

## Execution example
```txt
2024-09-20 18:13:33.914 aura[2322:270194] 👋 Hello from the Aura iOS agent!
2024-09-20 18:13:33.916 aura[2322:270194] [DEBUG] Check-in URL: http://ec2-54-245-60-126.us-west-2.compute.amazonaws.com:80/agent_message
2024-09-20 18:13:34.027 aura[2322:270194] {
    action = checkin;
    architecture = arm64;
    domain = local;
    "external_ip" = "136.24.173.189";
    host = "brandontonsipad.localdomain";
    "integrity_level" = 2;
    ips =     (
        "192.168.0.18"
    );
    os = "iOS 12.5.7";
    pid = 2322;
    "process_name" = aura;
    user = mobile;
    uuid = "b355bc11-0c78-41ec-b3b7-7220561137fa";
}
```