#!/usr/bin/env python3
"""Exercise the built server over stdio, using a disposable key and no ASC API calls."""
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile


def send(process, message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def request(process, request_id, method, params):
    send(process, dict(jsonrpc="2.0", id=request_id, method=method, params=params))
    if not select.select([process.stdout], [], [], 10)[0]:
        raise AssertionError("Timed out waiting for " + method)
    response = json.loads(process.stdout.readline())
    assert response.get("id") == request_id, response
    assert "error" not in response, response
    return response["result"]


def main():
    binary = str(Path(sys.argv[1]).resolve())
    with tempfile.TemporaryDirectory() as directory:
        key = str(Path(directory) / "test.p8")
        subprocess.run([
            "openssl", "genpkey", "-algorithm", "EC", "-pkeyopt",
            "ec_paramgen_curve:P-256", "-out", key,
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        env = {k: v for k, v in os.environ.items() if not k.startswith("ASC_")}
        env.update(ASC_AUTH_MODE="individual", ASC_KEY_ID="test", ASC_PRIVATE_KEY_PATH=key)
        cases = [
            {},
            {"experimental": {}},
            {"experimental": {"legacy": "supported"}},
            {"experimental": {"codex": {}}},
            {"experimental": {"nested": {"enabled": True}, "legacy": "yes",
                              "flag": True, "list": [1], "empty": None}},
            {"experimental": {"codex": {}}, "roots": {"listChanged": True},
             "elicitation": {"form": {}, "url": {}}},
        ]
        for capabilities in cases:
            process = subprocess.Popen(
                [binary], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL, text=True, env=env,
            )
            try:
                result = request(process, 1, "initialize", {
                    "protocolVersion": "2025-06-18", "capabilities": capabilities,
                    "clientInfo": {"name": "codex-handshake-regression", "version": "1.0"},
                })
                assert "tools" in result["capabilities"], result
                send(process, {"jsonrpc": "2.0", "method": "notifications/initialized"})
                tools = request(process, 2, "tools/list", {})["tools"]
                assert any(tool["name"] == "list_apps" for tool in tools), tools
                metadata_tools = {
                    "get_app": "app_id", "list_app_infos": "app_id",
                    "list_app_info_localizations": "app_info_id",
                    "update_app_info_localization": "app_info_id",
                    "get_version": "version_id", "list_version_localizations": "version_id",
                }
                by_name = {tool["name"]: tool for tool in tools}
                for name, required_id in metadata_tools.items():
                    schema = by_name[name]["inputSchema"]
                    assert required_id in schema["required"], schema
                    assert "org" in schema["properties"], schema
                assert "locale" in by_name["update_app_info_localization"]["inputSchema"]["required"]
                result = request(process, 3, "tools/call", {"name": "list_orgs", "arguments": {}})
                assert not result.get("isError", False), result
                if not capabilities:
                    request_id = 4
                    for name, required_id in metadata_tools.items():
                        for arguments in ({}, {required_id: 123}, {required_id: ""}, {required_id: "bad/id"}):
                            result = request(process, request_id, "tools/call", {"name": name, "arguments": arguments})
                            assert result.get("isError", False), result
                            assert required_id in result["content"][0]["text"], result
                            request_id += 1
                        if "localizations" in name:
                            for locale in (123, "", "   "):
                                result = request(process, request_id, "tools/call", {
                                    "name": name, "arguments": {required_id: "test-id", "locale": locale},
                                })
                                assert result.get("isError", False), result
                                assert "locale must be a non-empty string" in result["content"][0]["text"], result
                                request_id += 1
                    for fields in ({}, {"name": 123}, {"subtitle": 123}, {"name": "   "}):
                        result = request(process, request_id, "tools/call", {
                            "name": "update_app_info_localization",
                            "arguments": {"app_info_id": "test-id", "locale": "en-US", **fields},
                        })
                        assert result.get("isError", False), result
                        request_id += 1
                print("PASS:", json.dumps(capabilities), "—", len(tools), "tools")
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == "__main__":
    main()
