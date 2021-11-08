#include "reactgd.h"
#include "modules/gdscript/gdscript.h"
#include "scene/main/node.h"
#include "core/func_ref.h"

Dictionary ReactGD::create_node(Ref<Reference> type, Dictionary props, Array children) {
	Dictionary dict;
	
	Ref<Script> sc = type;
	Ref<GDScriptNativeClass> scn = type;

	ERR_FAIL_COND_V_MSG(!sc.is_valid() && !scn.is_valid(), dict, "\"type\" must be a Script or GDScriptNativeClass");

	dict["type"] = type;
	dict["props"] = props;
	dict["children"] = children;

	return dict;
}

void ReactGD::update_node_props(Node *node, Dictionary props) {
	Array prop_keys = props.keys();
	for (int i = 0; i < prop_keys.size(); i++) {
		String key = prop_keys[i];
		Variant value = props[key];

		if (!key.begins_with("on_")) {
			node->set(key, value);
		} else {
			Array func_ref = value;
			Ref<Reference> target = func_ref[0];
			String method_name = func_ref[1];
			String signal_name = key.substr(3);

			if (node->is_connected(signal_name, target.ptr(), method_name)) {
				node->disconnect(signal_name, target.ptr(), method_name);
			}
			node->connect(signal_name, target.ptr(), method_name);
		}
	}
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

	return n;
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
}