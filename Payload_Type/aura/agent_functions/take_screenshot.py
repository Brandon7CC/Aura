from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
import datetime
import json


class TakeScreenshotArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class TakeScreenshotCommand(CommandBase):
    cmd = "take_screenshot"
    needs_admin = False
    help_cmd = "take_screenshot"
    description = "Take a screenshot of the screen."
    version = 1
    author = "@brandon7CC"
    parameters = []
    attackmapping = ["T1113"]
    argument_class = TakeScreenshotArguments
    browser_script = BrowserScript(script_name="screencapture_new", author="@djhohnstein", for_new_ui=True)
    supported_os = [SupportedOS.IOS]

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.args.command_line += str(datetime.datetime.utcnow())
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
            artifact="$.CGDisplayCreateImage($.CGMainDisplayID());, $.NSBitmapImageRep.alloc.initWithCGImage(cgimage);",
            artifact_type="API Called",
        )
        return task

    async def process_response(self, response: AgentResponse):
        pass