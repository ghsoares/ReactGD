#include "reactgdcomponent.h"

void ReactGDComponent::_bind_methods() {
	BIND_VMETHOD(MethodInfo(Variant::DICTIONARY, "_render"));
}

Dictionary ReactGDComponent::_render() {
	if (get_script_instance() && get_script_instance()->has_method("_render")) {
		return get_script_instance()->call("_render");
	}

	Dictionary dict;

	return dict;
}

ReactGDComponent::ReactGDComponent() {}