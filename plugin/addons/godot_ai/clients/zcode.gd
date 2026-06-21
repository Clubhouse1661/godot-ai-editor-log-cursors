@tool
extends McpClient

## ZCode's runtime config stores global MCP servers in
## ~/.zcode/cli/config.json under `mcp.servers.<name>`. The desktop app keeps
## separate UI/account state under ~/.zcode/v2; that is not the MCP runtime
## config file.


func _init() -> void:
	id = "zcode"
	display_name = "ZCode"
	config_type = "json"
	doc_url = "https://zcode.z.ai/en/docs/mcp-services"
	path_template = {
		"unix": "~/.zcode/cli/config.json",
		"windows": "$USERPROFILE/.zcode/cli/config.json",
	}
	server_key_path = PackedStringArray(["mcp", "servers"])
	entry_extra_fields = {"type": "http", "headers": []}
	detect_paths = PackedStringArray(["~/.zcode", "~/.zcode/v2", "~/.zcode/cli"])
