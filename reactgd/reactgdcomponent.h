#ifndef REACTGDCOMPONENT_H
#define REACTGDCOMPONENT_H

#include "scene/main/node.h"
#include "core/variant.h"

class ReactGDComponent : public Node {
	GDCLASS(ReactGDComponent, Node);

	protected:
		static void _bind_methods();

	public:
		virtual Dictionary _render();

		ReactGDComponent();

};

#endif