#include "reactgd.h"
#include "modules/gdscript/gdscript.h"
#include "scene/main/node.h"
#include "core/func_ref.h"

Dictionary ReactGD::create_node(String id, Ref<Reference> type, Dictionary props, Array children) {
	Dictionary dict;
	
	Ref<Script> sc = type;
	Ref<GDScriptNativeClass> scn = type;

	ERR_FAIL_COND_V_MSG(!sc.is_valid() && !scn.is_valid(), dict, "\"type\" must be a Script or GDScriptNativeClass");

	if (props.has("id")) {
		id = String(props["id"]);
	}
	if (props.has("key")) {
		id += String(props["key"]);
	}

	dict["id"] = id;
	
	dict["type"] = type;
	dict["props"] = props;
	dict["children"] = children;

	return dict;
}

bool ReactGD::update_node_props(Node *node, Dictionary props) {
	bool changed = false;

	Array prop_keys = props.keys();
	for (int i = 0; i < prop_keys.size(); i++) {
		String key = prop_keys[i];
		Variant value = props[key];

		if (!key.begins_with("on_")) {
			auto prop_index = NodePath(key).get_as_property_path().get_subnames();
			bool valid = false;
			Variant curr_val = node->get_indexed(prop_index, &valid);
			ERR_FAIL_COND_V_MSG(!valid, false, "Node of type \'" + node->get_class() + "\' don't have property \'" + key + "\'");
			
			if (curr_val != value) {
				node->set_indexed(NodePath(key).get_as_property_path().get_subnames(), value);
				changed = true;
			}
		} else {
			Array func_ref = value;
			Object *target = func_ref[0];
			String method_name = func_ref[1];
			String signal_name = key.substr(3);

			if (node->is_connected(signal_name, target, method_name)) {
				node->disconnect(signal_name, target, method_name);
			}
			node->connect(signal_name, target, method_name);
		}
	}

	return changed;
}

Node *ReactGD::instantiate(Dictionary node) {
	Ref<Script> sc = node["type"];
	Ref<GDScriptNativeClass> scn = node["type"];

	StringName base = sc.is_valid() ? sc->get_instance_base_type() : scn->get_name();
	Object* obj = ClassDB::instance(base);
	Node *n = Object::cast_to<Node>(obj);
	if (sc.is_valid()) {
		n->set_script(sc.get_ref_ptr());
	}
	n->set_name(node["id"]);

	return n;
}


void ReactGD::_render(Node *root, Dictionary tree, int &child_id) {
	Node *curr_node = nullptr;

	String id = tree["id"];
	Ref<Script> sc = tree["type"];
	Ref<GDScriptNativeClass> scn = tree["type"];
	Dictionary props = tree["props"];
	Array children = tree["children"];

	bool changed = false;

	if (root->has_node(id)) {
		curr_node = root->get_node(id);
	}

	if (curr_node) {
		changed = update_node_props(curr_node, props);
		root->move_child(curr_node, child_id);
	} else {
		Node *new_node = instantiate(tree);
		root->add_child(new_node);
		root->move_child(new_node, child_id);
		changed = update_node_props(new_node, props);
		if (sc.is_valid()) {
			new_node->set_script(sc.get_ref_ptr());
		}
		curr_node = new_node;
	}

	bool component_rendered = false;
	if (sc.is_valid() && ClassDB::is_parent_class(sc->get_instance_base_type(), "ReactGDComponent")) {
		if (changed && sc->has_method("_render")) {
			Dictionary new_render = sc->call("_render");
			child_id++;
			int new_child_id = child_id;
			_render(root, new_render, new_child_id);
		}
	}

	child_id++;

	int num_children = children.size();

	int child_idx = 0;

	for (int i = 0; i < num_children; i++) {
		Dictionary child = children[i];

		_render(curr_node, child, child_idx);
	}
}

void ReactGD::render(Node *root, Dictionary tree) {
	int child_idx = 0;
	_render(root, tree, child_idx);
}

ReactGD *ReactGD::singleton = nullptr;

ReactGD::ReactGD() {
	ReactGD::singleton = this;
}

ReactGD::~ReactGD() {
	ReactGD::singleton = nullptr;
}

void ReactGD::_bind_methods() {
	ClassDB::bind_method(D_METHOD("create_node", "type", "props", "children"), &ReactGD::create_node);
	ClassDB::bind_method(D_METHOD("update_node_props", "node", "props"), &ReactGD::update_node_props);
	ClassDB::bind_method(D_METHOD("instantiate", "node"), &ReactGD::instantiate);
	ClassDB::bind_method(D_METHOD("render", "root", "tree"), &ReactGD::render);
}