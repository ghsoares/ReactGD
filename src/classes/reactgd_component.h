#ifndef REACTGD_COMPONENT_H
#define REACTGD_COMPONENT_H

#include <Godot.hpp>
#include <Node.hpp>

namespace godot {
class ReactGDComponent : public Node {
	GODOT_CLASS(ReactGDComponent, Node)
	
	private:
    	bool _dirty;
		godot_dictionary _render_state;

		void _render_process(float delta);
	public:
		// NativeScript methods
		static void _register_methods();

		// Class properties
		String* 			id;
		String* 			cached_path;
		Dictionary* 		state;
		Dictionary* 		props;
		ReactGDComponent* 	parent_component;
		
		/*
		func set_state(new_state: Dictionary) -> void:
			ReactGDDictionaryMethods.merge_dict(state, new_state)
			tree._add_component_to_update(self)

		func do_transition(final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
			return tree.do_transition(final_val, duration, trans_type, ease_type, delay)

		func do_shake(peak_val, final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
			return tree.do_shake(peak_val, final_val, duration, trans_type, ease_type, delay)

		func construct() -> void:
			self.state = {}

		func render() -> Dictionary:
			return {}
		*/

		// Constructor/Destructor
		ReactGDComponent();
		~ReactGDComponent();

		// Inherited methods
		void _enter_tree();
		void _process(float delta);

		// Class methods
		void set_state(Dictionary new_state);
		void construct();
		virtual Dictionary render();
};
}

#endif