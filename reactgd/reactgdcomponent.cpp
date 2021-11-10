#include "reactgdcomponent.h"
#include "reactgd.h"

void ReactGDComponent::_bind_methods() {
	BIND_VMETHOD(MethodInfo(Variant::ARRAY, "_render"));

	ClassDB::bind_method(D_METHOD("set_state", "state"), &ReactGDComponent::set_state);
	ClassDB::bind_method(D_METHOD("get_state"), &ReactGDComponent::get_state);
	ClassDB::bind_method(D_METHOD("mark_dirty"), &ReactGDComponent::mark_dirty);
	ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "state"), "set_state", "get_state");
}

void ReactGDComponent::_notification(int p_notification) {
	switch (p_notification) {
		case NOTIFICATION_READY: {
			set_process(true);
		} break;
		case NOTIFICATION_PROCESS: {
			if (dirty) {
				Array r = _render();
				if (!r.empty()) {
					current_node = ReactGD::get_singleton()->render(this, r);
				}
				dirty = false;
			}
		} break;
	}
}

Array ReactGDComponent::_render() {
	if (get_script_instance() && get_script_instance()->has_method("_render")) {
		return get_script_instance()->call("_render");
	}

	Array arr;

	return arr;
}

void ReactGDComponent::mark_dirty() {
	dirty = true;
}

void ReactGDComponent::set_state(Dictionary new_state) {
	Array keys = new_state.keys();
	int num_keys = keys.size();
	for (int i = 0; i < num_keys; i++) {
		state[keys[i]] = new_state[keys[i]];
	}
	dirty = true;
}

Dictionary ReactGDComponent::get_state() {return state;}

ReactGDComponent::ReactGDComponent() {
	dirty = true;
	state = Dictionary();
	child_pos = 0;
}