#ifndef REACTGD_H
#define REACTGD_H

#include "core/reference.h"
#include "core/variant.h"

class ReactGD : public Object {
	GDCLASS(ReactGD, Object)

	static ReactGD *singleton;

protected:

	static void _bind_methods();
public:
	static ReactGD *get_singleton() {return ReactGD::singleton;}

	Dictionary create_node(Ref<Reference> type, Dictionary props, Array children);
	void update_node_props(Node *node, Dictionary props);
	Node *instantiate(Dictionary tree);

	ReactGD();
	~ReactGD();
};

#endif