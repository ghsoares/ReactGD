#include "reactgd_component.h"

using namespace godot;

void ReactGDComponent::_register_methods()
{
	register_method("_enter_tree", &ReactGDComponent::_enter_tree);
	register_method("_process", &ReactGDComponent::_process);
	register_method("set_state", &ReactGDComponent::set_state);
	register_method("construct", &ReactGDComponent::construct);
	register_method("render", &ReactGDComponent::render);
}

ReactGDComponent::ReactGDComponent() {}
ReactGDComponent::~ReactGDComponent() {}

void ReactGDComponent::_enter_tree()
{
	this->construct();
}

void ReactGDComponent::_process(float delta) {
	this->_render_process(delta);
}

void ReactGDComponent::_render_process(float delta) {
	if (!this->_dirty) return;

	godot_dictionary new_render_state = this->render();
	godot_print(&godot_dictionary_to_json(&new_render_state));

	this->_dirty = false;
}

/*
void GDExample::_process(float delta) {
    time_passed += delta;

    Vector2 new_position = Vector2(10.0 + (10.0 * sin(time_passed * 2.0)), 10.0 + (10.0 * cos(time_passed * 1.5)));

    set_position(new_position);
}
*/
