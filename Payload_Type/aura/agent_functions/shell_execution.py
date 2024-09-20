from mythic_container.MythicCommandBase import *
import json
from mythic_container.MythicRPC import *


class ShellExecutionArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class ShellExecutionCommand(CommandBase):
    cmd = "shell_execution"
    needs_admin = False
    help_cmd = "shell_execution [params]"
    description = "Execute a zshell command with '/bin/zsh -c'"
    version = 1
    author = "@brandon7CC"
    argument_class = ShellExecutionArguments
    attackmapping = ["T1059"]

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
                                         artifact="/bin/zsh -c {}".format(task.args.command_line),
                                         artifact_type="Process Create",
                                         )
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
                                         artifact="{}".format(task.args.command_line),
                                         artifact_type="Process Create",
                                         )
        return task

    async def process_response(self, response: AgentResponse):
        pass
