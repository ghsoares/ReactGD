#ifndef REACTGDCOMPONENT_H
#define REACTGDCOMPONENT_H

#include "scene/main/node.h"
#include "core/variant.h"

class ReactGDComponent : public Node {
	GDCLASS(ReactGDComponent, Node);

	protected:
		static void _bind_methods();

	public:
		Dictionary create_node(String id, Ref<Script> type, Dictionary props, Array children);

		ReactGDComponent();

};

#endif