@tool
class_name McpTypedContainerNodeFixture
extends Node

## Node fixture with exported typed containers for node_set_property regressions.

@export var ints: Array[int] = []
@export var strings: Array[String] = []
@export var vec3s: Array[Vector3] = []
@export var textures: Array[Texture2D] = []
@export var items: Array[MyTestResource] = []
@export var nested: Array[Array] = []
@export var loose: Array = []
