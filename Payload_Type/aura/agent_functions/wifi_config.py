from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class WiFiConfigArgs(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class WiFiConfigCommand(CommandBase):
    cmd = "wifi_config"
    needs_admin = False
    help_cmd = "wifi_config"
    description = "Read from: /private/var/preferences/SystemConfiguration/com.apple.wifi.plist"
    version = 1
    author = "@brandon7CC"
    argument_class = WiFiConfigArgs
    attackmapping = ["T1059"]

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
                                         artifact="NSDictionary *wifiConfig = [NSDictionary dictionaryWithContentsOfFile:plistPath];",
                                         artifact_type="API Called",
                                         )
        return task

    async def process_response(self, response: AgentResponse):
        pass
