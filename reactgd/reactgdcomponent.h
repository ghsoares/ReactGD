#ifndef REACTGDCOMPONENT_H
#define REACTGDCOMPONENT_H

#include "scene/gui/control.h"
#include "core/variant.h"
#include "scene/gui/check_box.h"

class ReactGDComponent : public Control {
	GDCLASS(ReactGDComponent, Control);

	private:
		bool dirty;
		int child_pos;
		Node* current_node;

	protected:
		static void _bind_methods();

		void _notification(int p_notification);
	public:
		virtual Array _render();

		Dictionary state;

		void mark_dirty();
		void set_state(Dictionary new_state);
		Dictionary get_state();

		ReactGDComponent();

};

#endif