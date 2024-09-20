from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class ShellExecArgs(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class ShellExecCommand(CommandBase):
    cmd = "shell_exec"
    needs_admin = False
    help_cmd = "shell_exec [args]"
    description = "Execute a shell command with '/bin/bash -c'"
    version = 1
    author = "@brandon7CC"
    argument_class = ShellExecArgs
    attackmapping = ["T1059"]

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
                                         artifact="/bin/bash -c {}".format(task.args.command_line),
                                         artifact_type="Process Create",
                                         )
        return task

    async def process_response(self, response: AgentResponse):
        pass
