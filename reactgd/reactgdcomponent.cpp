#include "reactgdcomponent.h"

void ReactGDComponent::_bind_methods() {
	ClassDB::bind_method(D_METHOD("create_node", "id", "type", "props", "children"), &ReactGDComponent::create_node);
}

Dictionary ReactGDComponent::create_node(String id, Ref<Script> type, Dictionary props, Array children) {
	Dictionary dict;

	dict["id"] = id;
	dict["type"] = type;
	dict["props"] = props;
	dict["children"] = children;

	return dict;
}

ReactGDComponent::ReactGDComponent() {}